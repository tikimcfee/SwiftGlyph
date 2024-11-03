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
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                Divider()
                VStack(alignment: .leading) {
                    ForEach(PanelSections.sorted, id: \.self) { section in
                        sectionRow(section)
                        Divider()
                    }
                }
            }
            .padding()
        }
    }
    
    @ViewBuilder
    func sectionRow(_ section: PanelSections) -> some View {
        HStack {
            Picker(
                selection: $state[section],
                content: {
                    ForEach(modes(for: section)) { mode in
                        Text("\(mode.segmentedControlName)")
                            .tag(mode)
                    }
                },
                label: {
                    Text("\(section.rawValue)")
                        .frame(minWidth: 160.0, alignment: .leading)
                }
            )
            .pickerStyle(.segmented)
            
            resetControl(section)
        }
    }
    
    func modes(for section: PanelSections) -> [FloatableViewMode] {
        switch section {
        case .windowControls:
            [.displayedAsSibling, .displayedAsWindow]
        default:
            FloatableViewMode.allCases
        }
    }
    
    @ViewBuilder
    func resetControl(_ section: PanelSections) -> some View {
        Button(
            action: {
                section.setDragState(
                    ComponentModel(
                        componentInfo: ComponentState(
                            origin: .init(x: 512, y: 512),
                            size: .init(width: 300, height: 300)
                        )
                    )
                )
                state[section] = .displayedAsSibling
            },
            label: {
                Text("⊜")
            }
        )
    }
}

struct AppControlPanelToggles_Preview: PreviewProvider {
    static let state = AppControlPanelState()
    static var previews: some View {
        return AppControlPanelToggles(state: state)
    }
}
