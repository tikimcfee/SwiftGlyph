//
//  SwitchModeButtons.swift
//  SwiftGlyph
//
//  Created by Ivan Lugo on 11/3/24.
//


import SwiftUI
import BitHandling

struct SwitchModeButtons: View {
    @Binding var displayMode: FloatableViewMode
    let windowKey: GlobalWindowKey
    
    var body: some View {
        HStack {
            if windowKey != .windowControls {
                buttonView
                    .foregroundStyle(.red.opacity(0.8))
                    .onTapGesture {
                        displayMode = .hidden
                    }
            }

            switch displayMode {
            case .displayedAsSibling:
                buttonView
                    .foregroundStyle(.yellow.opacity(0.8))
                    .onTapGesture {
                        displayMode = .displayedAsWindow
                    }
                
                
            case .displayedAsWindow:
                buttonView
                    .foregroundStyle(.yellow.opacity(0.8))
                    .onTapGesture {
                        displayMode = .displayedAsSibling
                    }
                
            case .hidden:
                EmptyView()
            }
        }
    }
    
    var buttonView: some View {
        Circle()
            .frame(width: 12, height: 12)

    }
}