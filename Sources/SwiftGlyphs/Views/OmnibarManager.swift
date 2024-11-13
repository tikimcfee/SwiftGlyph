//
//  OmnibarManager.swift
//  MetalLink
//
//  Created by Ivan Lugo on 11/10/24.
//


import BitHandling
import Combine
import Foundation
import MetalLink


#if os(macOS)
import AppKit

public enum OmnibarState {
    case visible
    case inactive
}

enum OmniActionTrigger: String {
    case gridJump = "j"
    case gridClose = "x"
    case gridOpen = "o"
    case search = "search"
}

public struct OmniAction: Identifiable, Hashable, Equatable {
    public let id = UUID()
    
    let trigger: OmniActionTrigger
    let sourceQuery: String
    
    let actionDisplay: String
    let perform: () -> Void
    
    public static func == (lhs: OmniAction, rhs: OmniAction) -> Bool {
        lhs.id == rhs.id
        && lhs.trigger == rhs.trigger
        && lhs.sourceQuery == rhs.sourceQuery
        && lhs.actionDisplay == rhs.actionDisplay
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(trigger)
        hasher.combine(sourceQuery)
        hasher.combine(actionDisplay)
    }
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
    
    public func dismissOmnibar() {
        DispatchQueue.main.async {
            self.state = .inactive
        }
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

extension OmnibarManager {
    func lookup(_ input: String) -> [OmniAction] {
        let components = input.components(separatedBy: .whitespaces)
        guard components.count > 1 else {
            return search(input)
        }
        
        let actionTriggerText = components[0]
        let queryText = components[1]
        
        switch actionTriggerText {
        case OmniActionTrigger.gridJump.rawValue:
            return renderedGridsMatching(queryText).map { foundGrid in
                .init(
                    trigger: .gridJump,
                    sourceQuery: queryText,
                    actionDisplay: "Jump to '\(foundGrid.fileName)'",
                    perform: { [weak self, weak foundGrid] in
                        guard let self, let foundGrid else { return }
                        self.lockZoomToBounds(of: foundGrid.rootNode)
                    }
                )
            }
            
        case OmniActionTrigger.gridClose.rawValue:
            return renderedGridsMatching(queryText).map { foundGrid in
                .init(
                    trigger: .gridJump,
                    sourceQuery: queryText,
                    actionDisplay: "Derez '\(foundGrid.fileName)'",
                    perform: { [weak foundGrid] in
                        foundGrid?.derez_global()
                    }
                )
            }
            
        case OmniActionTrigger.gridOpen.rawValue:
            return scopesMatching(queryText).map { scope in
                .init(
                    trigger: .gridJump,
                    sourceQuery: queryText,
                    actionDisplay: "Open '\(scope.path.lastPathComponent)'",
                    perform: {
                        RenderPlan(
                            mode: .cacheAndLayoutStream,
                            rootPath: scope.path,
                            editor: GlobalInstances.gridStore.editor,
                            focus: GlobalInstances.gridStore.worldFocusController
                        ).startRender { plan in
                            GlobalInstances.gridStore.editor.transformedByAdding(
                                .inNextRow(plan.rootGroup.globalRootGrid)
                            )
                            GlobalInstances.swiftGlyphRoot.root.add(
                                child: plan.targetParent
                            )
                        }
                    }
                )
            }
            
        default:
            break
        }
        
        return []
    }
    
    func scopesMatching(_ input: String) -> [FileBrowser.Scope] {
        GlobalInstances.fileBrowser.scopes.filter {
            $0.path.lastPathComponent.fuzzyMatch(input)
        }
    }
    
    func renderedGridsMatching(_ input: String) -> [CodeGrid] {
        GlobalInstances.gridStore.gridCache.cachedGrids.values.filter {
            $0.fileName.fuzzyMatch(input)
        }
    }
    
    func search(_ input: String) -> [OmniAction] {
        let min = 3
        let remaining = input.count - min
        guard remaining >= 0 else { return [
            .init(
                trigger: .search,
                sourceQuery: input,
                actionDisplay: "'\(input)' -- \(-remaining) more needed",
                perform: {
                    
                }
            )
        ] }
        
        return []
    }
    
    func lockZoomToBounds(of node: MetalLinkNode) {
        var bounds = node.worldBounds
//        bounds.min.x -= 4
//        bounds.max.x += 4
//        bounds.min.y -= 8
//        bounds.max.y += 16
        bounds.min.z -= 32
        bounds.max.z += 32
        
//        let position = bounds.center
        GlobalInstances.debugCamera.interceptor.resetPositions()
        GlobalInstances.debugCamera.position = LFloat3(bounds.leading, bounds.top, bounds.front)
        GlobalInstances.debugCamera.rotation = .zero
        GlobalInstances.debugCamera.scrollBounds = bounds
    }
}

#elseif os(iOS)
import UIKit

public enum OmnibarState {
    case visible
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


