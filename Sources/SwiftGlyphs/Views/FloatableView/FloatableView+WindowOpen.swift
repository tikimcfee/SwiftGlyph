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

public class FloatableWindow: NSWindow {
    let key: GlobalWindowKey
    let mode: Binding<FloatableViewMode>
    public static let defaultRect: NSRect = {
        let mainRect = NSScreen.main?.frame ?? .zero
        let width = 300.0
        let height = 400.0
        return NSRect(
            x: Double(mainRect.width / 2 - width / 2),
            y: Double(mainRect.height / 2 - height / 2),
            width: width,
            height: height
        )
    }()
    
    convenience init(
        key: GlobalWindowKey,
        mode: Binding<FloatableViewMode>
    ) {
        self.init(
            key: key,
            mode: mode,
            contentRect: Self.defaultRect,
            styleMask: [
                .titled,
                .fullSizeContentView,
                .resizable,
                .miniaturizable
            ],
            backing: .buffered,
            defer: false
        )
    }
    
    init(
        key: GlobalWindowKey,
        mode: Binding<FloatableViewMode>,
        contentRect: NSRect,
        styleMask style: NSWindow.StyleMask,
        backing backingStoreType: NSWindow.BackingStoreType,
        defer flag: Bool
    ) {
        self.key = key
        self.mode = mode
        
        // TODO: Omnibar is everywhere
        // Maybe do some kind of default window config for the keys instead.
        
        var updatedStyle = style
//        if key != .windowControls {
            updatedStyle.formUnion(.closable)
//        }
        
        if case .omnibar = key {
            updatedStyle.remove([
//                .titled,
                .resizable,
                .closable,
                .miniaturizable,
            ])
            updatedStyle.formUnion([
                .borderless,
                .utilityWindow,
            ])
        }
        
        super.init(
            contentRect: key == .omnibar ? OmnibarManager.defaultRect : contentRect,
            styleMask: updatedStyle,
            backing: backingStoreType,
            defer: flag
        )
        
        if case .omnibar = key {
//            title = "Quickbar"
            titlebarAppearsTransparent = true
            level = .floating
            level = .modalPanel
            becomeFirstResponder()
            
            isOpaque = false
            backgroundColor = .clear
        } else {
            setFrameAutosaveName(key.title)
            title = key.title
        }
        
        // THIS IS CRITICAL!
        // The window lifecycle is fragile here, and the window
        // can and will crash if it is immediately released on close.
        // Allow it to stick around long enough for the willClose notification
        // to come around and then clear the store then.
        isReleasedWhenClosed = false
    }
    
    public override func close() {
        super.close()
        
        guard mode.wrappedValue == .displayedAsWindow else { return }
        guard !GlobalWindowDelegate.instance.isTerminating else { return }
        mode.wrappedValue = .hidden
    }
    
    public override func miniaturize(_ sender: Any?) {
        guard mode.wrappedValue == .displayedAsWindow else { return }
        mode.wrappedValue = .displayedAsSibling
    }
}
#endif
