//
//  PanelSections.swift
//
//
//  Created by Ivan Lugo on 11/3/24.
//


import Combine
import SwiftUI
import BitHandling

public enum PanelSections: RawRepresentable, Codable, Identifiable {
    case windowControls
    case menuActions
    case directories
    case editor
    case githubTools
    case semanticCategories
    case hoverInfo
    case tracingInfo
    case globalSearch
    case appStatusInfo
    case gridStateInfo
    case focusState
    case bookmarks
    case unregistered(String)
    
    public var title: String { rawValue }
    
    public var id: String { rawValue }
    
    var defaultMode: FloatableViewMode {
        switch self {
        case .windowControls:
            .displayedAsSibling
        default:
            .hidden
        }
    }
    
    public init?(rawValue: String) {
        switch rawValue {
        case "Window Controls":
            self = .windowControls
        case "App Tools":
            self = .menuActions
        case "Files":
            self = .directories
        case "Editor":
            self = .editor
        case "GitHub":
            self = .githubTools
        case "Semantics":
            self = .semanticCategories
        case "Hover Info":
            self = .hoverInfo
        case "Tracing Info":
            self = .tracingInfo
        case "Global Search":
            self = .globalSearch
        case "App Status":
            self = .appStatusInfo
        case "Grid State":
            self = .gridStateInfo
        case "Focus":
            self = .focusState
        case "Bookmarks":
            self = .bookmarks
        default:
            self = .unregistered(rawValue)
        }
    }
    
    public var rawValue: String {
        switch self {
        case .windowControls:
            return "Window Controls"
        case .menuActions:
            return "App Tools"
        case .directories:
            return "Files"
        case .editor:
            return "Editor"
        case .githubTools:
            return "GitHub"
        case .semanticCategories:
            return "Semantics"
        case .hoverInfo:
            return "Hover Info"
        case .tracingInfo:
            return "Tracing Info"
        case .globalSearch:
            return "Global Search"
        case .appStatusInfo:
            return "App Status"
        case .gridStateInfo:
            return "Grid State"
        case .focusState:
            return "Focus"
        case .bookmarks:
            return "Bookmarks"
        case .unregistered(let string):
            return string
        }
    }
}

extension PanelSections: CaseIterable, Equatable, Hashable, Comparable {
    public static var allCases: [PanelSections] { [
        .windowControls,
        .menuActions,
        .directories,
        .editor,
        .githubTools,
        .semanticCategories,
        .hoverInfo,
        .tracingInfo,
        .globalSearch,
        .appStatusInfo,
        .gridStateInfo,
        .focusState,
        .bookmarks
    ] }
    
    public static var usableWindows: [PanelSections] { [
        .windowControls,
        .menuActions,
        .directories,
        .editor,
        .githubTools,
        .semanticCategories,
        .tracingInfo,
        .globalSearch,
        .appStatusInfo,
        .focusState,
        .bookmarks,
    ] }
    
    public static func < (lhs: PanelSections, rhs: PanelSections) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
