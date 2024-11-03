//
//  File.swift
//  
//
//  Created by Ivan Lugo on 8/17/24.
//

import SwiftUI

import STTextView
import STTextViewSwiftUI

struct TextViewWrapper: View {
    @ObservedObject var holder = GlobalInstances.userTextEditHolder
    @ObservedObject var renderer = GlobalInstances.userTextEditRenderer
    
    var body: some View {
        TextView(
            text: $holder.userTextInput,
            selection: $holder.userTextSelection,
            options: [],
            plugins: []
        )
        .preferredColorScheme(.dark)
        .foregroundStyle(.white)
    }
}
