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

public class OmnibarManager: ObservableObject {
    @Published public var state = OmnibarState.inactive
    
    public lazy var eventMonitor = makeEventMonitor()
    
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
    
    public var isOmnibarVisible: Bool {
        switch state {
        case .visible: return true
        case .inactive: return false
        }
    }
}

extension OmnibarManager {
    func lookup(_ input: String) -> [OmniAction] {
        switch self.state {
        case .visible(.actions):
            return showActions(input: input)
            
        case .visible(.open):
            return showOpenList(queryText: input)
            
        case .inactive:
            return []
        }
    }
    
    func showOpenList(queryText: String) -> [OmniAction] {
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
    }
    
    func showActions(input: String) -> [OmniAction] {
        let components = input.components(separatedBy: .whitespaces)
        guard components.count > 1 else {
            return search(input)
        }
        
        let actionTriggerText = components[0]
        let queryText = components[1]
        
        switch actionTriggerText {
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
            return []
        }
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
}

extension OmnibarManager {
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


