//
//  FloatableView.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 5/14/22.
//

import SwiftUI
import BitHandling

public enum FloatableViewMode: Codable, Identifiable, Equatable, CaseIterable {
    public var id: Self { self }
    
    case hidden
    case displayedAsSibling
    case displayedAsWindow
    
    var segmentedControlName: String {
        switch self {
        case .hidden:
            "⤫"
        case .displayedAsWindow:
            "✚"
        case .displayedAsSibling:
            "⿴"
        }
    }
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
                model: windowKey.getDragState,
                onSave: windowKey.setDragState,
                content: {
                    coreContent(isWindow: false)
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
            Spacer()
                .onAppear { performDock() }
            
        case .displayedAsSibling:
            ResizableComponentView(
                displayMode: $displayMode,
                windowKey: windowKey, 
                model: windowKey.getDragState,
                onSave: windowKey.setDragState,
                content: {
                    coreContent(isWindow: false)
                }
            )
            .onAppear { performDock() }
            
        case .displayedAsWindow:
            Spacer()
                .onAppear { performUndock() }
                .onDisappear { performDock() }
        }
    }
    
    @ViewBuilder
    func coreContent(isWindow: Bool) -> some View {
        innerViewBuilder()
            .padding(isWindow ? 8 : 0)
            .border(.black, width: isWindow ? 0.0 : 1.0)
            .background(
                isWindow
                    ? nil
                    : Color(red: 0.2, green: 0.2, blue: 0.2, opacity: 0.2)
            )
    }
}

struct SwitchModeButtons: View {
    @Binding var displayMode: FloatableViewMode
    let windowKey: GlobalWindowKey
    
    var body: some View {
        HStack {
            if windowKey != .windowControls {
                buttonView
                    .foregroundStyle(.red.opacity(0.8))
                    .onTapGesture {
                        displayMode = .hidden
                    }
            }

            switch displayMode {
            case .displayedAsSibling:
                buttonView
                    .foregroundStyle(.yellow.opacity(0.8))
                    .onTapGesture {
                        displayMode = .displayedAsWindow
                    }
                
                
            case .displayedAsWindow:
                buttonView
                    .foregroundStyle(.yellow.opacity(0.8))
                    .onTapGesture {
                        displayMode = .displayedAsSibling
                    }
                
            case .hidden:
                EmptyView()
            }
        }
    }
    
    var buttonView: some View {
        Circle()
            .frame(width: 12, height: 12)

    }
}

extension FloatableView {
    var delegate: GlobalWindowDelegate { GlobalWindowDelegate.instance }

    // `Undock` is called when review is rebuilt, check state before calling window actions
    func performUndock() {
        guard !delegate.windowIsDisplayed(for: windowKey) else { return }
        displayWindowWithNewBuilderInstance()
    }
    
    // `Dock` is called when review is rebuilt, check state before calling window actions
    func performDock() {
        delegate.dismissWindow(for: windowKey)
    }
    
    func displayWindowWithNewBuilderInstance() {
        coreContent(isWindow: true)
            .openInWindow(key: windowKey, mode: $displayMode)
    }
}
#endif
