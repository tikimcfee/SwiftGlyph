//
//  MenuActions.swift
//  SwiftGlyph
//
//  Created by Ivan Lugo on 10/10/24.
//

import SwiftUI
import MetalLink
import BitHandling
import STTextViewSwiftUI

struct MenuActions: View {
    var body: some View {
        actionsContent
    }

    var actionsContent: some View {
        List {
            Section("Atlas") {
                LabeledContent("Save texture atlas", content: {
                    saveAtlasButton
                })
                
                LabeledContent("Totally clear atlas", content: {
                    deleteAtlasButton
                })
                
                LabeledContent("Run preload (autosaves)", content: {
                    preloadAtlasButton
                })
            }
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            
            Section("Configs") {
                saveDefaultConfigButton
                resetDefaultConfigButton
            }
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        }
        #if os(iOS)
        .listStyle(.grouped)
        #endif
        .buttonStyle(.bordered)
        .tint(Color.primaryForeground)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    var deleteAtlasButton: some View {
        Button("Clear") {
            GlobalInstances.resetAtlas()
        }
    }
    
    var saveAtlasButton: some View {
        Button("Save") {
            GlobalInstances.defaultAtlas.save()
        }
    }
    
    var preloadAtlasButton: some View {
        Button("Preload") {
            GlobalInstances.defaultAtlas.preload()
        }
    }
    
    var saveDefaultConfigButton: some View {
        Button("Save Default") {
            GlobalLiveConfig.saveDefault()
        }
    }
    
    var resetDefaultConfigButton: some View {
        Button("Reset Default") {
            GlobalLiveConfig.saveDefault()
        }
    }
}
