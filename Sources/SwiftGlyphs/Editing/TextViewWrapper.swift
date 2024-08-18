//
//  File.swift
//  
//
//  Created by Ivan Lugo on 8/17/24.
//

import SwiftUI

#if canImport(STTextViewSwiftUI)
import STTextViewSwiftUI
#endif

struct TextViewWrapper: View {
    @ObservedObject var holder = GlobalInstances.userTextEditHolder
    
    var body: some View {
#if os(macOS)
        TextView(
            text: $holder.userTextInput,
            selection: $holder.userTextSelection,
            options: [],
            plugins: []
        )
        .textViewFont(.monospacedSystemFont(ofSize: 14, weight: .regular))
#else
        Text("Text editing is hard for da little phone buddies. Gotta have big beefy operating system to actually edit words. Go figure.")
#endif
    }
    
    
}
