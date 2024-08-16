//
//  SourceInfoPanelState.swift
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
    case testStreamInput = "(Test) Stream Input"
    
    public static func < (lhs: PanelSections, rhs: PanelSections) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
    
    static var sorted: [PanelSections] {
        allCases.sorted(by: { $0.rawValue < $1.rawValue} )
    }
}

public class SourceInfoPanelState: ObservableObject {
    // MARK: - Reused states
    public var fileBrowserState = FileBrowserViewState()
    
    // Category pannel state
    public struct Categories {
        var expandedGrids = Set<CodeGrid.ID>()
    }
    @Published public var categories: Categories = Categories()

    // Visible subsections
    @Published public var visiblePanelStates = CodableAutoCache<PanelSections, FloatableViewMode>() {
        didSet {
            AppStatePreferences.shared.panelStates = visiblePanelStates
        }
    }
    
    private var bag = Set<AnyCancellable>()
    
    public init() {
        self.visiblePanelStates = AppStatePreferences.shared.panelStates ?? Self.defaultStates()
        
        setupBindings()
    }
    
    private static func defaultStates() -> CodableAutoCache<PanelSections, FloatableViewMode> {
        PanelSections.allCases.reduce(
            into: CodableAutoCache<PanelSections, FloatableViewMode>()
        ) { cache, section in
            switch section {
            case .windowControls,
                    .directories,
                    .appStatusInfo:
                cache.source[section] = .displayedAsWindow
            default:
                cache.source[section] = .hidden
            }
        }
    }
}

public extension SourceInfoPanelState {
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
    
    func getPanelIsWindowBinding(_ panel: PanelSections) -> Binding<Bool> {
        func makeNewBinding() -> Binding<Bool> {
            Binding<Bool>(
                get: {
                    self[panel] == .displayedAsWindow
                },
                set: { isSelected in
                    let oldState = self[panel]
                    let newState = isSelected
                        ? FloatableViewMode.displayedAsWindow
                        : oldState
                    self[panel] = newState
                }
            )
        }
        return makeNewBinding()
    }
    
    func vendPanelVisibleBinding(_ panel: PanelSections) -> Binding<Bool> {
        func makeNewBinding() -> Binding<Bool> {
            Binding<Bool>(
                get: { self[panel] != .hidden },
                set: { isSelected in
                    switch isSelected {
                    case true: self[panel] = .displayedAsWindow
                    case false: self[panel] = .hidden
                    }
                }
            )
        }
        return makeNewBinding()
    }
}

private extension SourceInfoPanelState {
    subscript(_ section: PanelSections) -> FloatableViewMode {
        get { visiblePanelStates.source[section, default: .hidden] }
        set { visiblePanelStates.source[section] = newValue }
    }
    
    func setupBindings() {
        print("Not implemented: \(#function)")
    }
}
