//
//  SwitchModeButtonsMobile.swift
//  SwiftGlyph
//
//  Created by Ivan Lugo on 11/3/24.
//


import SwiftUI
import BitHandling

struct SwitchModeButtonsMobile: View {
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
        }
    }
    
    var buttonView: some View {
        RoundedRectangle(cornerRadius: 4)
            .frame(width: 40, height: 20)

    }
}
