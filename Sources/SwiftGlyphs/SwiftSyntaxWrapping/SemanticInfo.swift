//
//  SemanticInfo.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 4/24/22.
//

import Foundation
import SwiftSyntax
import MetalLink

public struct SemanticInfo: Hashable, CustomStringConvertible {
    public let node: Syntax
    public let syntaxId: SyntaxIdentifier
    
    // Refer to this semantic info by this name; it's displayable
    public var fullTextSearch: String = ""
    public var fileName: String = ""
    public let referenceName: String
    public let callStackName: String
    public let syntaxTypeName: String
    public let color: NSUIColor
    
    public var description: String {
        "\(syntaxTypeName)~>[\(referenceName)]"
    }
    
    public var isFullTextSearchable: Bool = false
    
    public init(node: Syntax,
         referenceName: String? = nil,
         typeName: String? = nil,
         color: NSUIColor? = nil,
         fullTextSearchable: Bool = false,
         fileName: String? = nil,
         callStackName: String? = nil
    ) {
        self.node = node
        self.syntaxId = node.id
        self.referenceName = referenceName ?? ""
        self.syntaxTypeName = typeName ?? String(describing: node.syntaxNodeType)
        self.color = color ?? CodeGridColors.defaultText
        self.isFullTextSearchable = fullTextSearchable
        self.callStackName = callStackName ?? ""
        if isFullTextSearchable {
            self.fullTextSearch = node.strippedText
        }
        self.fileName = fileName ?? ""
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(syntaxId.hashValue)
        hasher.combine(referenceName.hashValue)
    }
}

public extension SemanticInfo {
    func iterateReferenceKeys(_ receiver: (String) -> Void) {
        receiver(referenceName)
        receiver(referenceName.lowercased())
        receiver(referenceName.uppercased())
        
        referenceName.iterateTrieKeys(receiver: receiver)
    }
}
