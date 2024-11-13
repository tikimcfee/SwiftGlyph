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
import MetalLink

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
            HStack(spacing: 4) {
                if isHovered {
                    if scope.isDirectoryType {
                        showDirectoryButton(scope)
                    }
                    
                    jumpButton(scope)
                }
            }
            #endif
        }
        .background(Color.gray.opacity(0.001))
    }
    
    func jumpButton(_ scope: FileBrowser.Scope) -> some View {
        Button(
            action: {
                if let grid = scope.cachedGrid {
                    lockZoomToBounds(of: grid.rootNode)
                }
            },
            label: {
                Text("Jump")
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
    }
    
    func lockZoomToBounds(of node: MetalLinkNode) {
        var bounds = node.worldBounds
//        bounds.min.x -= 4
//        bounds.max.x += 4
//        bounds.min.y -= 8
//        bounds.max.y += 16
        bounds.min.z -= 32
        bounds.max.z += 32
        
//        let position = bounds.center
        GlobalInstances.debugCamera.interceptor.resetPositions()
        GlobalInstances.debugCamera.position = LFloat3(bounds.leading, bounds.top, bounds.front)
        GlobalInstances.debugCamera.rotation = .zero
        GlobalInstances.debugCamera.scrollBounds = bounds
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
