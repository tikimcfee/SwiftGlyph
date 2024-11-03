//
//  AppStatePreferences.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 5/26/22.
//

import BitHandling
import SwiftUI

extension AppStatePreferences {
    var panelStates: CodableAutoCache<PanelSections, FloatableViewMode> {
        get { _getEncoded(.panelStates) ?? Self.defaultStates() }
        set { _setEncoded(newValue, .panelStates) }
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
