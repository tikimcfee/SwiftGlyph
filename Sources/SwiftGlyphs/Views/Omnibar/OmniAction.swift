//
//  OmniAction.swift
//  SwiftGlyph
//
//  Created by Ivan Lugo on 11/13/24.
//

#if os(macOS)
import BitHandling
import Combine
import Foundation
import MetalLink
import AppKit

public struct OmniAction: Identifiable, Hashable, Equatable {
    public let id = UUID()
    
    let trigger: OmniActionTrigger
    let sourceQuery: String
    
    let actionDisplay: String
    let perform: () -> Void
    
    public static func == (lhs: OmniAction, rhs: OmniAction) -> Bool {
        lhs.id == rhs.id
        && lhs.trigger == rhs.trigger
        && lhs.sourceQuery == rhs.sourceQuery
        && lhs.actionDisplay == rhs.actionDisplay
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(trigger)
        hasher.combine(sourceQuery)
        hasher.combine(actionDisplay)
    }
}

public enum OmnibarInvoke {
    case open
    case actions
}

public enum OmnibarState {
    case visible(OmnibarInvoke)
    case inactive
}

enum OmniActionTrigger: String {
    case gridJump = "j"
    case gridClose = "x"
    case gridOpen = "o"
    case search = "search"
}
#endif
