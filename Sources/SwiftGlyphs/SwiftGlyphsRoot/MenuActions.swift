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

enum MenuPage {
    case actions
    case settings
    case coloring
}

struct MenuActions: View {
    @State var selection: MenuPage = .actions
    
    var body: some View {
        TabView(selection: $selection) {
            actionsContent
                .tabItem {
                    Label(title: { Text("Actions") }, icon: { Image(systemName: "filemenu.and.selection") })
                }
                .navigationTitle("Actions")
                .tag(MenuPage.actions)
            
            settingsContent
                .tabItem {
                    Label(title: { Text("Settings") }, icon: { Image(systemName: "gear") })
                }
                .navigationTitle("Settings Editor")
                .tag(MenuPage.settings)
            
            colorContent
                .tabItem {
                    Label(title: { Text("Coloring") }, icon: { Image(systemName: "paintpalette") })
                }
                .navigationTitle("Syntax Coloring")
                .tag(MenuPage.coloring)
        }
    }
    
    var settingsContent: some View {
        GlobalLiveConfigEditor()
    }
    
    var colorContent: some View {
        GlobalLiveConfigEditorColor()
    }

    var actionsContent: some View {
        List {
            Section("Atlas") {
                LabeledContent("Totally clear atlas", content: {
                    deleteAtlasButton
                })
                
                LabeledContent("Run preload (autosaves)", content: {
                    preloadAtlasButton
                })
                
                LabeledContent("Save texture atlas", content: {
                    saveAtlasButton
                })
            }
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            
            Section("Settings") {
                LabeledContent("Reset to default settings", content: {
                    resetDefaultConfigButton
                })
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
    
    var preloadAtlasButton: some View {
        Button("Preload") {
            GlobalInstances.defaultAtlas.preload()
        }
    }
    
    var saveAtlasButton: some View {
        Button("Save") {
            GlobalInstances.defaultAtlas.save()
        }
    }
    
    var resetDefaultConfigButton: some View {
        Button("Reset") {
            GlobalLiveConfig.store.preference = GlobalLiveConfig()
        }
    }
}
