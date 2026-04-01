//
//  MetalContext.swift
//  SwiftGlyph
//
//  Created by Ivan Lugo on 2026-03-31.
//

import Foundation
import Metal
import MetalLink

/// Container holding references to the core Metal primitives.
/// Created once at app launch in the composition root, then injected
/// into the view hierarchy and command system.
///
/// This replaces the Metal-related statics on `GlobalInstances`.
/// It is a reference type (class) because `MetalLink`, `MetalLinkAtlas`,
/// and `MetalLinkRenderer` are all classes with identity.
@MainActor
public final class MetalContext {
    public let link: MetalLink
    public let renderer: MetalLinkRenderer
    public let atlas: MetalLinkAtlas

    /// Convenience accessors forwarding to MetalLink.
    public var device: MTLDevice { link.device }
    public var commandQueue: MTLCommandQueue { link.defaultCommandQueue }

    /// `nonisolated` because this init only stores references.
    /// Allows creation from non-isolated contexts (e.g., static let in GlobalInstances).
    nonisolated public init(
        link: MetalLink,
        renderer: MetalLinkRenderer,
        atlas: MetalLinkAtlas
    ) {
        self.link = link
        self.renderer = renderer
        self.atlas = atlas
    }
}
