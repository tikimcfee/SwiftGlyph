//
//  FloatableView.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 5/14/22.
//

import SwiftUI
import BitHandling

public enum FloatableViewMode: Codable, CaseIterable {
    case hidden
    case displayedAsWindow
    case displayedAsSibling
}

public struct FloatableView<Inner: View>: View {
    @Binding var displayMode: FloatableViewMode
    let windowKey: GlobalWindowKey
    var resizableAsSibling: Bool = false
    let innerViewBuilder: () -> Inner
    
    let initialSize: CGSize
    @State var maxSiblingSize: CGSize
    
    public init(
        displayMode: Binding<FloatableViewMode>,
        windowKey: GlobalWindowKey,
        maxSiblingSize: CGSize,
        resizableAsSibling: Bool,
        innerViewBuilder: @escaping () -> Inner
    ) {
        self._displayMode = displayMode
        self._maxSiblingSize = State(wrappedValue: maxSiblingSize)
        self.initialSize = maxSiblingSize
        self.windowKey = windowKey
        self.resizableAsSibling = resizableAsSibling
        self.innerViewBuilder = innerViewBuilder
    }
    
    public init(
        displayMode: Binding<FloatableViewMode>,
        windowKey: GlobalWindowKey,
        resizableAsSibling: Bool,
        innerViewBuilder: @escaping () -> Inner
    ) {
        self._displayMode = displayMode
        self._maxSiblingSize = State(initialValue: CGSize(width: -1, height: -1))
        self.initialSize = CGSize(width: -1, height: -1)
        self.windowKey = windowKey
        self.resizableAsSibling = resizableAsSibling
        self.innerViewBuilder = innerViewBuilder
    }
    
    public var body: some View {
        makePlatformBody()
            .onChange(of: displayMode, initial: true) {
                maxSiblingSize = switch displayMode {
                case .displayedAsWindow:
                    .init(width: -1, height: -1)
                case .displayedAsSibling, .hidden:
                    initialSize
                }
            }
            .frame(
                maxWidth: maxSiblingSize.width > 0 ? maxSiblingSize.width : nil,
                maxHeight: maxSiblingSize.height > 0 ? maxSiblingSize.height : nil
            )
    }
}

#if os(iOS)
public extension FloatableView {
    @ViewBuilder
    func makePlatformBody() -> some View {
        if resizableAsSibling {
            ResizableComponentView(
                model: {
                    windowKey.getDragState()
                },
                onSave: { model in
                    windowKey.setDragState(model)
                },
                content: {
                    innerViewBuilder()
                }
            )
        } else {
            innerViewBuilder()
        }
    
    }
}
#elseif os(macOS)
public extension FloatableView {
    @ViewBuilder
    func makePlatformBody() -> some View {
        switch displayMode {
        case .hidden:
            EmptyView()
                .onAppear { performDock() }
            
        case .displayedAsSibling:
            ResizableComponentView(
                model: {
                    windowKey.getDragState()
                },
                onSave: { model in
                    windowKey.setDragState(model)
                },
                content: {
                    VStack(alignment: .leading, spacing: 0) {
                        switchModeButton()
                        innerViewBuilder()
                    }
                }
            )
            .onAppear { performDock() }
            
        case .displayedAsWindow:
            Spacer()
                .onAppear { performUndock() }
                .onDisappear { performDock() }
        }
    }
}
#endif
