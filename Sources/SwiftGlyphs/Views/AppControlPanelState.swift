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
    case editor = "2D Editor"
    case directories = "Directories"
    case semanticCategories = "Semantic Categories"
    case hoverInfo = "Hover Info"
    case tracingInfo = "Tracing Info"
    case globalSearch = "Global Search"
    case windowControls = "Window Controls"
    case appStatusInfo = "App Status Info"
    case gridStateInfo = "Grid State Info"
    case githubTools = "GitHub Tools"
    case focusState = "Focus State"
    case menuActions = "Menu Actions"
    
    public static func < (lhs: PanelSections, rhs: PanelSections) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
    
    static var sorted: [PanelSections] {
        allCases.sorted(by: { $0.rawValue < $1.rawValue} )
    }
}

public class AppControlPanelState: ObservableObject {
    // MARK: - Reused states
    public var fileBrowserState = FileBrowserViewState()

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
        get { visiblePanelStates.source[section, default: .hidden] }
        set { visiblePanelStates.source[section] = newValue }
    }
}

private extension AppControlPanelState {
    
    func setupBindings() {
        print("Not implemented: \(#function)")
    }
}
