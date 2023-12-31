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
    public var dragViewState = DragSizableViewState()
    
    // Category pannel state
    public struct Categories {
        var expandedGrids = Set<CodeGrid.ID>()
    }
    @Published public var categories: Categories = Categories()

    // Visible subsections
    @Published public private(set) var visiblePanelStates = CodableAutoCache<PanelSections, FloatableViewMode>() {
        didSet {
            savePanelWindowStates()
        }
    }
    
    @Published public private(set) var visiblePanels: Set<PanelSections> {
        didSet {
            savePanelStates()
            updatePanelSlices()
        }
    }
    
    var panelGroups = 3
    @Published public private(set) var visiblePanelSlices: [ArraySlice<PanelSections>] = []
    
    private var bag = Set<AnyCancellable>()
    
    public init() {
        self.visiblePanels = AppStatePreferences.shared.visiblePanels
            ?? [.windowControls, .directories, .appStatusInfo]
        self.visiblePanelStates = AppStatePreferences.shared.panelStates
            ?? {
                var states = CodableAutoCache<PanelSections, FloatableViewMode>()
                states.source[.windowControls] = .displayedAsWindow
                states.source[.directories] = .displayedAsWindow
                states.source[.appStatusInfo] = .displayedAsWindow
                return states
            }()
        
        setupBindings()
        updatePanelSlices()
    }
}

public extension SourceInfoPanelState {
    func isWindow(_ panel: PanelSections) -> Bool {
        visiblePanelStates.source[panel] == .displayedAsWindow
    }
    
    func isVisible(_ panel: PanelSections) -> Bool {
        visiblePanels.contains(panel)
    }
    
    func vendPanelBinding(_ panel: PanelSections) -> Binding<FloatableViewMode> {
        func makeNewBinding() -> Binding<FloatableViewMode> {
            Binding<FloatableViewMode>(
                get: {
                    self.visiblePanelStates.source[panel, default: .displayedAsSibling]
                },
                set: {
                    self.visiblePanelStates.source[panel] = $0
                }
            )
        }
        return makeNewBinding()
    }
    
    func vendPanelIsWindowBinding(_ panel: PanelSections) -> Binding<Bool> {
        func makeNewBinding() -> Binding<Bool> {
            Binding<Bool>(
                get: {
                    self.visiblePanelStates
                        .source[panel, default: .displayedAsSibling]
                     == .displayedAsWindow
                },
                set: { isSelected in
                    let newState = isSelected
                        ? FloatableViewMode.displayedAsWindow
                        : FloatableViewMode.displayedAsSibling
                    self.visiblePanelStates.source[panel] = newState
                }
            )
        }
        return makeNewBinding()
    }
    
    func vendPanelVisibleBinding(_ panel: PanelSections) -> Binding<Bool> {
        func makeNewBinding() -> Binding<Bool> {
            Binding<Bool>(
                get: { self.visiblePanels.contains(panel) },
                set: { isSelected in
                    switch isSelected {
                    case true: self.visiblePanels.insert(panel)
                    case false: self.visiblePanels.remove(panel)
                    }
                }
            )
        }
        return makeNewBinding()
    }
}

private extension SourceInfoPanelState {
    func updatePanelSlices() {
        guard !visiblePanels.isEmpty else {
            visiblePanelSlices = []
            return
        }
        let sortedPanelList = Array(visiblePanels).sorted(by: <)
        visiblePanelSlices = sortedPanelList
            .slices(sliceSize: panelGroups)
    }
    
    func savePanelStates() {
        AppStatePreferences.shared.visiblePanels = visiblePanels
    }
    
    func savePanelWindowStates() {
        AppStatePreferences.shared.panelStates = visiblePanelStates
    }
    
    func setupBindings() {
        print("Not implemented: \(#function)")
    }
}
