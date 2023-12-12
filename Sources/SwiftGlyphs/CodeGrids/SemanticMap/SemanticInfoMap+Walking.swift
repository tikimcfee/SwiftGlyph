//
//  SemanticInfoMap+Iteration.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 8/28/22.
//

import Foundation
import MetalLink

// MARK: - Associated Nodes for ID

public extension SemanticInfoMap {
    func doOnAssociatedNodes(
        _ nodeId: SyntaxIdentifier,
        _ cache: CodeGridTokenCache,
        _ receiver: ((SemanticInfo, CodeGridNodes)) throws -> Void
    ) rethrows {
        try walkFlattenedNonEscaping(from: nodeId, in: cache) { infoForNodeSet, nodeSet in
            try receiver((infoForNodeSet, nodeSet))
        }
    }
    
    func collectAssociatedNodes(
        _ nodeId: SyntaxIdentifier,
        _ cache: CodeGridTokenCache,
        _ sort: Bool = false
    ) throws -> [(SemanticInfo, SortedNodeSet)] {
        var allFound = [(SemanticInfo, SortedNodeSet)]()
        
        walkFlattened(from: nodeId, in: cache) { infoForNodeSet, nodeSet in
            let sortedTopMost = sort ? nodeSet.sorted(by: self.sortTopLeft) : Array(nodeSet)
            allFound.append((infoForNodeSet, sortedTopMost))
        }
        
        return sort ? allFound.sorted(by: sortTuplesTopLeft) : allFound
    }
    
    func tokenNodes(
        from syntaxIdentifer: SyntaxIdentifier,
        in cache: CodeGridTokenCache,
        _ walker: @escaping (SemanticInfo, CodeGridNodes) throws -> Void
    ) rethrows {
        // Just get all nodes directly underneath this one
//        guard let originalSynax = flattenedSyntax[syntaxIdentifer] else {
//            print("Cache missing on id: \(syntaxIdentifer)")
//            return
//        }
        
        print("[~~ walk flattened] noped")
    }
    
    func walkFlattened(
        from syntaxIdentifer: SyntaxIdentifier,
        in cache: CodeGridTokenCache,
        _ walker: @escaping (SemanticInfo, CodeGridNodes) throws -> Void
    ) rethrows {
//        guard let toWalk = flattenedSyntax[syntaxIdentifer] else {
//            print("Cache missing on id: \(syntaxIdentifer)")
//            return
//        }
        
        print("[~~ walk flattened] noped")
    }
    
    func walkFlattenedNonEscaping(
        from syntaxIdentifer: SyntaxIdentifier,
        in cache: CodeGridTokenCache,
        _ walker: (SemanticInfo, CodeGridNodes) throws -> Void
    ) rethrows {
//        guard let toWalk = flattenedSyntax[syntaxIdentifer] else {
//            print("Cache missing on id: \(syntaxIdentifer)")
//            return
//        }
        
        print("[~~ walk flattened] noped")
    }
}

// MARK: Parent Hierarchy from ID

public extension SemanticInfoMap {
    func parentList(
        _ nodeId: NodeSyntaxID,
        _ reversed: Bool = false
    ) -> [SemanticInfo] {
        var parentList = [SemanticInfo]()
        walkToRootFrom(nodeId) { info in
            parentList.append(info)
        }
        return reversed ? parentList.reversed() : parentList
    }
    
    func walkToRootFrom(
        _ nodeId: NodeSyntaxID?,
        _ walker: (SemanticInfo) -> Void
    ) {

        
    }
}
