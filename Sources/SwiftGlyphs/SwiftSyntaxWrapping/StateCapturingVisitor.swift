//
//  StateCapturingVisitor.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 6/13/21.
//

import Foundation
import SwiftSyntax

/////// WARNING 2!
/// Pretty much just don't use this. I have no idea what I could be doing incorrectly but just calling
/// child nodes works. Using the walker doesn't. I'm assuming the 'walk' path makes assumptions about
/// the state of nodes, and since I retain nodes all over the place, I'm likely breaking those assumptions.
public class ChildIterator: IteratorProtocol {
    public typealias Element = Syntax
    
    private class OneShotVisitor: SyntaxAnyVisitor {
        var enumeratedChildren = [Syntax]()
        
        init(_ syntax: Syntax) {
            super.init(viewMode: .sourceAccurate)
            super.walk(syntax)
        }
        
        override func visitAnyPost(_ node: Syntax) {
            enumeratedChildren.append(node)
        }
    }
    
    public let count: Int
    private let root: Syntax
    private var iterator: Array<Syntax>.Iterator

    public init(
        _ syntax: Syntax
    ) {
        self.root = syntax
        
        let visitor = OneShotVisitor(root)
        self.count = visitor.enumeratedChildren.count
        self.iterator = visitor.enumeratedChildren.makeIterator()
    }
    
    public func next() -> SwiftSyntax.Syntax? {
        iterator.next()
    }
}

// For whatever reason, it's safer to iterate through children than walking and doing things that way.
// Luckily the recursion is super simple, and barring super crazy nesting, the stack should be fine.
public class IterativeRecursiveVisitor {
    public static func walkRecursiveFromSyntax(
        _ root: Syntax,
        _ receiver: (Syntax) throws -> Void
    ) {
        do {
            try receiver(root)
            try consumeRecursiveStart(root.children(viewMode: .sourceAccurate), receiver)
        } catch {
            print("Error while recursing: ", error)
        }
    }
    
    private static func consumeRecursiveStart(
        _ allChildNodes: SyntaxChildren,
        _ receiver: (Syntax) throws -> Void
    ) throws {
        for childNode in allChildNodes {
            try receiver(childNode)
            try consumeRecursiveStart(childNode.children(viewMode: .sourceAccurate), receiver)
        }
    }
}

public class FlatteningVisitor {
    public let target: SemanticInfoMap
    public let builder: SemanticInfoBuilder
    
    public init(target: SemanticInfoMap, builder: SemanticInfoBuilder) {
        self.target = target
        self.builder = builder
    }
    
    public func walkRecursiveFromSyntax(_ root: Syntax) {
        tryMap(root)
        consumeRecursiveStart(root.children(viewMode: .sourceAccurate))
    }
    
    private func consumeRecursiveStart(_ allChildNodes: SyntaxChildren) {
        for childNode in allChildNodes {
            consumeRecursiveStart(childNode.children(viewMode: .sourceAccurate))
            tryMap(childNode)
        }
    }
    
    private func tryMap(_ syntax: Syntax) {
        let syntaxId = syntax.id
        let type = syntax.as(SyntaxEnum.self)
        
        target.flattenedSyntax[syntaxId] = syntax
        builder[syntax] = type
        
        let info = builder.semanticInfo(for: syntax, type: type)
        target.insertSemanticInfo(syntaxId, info)
        
        // associate it with itself for now; the view just does
        // an Array(dictionary.keys), doesn't even matter
        target.category(for: type) { store in
            store[syntaxId, default: [:]][syntaxId] = 1
        }
    }
}
