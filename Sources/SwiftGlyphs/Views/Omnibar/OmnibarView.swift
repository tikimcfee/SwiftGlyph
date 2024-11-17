//
//  Bar.swift
//  SwiftGlyph
//
//  Created by Ivan Lugo on 11/10/24.
//

#if os(macOS)
import SwiftUI
import MetalLink

extension GlobalWindowKey {
    static let omnibar = GlobalWindowKey.unregistered("omnibar-v1.0.0")
}

enum Focus {
    case input
    case list
}

struct OmnibarView: View {
    @ObservedObject var omniBarManager: OmnibarManager = GlobalInstances.omnibarManager
    
    @FocusState private var focus: Focus?
    
    @State private var searchText = ""
    @State private var results: [OmniAction] = []
    @State private var selection: OmniAction?
    
    var body: some View {
        VStack {
            TextField("Search...", text: $searchText)
                .focused($focus, equals: .input)
                .onKeyPress(.downArrow) {
                    focus = .list
                    selection = results.first
                    return .handled
                }
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            List(results, id: \.self, selection: $selection) { result in
                Text(result.actionDisplay)
            }
            .frame(maxHeight: 400)
            .focused($focus, equals: .list)
            .onKeyPress(.return) {
                guard let selection else { return .ignored }
                selection.perform()
                omniBarManager.dismissOmnibar()
                return .handled
            }
        }
        .frame(maxWidth: 600, maxHeight: 400)
        .onAppear {
            focus = .input
            omniBarManager.focusOmnibar()
        }
        .onDisappear {
            focus = nil
        }
        .onChange(of: searchText) { old, new in
            results = actions(for: new)
        }
    }
    
    func actions(for query: String) -> [OmniAction] {
        omniBarManager.lookup(query)
    }
}
#endif
