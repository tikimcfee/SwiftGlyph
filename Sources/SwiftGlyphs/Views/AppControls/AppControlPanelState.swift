//
//  AppControlPanelState.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 4/23/22.
//

import Combine
import SwiftUI
import BitHandling


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
    func resetSection(_ section: PanelSections) {
        DispatchQueue.main.async {
            self[section] = .hidden
        }
        DispatchQueue.main.async {
            section.setDragState(
                ComponentModel(
                    componentInfo: ComponentState(
                        origin: .init(x: 120, y: 120),
                        size: .init(width: 300, height: 300)
                    )
                )
            )
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self[section] = .displayedAsSibling
        }
    }
    
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
        get {
            visiblePanelStates.source[section, default: section.defaultMode]
        }
        set {
            let current = visiblePanelStates.source[section]
            guard current != newValue else { return }
            visiblePanelStates.source[section] = newValue
        }
    }
}

private extension AppControlPanelState {
    
    func setupBindings() {
        print("Not implemented: \(#function)")
    }
}
