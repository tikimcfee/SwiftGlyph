//
//  GlobalWindowDelegate.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 5/14/22.
//

import SwiftUI
import BitHandling

#if os(iOS)
public class GlobalWindowDelegate: NSObject {
    static let instance = GlobalWindowDelegate()
}
#endif


#if os(macOS)
// TODO: just use the WindowGroup API..
public typealias WindowType = FloatableWindow

public class GlobalWindowDelegate: NSObject, NSWindowDelegate {
    public static let instance = GlobalWindowDelegate()
    public var isTerminating = false
    
    public private(set) var knownWindowMap = BiMap<GlobalWindowKey, WindowType>()
    public private(set) var rootWindow: NSWindow?
    
    override private init() {
        super.init()
    }
    
    public func registerRootWindow(_ window: NSWindow) {
        self.rootWindow = window
    }
    
    public func windowIsDisplayed(for key: GlobalWindowKey) -> Bool {
        knownWindowMap[key]?.isVisible == true
    }
    
    public func window(
        for key: GlobalWindowKey,
        _ makeWindow: @autoclosure () -> FloatableWindow) -> FloatableWindow {
        knownWindowMap[key] ?? {
            let newWindow = makeWindow()
            register(key, newWindow)
            return newWindow
        }()
    }
    
    public func dismissWindow(for key: GlobalWindowKey) {
        knownWindowMap[key]?.close()
//        knownWindowMap[key]?.performClose("manual-dismiss")
    }
    
    private func register(_ key: GlobalWindowKey, _ window: FloatableWindow) {
        knownWindowMap[key] = window
        window.orderFrontRegardless()
        window.delegate = self
    }
    
    public func windowWillClose(_ notification: Notification) {
        guard let window = notification.object as? FloatableWindow else {
            print("Missing window on close!", notification)
            return
        }
        print("Window closing:", knownWindowMap[window]?.rawValue ?? "<No known key!>", "->", window.title)
        knownWindowMap[window] = nil
    }
    
    public func setupScreens() {
        print("Available screens:")
        NSScreen.screens.forEach { screen in
            print(screen)
            print("-> name  ", screen.localizedName)
            print("-> frame ", screen.frame)
            print("->vframe ", screen.visibleFrame)
            print("-> safe  ", screen.safeAreaInsets)
            screen.deviceDescription.forEach {
                print("-> \($0.key)", $0.value)
            }
        }
    }
}
#endif
