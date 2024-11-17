//
//  AppControlsTogglesView.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 5/15/22.
//

import SwiftUI
import BitHandling

public struct AppControlsTogglesView: View {
    @ObservedObject public var state: AppControlPanelState
    @State var hoveredSection: PanelSections?
    
    let sections: [PanelSections]
    
    public init(
        state: AppControlPanelState,
        sections: [PanelSections]
    ) {
        self.state = state
        self.sections = sections
    }
    
    public var body: some View {
        ScrollView {
            VStack {
                ForEach(sections, id: \.self) { section in
                    if section != .windowControls {
                        sectionRow(section)
                        Divider()
                    }
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
            
            #if os(iOS)
            resetControl(section)
            #else
            if hoveredSection == section {
                resetControl(section)
            }
            #endif
            
            if section != .windowControls {
                Picker(
                    "",
                    selection: $state[section],
                    content: {
                        ForEach(modes(for: section)) { mode in
                            Image(systemName:"\(mode.segmentedControlName)")
                                .tag(mode)
                        }
                    }
                )
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(width: 120)
            }
        }
        .contentShape(Rectangle())
        .onHover { hovered in
            if hovered {
                hoveredSection = section
            } else if hoveredSection == section {
                hoveredSection = nil
            }
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
                state.resetSection(section)
            },
            label: {
                Image(systemName: "arrow.clockwise")
            }
        )
    }
}

struct AppControlsTogglesView_Preview: PreviewProvider {
    static let state = AppControlPanelState()
    static var previews: some View {
        return AppControlsTogglesView(state: state, sections: PanelSections.usableWindows)
    }
}
