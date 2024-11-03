//
//  File.swift
//  
//
//  Created by Ivan Lugo on 8/16/24.
//

import BitHandling

public typealias GlobalWindowKey = PanelSections

extension GlobalWindowKey: Identifiable, Hashable {
    public var id: String { rawValue }
    var title: String { rawValue }
}

public extension GlobalWindowKey {
    func setDragState(_ newValue: ComponentModel) {
        AppStatePreferences.shared.setCustom(
            name: persistedDragStateName,
            value: newValue
        )
    }
    
    func getDragState() -> ComponentModel {
        AppStatePreferences.shared.getCustom(
            name: persistedDragStateName,
            makeDefault: { ComponentModel() }
        )
    }
    
    var persistedDragStateName: String {
        "DragState-\(rawValue)"
    }
}
