//
//  GridInfo.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 10/26/21.
//

import Foundation
import MetalLink

public typealias AssociatedSyntaxSet = Set<SyntaxIdentifier>
public typealias AssociatedSyntaxMap = [SyntaxIdentifier: [SyntaxIdentifier: Int]]

public class SemanticInfoMap {
    
    // MARK: - Core association sets
    
    // TODO: *1 = these can be merged! SemanticInfo wraps Syntax
    // var totalProtonicReversal = [NodeId: (Syntax, SemanticInfo)]
    // Or just one can be removed.. I think I walked myself into duplicating the map
    // since SemanticInfo captures the node Syntax... TreeSitter will make me laughcry.
    public var flattenedSyntax = [SyntaxIdentifier: Syntax]()  //TODO: *1
    public var semanticsLookupBySyntaxId = [SyntaxIdentifier: SemanticInfo]()  //TODO: *1
    public var syntaxIDLookupByNodeId = [NodeSyntaxID: SyntaxIdentifier]()

    public var structs = AssociatedSyntaxMap()
    public var classes = AssociatedSyntaxMap()
    public var enumerations = AssociatedSyntaxMap()
    public var functions = AssociatedSyntaxMap()
    public var variables = AssociatedSyntaxMap()
    public var typeAliases = AssociatedSyntaxMap()
    public var protocols = AssociatedSyntaxMap()
    public var initializers = AssociatedSyntaxMap()
    public var deinitializers = AssociatedSyntaxMap()
    public var extensions = AssociatedSyntaxMap()
    public var switches = AssociatedSyntaxMap()
    
    public var allSemanticInfo: [SemanticInfo] {
        return Array(semanticsLookupBySyntaxId.values)
    }
    
    public init() {
        
    }
}

public extension SemanticInfoMap {
    enum Category: String, CaseIterable, Identifiable {
        public var id: String { rawValue }
        case structs = "Structs"
        case classes = "Classes"
        case enumerations = "Enumerations"
        case functions = "Functions"
        case variables = "Variables"
        case typeAliases = "Type Aliases"
        case protocols = "Protocols"
        case initializers = "Initializers"
        case deinitializers = "Deinitializers"
        case extensions = "Extensions"
        case switches = "Switches"
    }
    
    func category(
        _ category: SemanticInfoMap.Category,
        _ receiver: (inout AssociatedSyntaxMap) -> Void
    ) {
        switch category {
        case .structs: receiver(&structs)
        case .classes: receiver(&classes)
        case .enumerations: receiver(&enumerations)
        case .functions: receiver(&functions)
        case .variables: receiver(&variables)
        case .typeAliases: receiver(&typeAliases)
        case .protocols: receiver(&protocols)
        case .initializers: receiver(&initializers)
        case .deinitializers: receiver(&deinitializers)
        case .extensions: receiver(&extensions)
        case .switches: receiver(&switches)
        }
    }
    
    func map(for category: SemanticInfoMap.Category) -> AssociatedSyntaxMap {
        switch category {
        case .structs: return structs
        case .classes: return classes
        case .enumerations: return enumerations
        case .functions: return functions
        case .variables: return variables
        case .typeAliases: return typeAliases
        case .protocols: return protocols
        case .initializers: return initializers
        case .deinitializers: return deinitializers
        case .extensions: return extensions
        case .switches: return switches
        }
    }
}

// MARK: - Simplified mapping

public extension SemanticInfoMap {
    func addFlattened(_ syntax: Syntax) {
        flattenedSyntax[syntax.id] = syntax
    }
    
    func insertSemanticInfo(_ id: SyntaxIdentifier, _ info: SemanticInfo) {
        semanticsLookupBySyntaxId[id] = info
    }
    
    func insertNodeInfo(_ nodeId: NodeSyntaxID, _ syntaxId: SyntaxIdentifier) {
        syntaxIDLookupByNodeId[nodeId] = syntaxId
    }
}

// MARK: - Major Categories

public extension SemanticInfoMap {
    var isEmpty: Bool {
        semanticsLookupBySyntaxId.isEmpty
        && syntaxIDLookupByNodeId.isEmpty
        && structs.isEmpty
        && classes.isEmpty
        && enumerations.isEmpty
        && functions.isEmpty
        && variables.isEmpty
        && typeAliases.isEmpty
        && protocols.isEmpty
        && initializers.isEmpty
        && deinitializers.isEmpty
        && extensions.isEmpty
        && switches.isEmpty
    }
}

