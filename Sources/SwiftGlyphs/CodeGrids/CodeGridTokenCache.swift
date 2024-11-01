//
//  CodeGridTokenCache.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 12/12/21.
//

import Foundation
import BitHandling
import MetalLink

// associate tokens to sets of nodes.
// { let nodesToUpdate = tracker[someToken] }
// - given a token, return the nodes that represent it
// - use that set to highlight, move, do stuff to

//typealias [GlyphNode] = Set<GlyphNode>
public class CodeGridTokenCache: LockingCache<String, [GlyphNode]> {
    public override func make(_ key: Key) -> Value {
        laztrace(#fileID,#function,key)
        
        let set = [GlyphNode]()
        return set
    }
}
