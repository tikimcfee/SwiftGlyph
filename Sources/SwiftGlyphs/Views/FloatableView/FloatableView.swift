//
//  FloatableView.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 5/14/22.
//

import SwiftUI
import BitHandling

public typealias GlobalWindowKey = PanelSections

extension GlobalWindowKey: Identifiable, Hashable {
    public var id: String { rawValue }
    var title: String { rawValue }
}

public enum FloatableViewMode: Codable {
    case displayedAsWindow
    case displayedAsSibling
}

public extension GlobalWindowKey {
    func setDragState(_ newValue: ComponentModel) {
        AppStatePreferences.shared.setCustom(
            name: persistedDragStateName,
            value: newValue
        )
    }
    
    func getDragState() -> ComponentModel {
        AppStatePreferences.shared.getCustom(
            name: persistedDragStateName,
            makeDefault: { ComponentModel() }
        )
    }
    
    var persistedDragStateName: String {
        "DragState-\(rawValue)"
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
                case .displayedAsSibling:
                    initialSize
                }
            }
            .frame(
                maxWidth: maxSiblingSize.width > 0 ? maxSiblingSize.width : nil,
                maxHeight: maxSiblingSize.height > 0 ? maxSiblingSize.height : nil
            )
    }
}

public extension FloatableView {
    @ViewBuilder
    func makePlatformBody() -> some View {
    #if os(iOS)
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
    #elseif os(macOS)
        switch displayMode {
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
        case .displayedAsWindow:
            Spacer()
                .onAppear { performUndock() }
                .onDisappear { performDock() }
        }
    #endif
    }
}

#if os(macOS)
private extension FloatableView {
    var delegate: GlobalWindowDelegate { GlobalWindowDelegate.instance }
    
    @ViewBuilder
    func switchModeButton() -> some View {
        switch displayMode {
        case .displayedAsSibling:
            Button("Undock", action: {
                displayMode = .displayedAsWindow
            }).padding(2)
        case .displayedAsWindow:
            Button("Dock", action: {
                displayMode = .displayedAsSibling
            }).padding(2)
        }
    }

    // `Undock` is called when review is rebuilt, check state before calling window actions
    func performUndock() {
        guard displayMode == .displayedAsWindow else { return }
        guard !delegate.windowIsDisplayed(for: windowKey) else { return }
        displayWindowWithNewBuilderInstance()
    }
    
    // `Dock` is called when review is rebuilt, check state before calling window actions
    func performDock() {
        guard displayMode == .displayedAsSibling else { return }
        delegate.dismissWindow(for: windowKey)
    }
    
    func displayWindowWithNewBuilderInstance() {
        VStack(alignment: .leading, spacing: 0) {
            switchModeButton()
            innerViewBuilder()
        }.openInWindow(key: windowKey, sender: self)
    }
}
#endif
