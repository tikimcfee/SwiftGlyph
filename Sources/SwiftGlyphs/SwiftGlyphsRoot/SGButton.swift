//
//  SGButton.swift
//  SwiftGlyph
//
//  Created by Ivan Lugo on 11/16/24.
//


import SwiftUI
import BitHandling

public enum SGButtonStyle {
    case toolbar
    case medium
    case small
    
    var padding: EdgeInsets {
        switch self {
        case .toolbar: return .init(top: 6, leading: 8, bottom: 6, trailing: 8)
        case .medium: return .init(top: 4, leading: 4, bottom: 4, trailing: 4)
        case .small: return .init(top: 1, leading: 4, bottom: 1, trailing: 4)
        }
    }
}

public func SGButton(
    _ text: String,
    _ image: String,
    _ style: SGButtonStyle = .small,
    _ action: @escaping () -> Void
) -> some View {
    Button(
        action: action,
        label: {
            HStack {
                if !text.isEmpty {
                    Text(text)
                        .font(.caption2)
                }
                
                if !image.isEmpty {
                    Image(systemName: image)
                }
            }
            .padding(style.padding)
            .background(Color.primarySGButtonBackground)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    )
    .buttonStyle(.plain)
}
