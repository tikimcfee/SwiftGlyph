//
//  Bar.swift
//  SwiftGlyph
//
//  Created by Ivan Lugo on 11/10/24.
//

import SwiftUI
import MetalLink

extension GlobalWindowKey {
    static let omnibar = GlobalWindowKey.unregistered("omnibar-v1.0.0")
}

struct OmnibarView: View {
    @ObservedObject var omniBarManager: OmnibarManager = GlobalInstances.omnibarManager
    
    @FocusState private var focused: Bool
    
    @State private var searchText = ""
    @State private var results: [String] = []
    
    var body: some View {
        VStack {
            TextField("Search...", text: $searchText)
                .focused($focused)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            List(results, id: \.self) { result in
                Text(result)
            }
            .frame(maxHeight: 200)
        }
        .shadow(radius: 5)
        .frame(maxWidth: 600, maxHeight: 400)
        .onAppear {
            focused = true
            omniBarManager.focusOmnibar()
        }
        .onDisappear {
            focused = false
        }
        .onChange(of: searchText) { old, new in
            results = getResults(for: new)
        }
    }
    
    func getResults(for query: String) -> [String] {
        // Implement your search logic here
        // This is a placeholder for demonstration
        let allItems = ["Open File", "Save File", "Close Window", "Exit App"]
        return allItems.filter { $0.lowercased().contains(query.lowercased()) }
    }
}
