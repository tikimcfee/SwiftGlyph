//
//  FileBrowserRowView.swift
//  SwiftGlyph
//
//  Created by Ivan Lugo on 10/27/24.
//


import Combine
import SwiftUI
import Foundation
import BitHandling

struct FileBrowserRowView: View {
    let scope: FileBrowser.Scope
    let depth: Int
    
    @Binding var hoveredScope: FileBrowser.Scope?
    var isHovered: Bool {
        scope.path == hoveredScope?.path
    }
    
    let onEvent: (FileBrowserEvent) -> Void

    var body: some View {
        HStack(spacing: 0) {
            makeSpacer(depth)
            rowContent()
        }
        .background(isHovered ? Color.blue.opacity(0.05) : Color.clear)
        .onHover { isHovering in
            if isHovering {
                hoveredScope = scope
            } else if hoveredScope == scope {
                hoveredScope = nil
            }
        }
        .onTapGesture {
            if scope.isDirectoryType {
                GlobalInstances.fileBrowser.onScopeSelected(
                    scope,
                    recursive: GlobalInstances
                        .debugCamera
                        .interceptor
                        .state
                        .currentModifiers
                        .contains(.shift)
                )
            } else {
                onEvent(.init(scope, .toggle))
            }
        }
        .padding(2)
    }

    @ViewBuilder
    func makeSpacer(_ depth: Int) -> some View {
        if depth == 0 {
            EmptyView()
        } else {
            Spacer()
                .frame(width: CGFloat(depth) * 8.0)
        }
    }

    @ViewBuilder
    func rowContent() -> some View {
        HStack(spacing: 2) {
            // Left Icon
            if scope.isDirectoryType {
                Image(systemName: scope.directoryStateIconName)
                    .font(.footnote)
                    .frame(width: 8)
            }
            Image(systemName: scope.mainIconName)
                .aspectRatio(contentMode: .fit)
                .font(.footnote)
                .padding(.leading, 12)
                .padding(1)

            // File/Directory Name
            Text(scope.path.lastPathComponent)
                .fontWeight(scope.fontWeight)

            Spacer()

            // Hover Action Button
            #if os(iOS)
            if scope.isDirectoryType {
                showDirectoryButton(scope)
                    .padding(2)
            }
            #else
            if isHovered && scope.isDirectoryType {
                showDirectoryButton(scope)
            }
            #endif
        }
        .background(Color.gray.opacity(0.001))
    }

    func showDirectoryButton(_ scope: FileBrowser.Scope) -> some View {
        Button(
            action: {
                onEvent(FileBrowserEvent(scope, .toggle))
            },
            label: {
                Text("Show All")
                    .font(.caption2)
            }
        )
        .padding(.horizontal, 4)
        .padding(.vertical, 1)
        .background(
            RoundedRectangle(cornerRadius: 4.0)
                .foregroundColor(.blue.opacity(0.6))
        )
        .buttonStyle(.plain)
        #if os(macOS)
        .onLongPressGesture(perform: {
            NSPasteboard.general.declareTypes([.string], owner: nil)
            NSPasteboard.general.setString(scope.path.path(), forType: .string)
        })
        #endif
    }
}
