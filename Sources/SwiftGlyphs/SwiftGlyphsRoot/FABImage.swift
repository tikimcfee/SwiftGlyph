//
//  FABImage.swift
//  SwiftGlyph
//
//  Created by Ivan Lugo on 11/16/24.
//


import SwiftUI

public struct FABImage: View {
    let name: String
    
    init(_ name: String) {
        self.name = name
    }
    
    public var body: some View {
        buttonImage(name)
    }
    
    func buttonImage(_ name: String) -> some View {
        Image(systemName: name)
            .renderingMode(.template)
            .frame(width: 40, height: 40)
            .foregroundStyle(.red.opacity(0.8))
            .padding(6)
            .background(.blue.opacity(0.2))
            .contentShape(Rectangle())
            .clipShape(Circle())
    }
}
