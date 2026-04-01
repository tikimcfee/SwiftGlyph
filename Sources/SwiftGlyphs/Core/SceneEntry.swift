//
//  SceneEntry.swift
//  SwiftGlyph
//
//  Created by Ivan Lugo on 2026-03-31.
//

import Foundation
import Observation

/// Protocol for any content type that can be registered in the scene.
/// `CodeGrid` and future types (`TUIWindow`, etc.) conform to this.
public protocol SceneEntryContent: AnyObject {
    var name: String { get }
}

/// A single entry in the scene registry.
///
/// Each entry has a unique `id`, a GPU-side `groupId` for indexing into
/// the group transform buffer, and the associated content object.
/// `isVisible` tracks logical visibility separate from GPU state.
@Observable
public final class SceneEntry: Identifiable {
    public let id: String
    public let groupId: UInt16
    public let content: any SceneEntryContent
    public var isVisible: Bool = true

    public init(
        id: String,
        groupId: UInt16,
        content: any SceneEntryContent
    ) {
        self.id = id
        self.groupId = groupId
        self.content = content
    }
}
