//
//  AppWindowTogglesView.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 5/15/22.
//

import SwiftUI
import BitHandling

public struct AppWindowTogglesView: View {
    @ObservedObject public var state: AppControlPanelState
    
    public init(state: AppControlPanelState) {
        self.state = state
    }
    
    public var body: some View {
        ScrollView {
            VStack {
                ForEach(PanelSections.sorted, id: \.self) { section in
                    sectionRow(section)
                    Divider()
                }
            }
            .padding(8)
        }
    }
    
    @ViewBuilder
    func sectionRow(_ section: PanelSections) -> some View {
        HStack {
            Text(section.rawValue)
                .layoutPriority(1)
            
            Spacer()
            
            if section != .windowControls {
                Picker(
                    "",
                    selection: $state[section],
                    content: {
                        ForEach(modes(for: section)) { mode in
                            Text("\(mode.segmentedControlName)")
                                .tag(mode)
                        }
                    }
                )
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(width: 120)
            }
            
            resetControl(section)
        }
    }
    
    func modes(for section: PanelSections) -> [FloatableViewMode] {
        #if os(macOS)
        switch section {
        case .windowControls:
            [.displayedAsSibling, .displayedAsWindow]
        default:
            FloatableViewMode.allCases
        }
        #else
        switch section {
        case .windowControls:
            []
        default:
            [.hidden, .displayedAsSibling]
        }
        #endif
    }
    
    @ViewBuilder
    func resetControl(_ section: PanelSections) -> some View {
        Button(
            action: {
                DispatchQueue.main.async {
                    state[section] = .hidden
                }
                DispatchQueue.main.async {
                    section.setDragState(
                        ComponentModel(
                            componentInfo: ComponentState(
                                origin: .init(x: 512, y: 512),
                                size: .init(width: 300, height: 300)
                            )
                        )
                    )
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    state[section] = .displayedAsSibling
                }
            },
            label: {
                Text("⊜")
            }
        )
    }
}

struct AppWindowTogglesView_Preview: PreviewProvider {
    static let state = AppControlPanelState()
    static var previews: some View {
        return AppWindowTogglesView(state: state)
    }
}
