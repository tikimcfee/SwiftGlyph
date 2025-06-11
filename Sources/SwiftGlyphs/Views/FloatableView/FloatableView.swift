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
            "eye.slash"
        case .displayedAsWindow:
            "macwindow.on.rectangle"
        case .displayedAsSibling:
            "uiwindow.split.2x1"
        }
    }
}

public struct FloatableView<Inner: View>: View {
    @Binding var displayMode: FloatableViewMode
    let windowKey: GlobalWindowKey
    let innerViewBuilder: () -> Inner
    
    public init(
        displayMode: Binding<FloatableViewMode>,
        windowKey: GlobalWindowKey,
        innerViewBuilder: @escaping () -> Inner
    ) {
        self._displayMode = displayMode
        self.windowKey = windowKey
        self.innerViewBuilder = innerViewBuilder
    }
    
    public var body: some View {
        makePlatformBody()
    }
}

#if os(iOS)
public extension FloatableView {
    @ViewBuilder
    func makePlatformBody() -> some View {
        switch displayMode {
        case .displayedAsSibling, .displayedAsWindow:
            ResizableComponentView(
                displayMode: $displayMode,
                windowKey: windowKey,
                model: windowKey.getDragState,
                onSave: windowKey.setDragState,
                content: {
                    coreContent(isWindow: false)
                }
            )
            
        case .hidden:
            EmptyView()
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
