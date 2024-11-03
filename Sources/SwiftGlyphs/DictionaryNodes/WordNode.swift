//
//  WordNode.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 2/17/23.
//

import Foundation
import MetalLink
import MetalLinkHeaders

public class WordNode: MetalLinkNode {
    public let sourceWord: String
    public var glyphs: [GlyphNode]
    public weak var parentGrid: CodeGrid?

    public override var hasIntrinsicSize: Bool {
        true
    }
    
    public override var contentBounds: Bounds {
        var totalBounds = Bounds.forBaseComputing
        for node in glyphs {
            totalBounds.union(with: node.sizeBounds)
        }
        return totalBounds * scale
    }
    
    public init(
        sourceWord: String,
        glyphs: [GlyphNode],
        parentGrid: CodeGrid,
        verticalLayout: Bool = false
    ) {
        self.sourceWord = sourceWord
        self.glyphs = glyphs
        self.parentGrid = parentGrid
        super.init()
        
        var xOffset: Float = 0
        var yOffset: Float = 0
        for glyph in glyphs {
            // The word node will act as a virtual parent and the instanced node shouldn't use the parent multipier.
            glyph.instanceConstants?.setFlag(.useParent, false)
            glyph.instanceConstants?.setFlag(.ignoreHover, true)
            glyph.parent = self
            glyph.position = LFloat3(x: xOffset, y: yOffset, z: 0)
            if verticalLayout {
                yOffset -= glyph.boundsHeight
            } else {
                xOffset += glyph.boundsWidth
            }
        }
    }
    
    public override var children: [MetalLinkNode] {
        get { glyphs }
        set { glyphs = newValue as? [MetalLinkGlyphNode] ?? glyphs }
    }
    
    public override func render(in sdp: SafeDrawPass) {
        // Don't render me
    }
}
