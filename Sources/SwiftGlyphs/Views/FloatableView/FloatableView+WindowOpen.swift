//
//  FloatableView+ViewExtension.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 5/14/22.
//

import SwiftUI

#if os(macOS)
extension FloatableView {
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
        case .hidden:
            EmptyView()
        }
    }

    // `Undock` is called when review is rebuilt, check state before calling window actions
    func performUndock() {
//        guard displayMode == .displayedAsWindow else { return }
        guard !delegate.windowIsDisplayed(for: windowKey) else { return }
        displayWindowWithNewBuilderInstance()
    }
    
    // `Dock` is called when review is rebuilt, check state before calling window actions
    func performDock() {
//        guard displayMode == .displayedAsSibling else { return }
        delegate.dismissWindow(for: windowKey)
    }
    
    func displayWindowWithNewBuilderInstance() {
        VStack(alignment: .leading, spacing: 0) {
            switchModeButton()
            innerViewBuilder()
        }.openInWindow(key: windowKey, sender: self)
    }
}

extension View {
    
    @discardableResult
    func openInWindow(key: GlobalWindowKey, sender: Any?) -> NSWindow {
        let window = GlobalWindowDelegate.instance
            .window(for: key, makeNewWindow(for: key))
        window.contentView = NSHostingView(rootView: self)
        return window
    }
    
    private func makeNewWindow(for key: GlobalWindowKey) -> NSWindow {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 600),
            styleMask: [.titled, .fullSizeContentView, .resizable],
            backing: .buffered,
            defer: false
        )
        // TODO: make this configurable. Options object, attached to key, something
        window.setFrameAutosaveName(key.title)
//        window.level = .modalPanel
        window.title = key.title
        
        // THIS IS CRITICAL!
        // The window lifecycle is fragile here, and the window
        // can and will crash if it is immediately released on close.
        // Allow it to stick around long enough for the willClose notification
        // to come around and then clear the store then.
        window.isReleasedWhenClosed = false
        
        return window
    }
}
#endif
