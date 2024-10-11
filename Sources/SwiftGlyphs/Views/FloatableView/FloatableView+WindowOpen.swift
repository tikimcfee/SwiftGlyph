//
//  FloatableView+ViewExtension.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 5/14/22.
//

import SwiftUI

#if os(macOS)
extension View {
    
    @discardableResult
    func openInWindow(
        key: GlobalWindowKey,
        mode: Binding<FloatableViewMode>
    ) -> NSWindow {
        let window = GlobalWindowDelegate
            .instance
            .window(
                for: key,
                FloatableWindow(
                    key: key,
                    mode: mode
                )
            )
        
        window.contentView = NSHostingView(rootView: self)
        return window
    }
}

class FloatableWindow: NSWindow {
    let key: GlobalWindowKey
    let mode: Binding<FloatableViewMode>
    
    init(
        key: GlobalWindowKey,
        mode: Binding<FloatableViewMode>,
        contentRect: NSRect = NSRect(
            x: 0,
            y: 0,
            width: 480,
            height: 600
        ),
        styleMask style: NSWindow.StyleMask = [
            .titled,
            .fullSizeContentView,
            .resizable,
            .closable,
            .miniaturizable
        ],
        backing backingStoreType: NSWindow.BackingStoreType = .buffered,
        defer flag: Bool = false
    ) {
        self.key = key
        self.mode = mode
        super.init(
            contentRect: contentRect,
            styleMask: style,
            backing: backingStoreType,
            defer: flag
        )
        
        setFrameAutosaveName(key.title)
        title = key.title
        
        // THIS IS CRITICAL!
        // The window lifecycle is fragile here, and the window
        // can and will crash if it is immediately released on close.
        // Allow it to stick around long enough for the willClose notification
        // to come around and then clear the store then.
        isReleasedWhenClosed = false
    }
    
    override func close() {
        super.close()
        
        guard mode.wrappedValue == .displayedAsWindow else { return }
        mode.wrappedValue = .hidden
    }
    
    override func miniaturize(_ sender: Any?) {
        guard mode.wrappedValue == .displayedAsWindow else { return }
        mode.wrappedValue = .displayedAsSibling
    }
}
#endif
