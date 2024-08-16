//
//  AppControlPanelToggles.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 5/15/22.
//

import SwiftUI
import BitHandling

public struct AppControlPanelToggles: View {
    @ObservedObject public var state: AppControlPanelState
    
    public init(state: AppControlPanelState) {
        self.state = state
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Divider()
            VStack(alignment: .leading) {
                ForEach(PanelSections.sorted, id: \.self) { section in
                    sectionRow(section)
                    Divider()
                }
            }
        }
        .fixedSize()
        .padding()
    }
    
    @ViewBuilder
    func sectionRow(_ section: PanelSections) -> some View {
        HStack {
            Text("\(section.rawValue)")
                .frame(minWidth: 160.0, alignment: .leading)
            
            visibilityControl(section)
//                .disabled(state.isWindow(section))
            
            dockControl(section)
            resetControl(section)
//                .disabled(!state.isVisible(section))
        }
    }
    
    @ViewBuilder
    func resetControl(_ section: PanelSections) -> some View {
        Button(
            action: {
                section.setDragState(.init())
            },
            label: {
                Text("⊜")
            }
        )
    }
    
    @ViewBuilder
    func dockControl(_ section: PanelSections) -> some View {
        Toggle("Window", isOn: state.getPanelIsWindowBinding(section))
    }
    
    @ViewBuilder
    func visibilityControl(_ section: PanelSections) -> some View {
        switch section {
        case .windowControls:
            Spacer()
        default:
            Toggle("Visible", isOn: state.vendPanelVisibleBinding(section))
        }
    }
}

struct AppControlPanelToggles_Preview: PreviewProvider {
    static let state = AppControlPanelState()
    static var previews: some View {
        return AppControlPanelToggles(state: state)
    }
}
