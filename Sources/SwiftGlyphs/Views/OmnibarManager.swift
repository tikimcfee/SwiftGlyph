//
//  OmnibarManager.swift
//  MetalLink
//
//  Created by Ivan Lugo on 11/10/24.
//


import BitHandling
import Combine
import Foundation
#if os(macOS)
import AppKit

public enum OmnibarState {
    case visible
    case inactive
}

public class OmnibarManager: ObservableObject {
    public static let defaultRect: NSRect = {
        let mainRect = NSScreen.main?.frame ?? .zero
        let width = 400.0
        let height = 200.0
        return NSRect(
            x: Double(mainRect.width / 2 - width / 2),
            y: Double(mainRect.height / 2),
            width: width,
            height: height
        )
    }()
    
    @Published public var state = OmnibarState.inactive
    
    private lazy var eventMonitor = {
        { (event: NSEvent) -> NSEvent? in
            if event.keyCode == 53 {
                self.state = .inactive
                return nil
            } else {
                switch event.characters?.first {
                case .some("o") where
                    event.modifierFlags.contains(.command) &&
                    event.modifierFlags.contains(.shift):
                    self.state = .visible
                    return nil
                default:
                    return event
                }
            }
        }
    }()
    
    public init() {
        attach()
    }
    
    deinit {
        detach()
    }
    
    public func focusOmnibar() {
        GlobalWindowDelegate.instance.withWindow(.omnibar) {
            $0.makeKeyAndOrderFront(nil)
        }
    }
    
    public func attach() {
        NSEvent.addLocalMonitorForEvents(
            matching: .keyDown,
            handler: eventMonitor
        )
    }

    public func detach() {
        NSEvent.removeMonitor(eventMonitor)
    }
    
    public var isOmnibarVisible: Bool {
        switch state {
        case .visible: return true
        case .inactive: return false
        }
    }
}

#elseif os(iOS)
import UIKit

public enum OmnibarState {
    case visible(InvokeOmnibarType)
    case inactive
}

public class OmnibarManager: ObservableObject {
    @Published public var state = OmnibarState.inactive
    
    public init() {
        
    }
    
    public var isOmnibarVisible: Bool {
        switch state {
        case .visible: return true
        case .inactive: return false
        }
    }
}

#endif

