//
//  AppControlPanelState.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 4/23/22.
//

import Combine
import SwiftUI
import BitHandling

public enum PanelSections: String, CaseIterable, Equatable, Comparable, Codable {
    case editor = "Editor"
    case directories = "Files"
    case semanticCategories = "Semantics"
    case hoverInfo = "Hover Info"
    case tracingInfo = "Tracing Info"
    case globalSearch = "Global Search"
    case windowControls = "Window Controls"
    case appStatusInfo = "App Status"
    case gridStateInfo = "Grid State"
    case githubTools = "GitHub"
    case focusState = "Focus"
    case bookmarks = "Bookmarks"
    case menuActions = "App Tools"
    
    public static func < (lhs: PanelSections, rhs: PanelSections) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
    
    static var sorted: [PanelSections] {
        allCases.sorted(by: { $0.rawValue < $1.rawValue} )
    }
    
    var defaultMode: FloatableViewMode {
        switch self {
        case .windowControls: .displayedAsSibling
        default: .hidden
        }
    }
}

public class AppControlPanelState: ObservableObject {
    // Visible subsections
    @Published public var visiblePanelStates = AppStatePreferences.shared.panelStates {
        didSet {
            AppStatePreferences.shared.panelStates = visiblePanelStates
        }
    }
    
    private var bag = Set<AnyCancellable>()
    
    public init() {
        setupBindings()
        
//        visiblePanelStates.source[.windowControls] = .displayedAsWindow
    }
}

public extension AppControlPanelState {
    func toggleWindowControlsVisible() {
        switch visiblePanelStates.source[.windowControls, default: .hidden] {
        case .hidden:
            visiblePanelStates.source[.windowControls] = .displayedAsSibling
        case .displayedAsWindow:
            visiblePanelStates.source[.windowControls] = .displayedAsSibling
        case .displayedAsSibling:
            visiblePanelStates.source[.windowControls] = .hidden
        }
    }
    
    func isWindow(_ panel: PanelSections) -> Bool {
        visiblePanelStates.source[panel] == .displayedAsWindow
    }
    
    func isVisible(_ panel: PanelSections) -> Bool {
        visiblePanelStates.source[panel] != .hidden
    }
    
    func vendPanelBinding(_ panel: PanelSections) -> Binding<FloatableViewMode> {
        func makeNewBinding() -> Binding<FloatableViewMode> {
            Binding<FloatableViewMode>(
                get: {
                    self[panel]
                },
                set: {
                    self[panel] = $0
                }
            )
        }
        return makeNewBinding()
    }
    
    subscript(_ section: PanelSections) -> FloatableViewMode {
        get { visiblePanelStates.source[section, default: section.defaultMode] }
        set { visiblePanelStates.source[section] = newValue }
    }
}

private extension AppControlPanelState {
    
    func setupBindings() {
        print("Not implemented: \(#function)")
    }
}
