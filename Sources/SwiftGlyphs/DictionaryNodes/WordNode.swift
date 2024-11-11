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
//            glyph.instanceConstants?.setFlag(.useParent, false)
            glyph.instanceConstants?.setFlag(.ignoreHover, true)
//            glyph.parent = self
            glyph.position = LFloat3(x: xOffset, y: yOffset, z: 0)
            if verticalLayout {
                yOffset -= glyph.boundsHeight
            } else {
                xOffset += glyph.boundsWidth
            }
        }
    }
    
    public static func layoutWord(
        glyphs: [GlyphNode],
        verticalLayout: Bool = false,
        scale: LFloat3,
        offset initialOffset: LFloat3,
        each: (GlyphNode) -> Void
    ) {
        var xOffset: Float = initialOffset.x
        var yOffset: Float = initialOffset.y
        let zOffset: Float = initialOffset.z
        for glyph in glyphs {
            glyph.instanceConstants?.scale = LFloat4(scale, 0);
            glyph.instanceConstants?.positionOffset = LFloat4(x: xOffset, y: yOffset, z: zOffset, w: 0)
//            glyph.position = LFloat3(x: xOffset, y: yOffset, z: zOffset)
            if verticalLayout {
                yOffset -= glyph.boundsHeight * scale.y
            } else {
                xOffset += glyph.boundsWidth * scale.x
            }
            each(glyph)
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
