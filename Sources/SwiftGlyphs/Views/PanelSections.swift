//
//  PanelSections.swift
//
//
//  Created by Ivan Lugo on 11/3/24.
//


import Combine
import SwiftUI
import BitHandling

public enum PanelSections: String, CaseIterable, Equatable, Comparable, Codable {
    case windowControls = "Window Controls"
    case menuActions = "App Tools"
    
    case directories = "Files"
    case editor = "Editor"
    case githubTools = "GitHub"
    
    case semanticCategories = "Semantics"
    case hoverInfo = "Hover Info"
    case tracingInfo = "Tracing Info"
    case globalSearch = "Global Search"
    case appStatusInfo = "App Status"
    case gridStateInfo = "Grid State"
    case focusState = "Focus"
    case bookmarks = "Bookmarks"
    
    
    public static var usableWindows: [PanelSections] {
        [
            .windowControls,
            .menuActions,
            
            .directories,
            .editor,
            .githubTools,
            
            .semanticCategories,
//            .hoverInfo,
            .tracingInfo,
            .globalSearch,
            .appStatusInfo,
//            .gridStateInfo,
            .focusState,
            .bookmarks,
        ]
    }
    
    public static func < (lhs: PanelSections, rhs: PanelSections) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
    
    var defaultMode: FloatableViewMode {
        switch self {
        case .windowControls: .displayedAsSibling
        default: .hidden
        }
    }
}
