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
    @State private var results: [OmniAction]
    @State private var selection: OmniAction?
    
    public init(
        results: [OmniAction] = []
    ) {
        self.results = results
    }
    
    var body: some View {
        VStack {
            TextField("Quick Search and Actions", text: $searchText)
                .focused($focus, equals: .input)
                .onKeyPress(.downArrow) {
                    focus = .list
                    selection = results.first
                    return .handled
                }
                .textFieldStyle(.plain)
                .padding()
            
            if !results.isEmpty {
                List(results, id: \.self, selection: $selection) { result in
                    Text(result.actionDisplay)
                        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                        .listRowSeparator(.hidden)
                }
                .focused($focus, equals: .list)
                .onKeyPress(.return) {
                    guard let selection else { return .ignored }
                    selection.perform()
                    omniBarManager.dismissOmnibar()
                    return .handled
                }
            }
        }
        .padding(2)
        .background(Color.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .frame(maxWidth: 600, maxHeight: 800)
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

var action: OmniAction {
    OmniAction(
        trigger: .gridJump,
        sourceQuery: "query",
        actionDisplay: "\(String("23dasdasdq3e2".randomSample(count: 5)))",
        perform: {
    
        }
    )
}

#Preview {
    OmnibarView(
        results: [
            action,
            action,
            action,
            action,
            action,
            action,
            action,
            action,
            action,
            action,
            action,
            action,
            action,
            action,
            action,
        ]
    )
}

#endif
