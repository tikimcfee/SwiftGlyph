//
//  OmnibarManager+EventMonitor.swift
//  SwiftGlyph
//
//  Created by Ivan Lugo on 11/13/24.
//

#if os(macOS)

import BitHandling
import Combine
import Foundation
import MetalLink
import AppKit

extension OmnibarManager {
    public func attach() {
        NSEvent.addLocalMonitorForEvents(
            matching: .keyDown,
            handler: eventMonitor
        )
    }

    public func detach() {
        NSEvent.removeMonitor(eventMonitor)
    }
    
    func makeEventMonitor() -> (NSEvent) -> NSEvent? {
        { [weak self] in
            self?.onEvent($0)
        }
    }
    
    private func onEvent(_ event: NSEvent) -> NSEvent? {
        if event.keyCode == 53 {
            stateSubject.send(.inactive)
            return nil
        }
            
        switch event.characters?.first {
        case .some("o") where
            event.modifierFlags.contains(.command) &&
            event.modifierFlags.contains(.shift):
            stateSubject.send(.visible(.open))
            return nil
        case .some("a") where
            event.modifierFlags.contains(.command) &&
            event.modifierFlags.contains(.shift):
            stateSubject.send(.visible(.actions))
            return nil
        default:
            return event
        }
    }
}

#endif
