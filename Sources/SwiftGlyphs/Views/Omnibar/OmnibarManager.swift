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
import SwiftUI

public class OmnibarManager: ObservableObject {
    let stateSubject = CurrentValueSubject<OmnibarState, Never>(.inactive)
    
    public lazy var eventMonitor = makeEventMonitor()
    
    public init() {
        attach()
    }
    
    deinit {
        detach()
    }
    
    public func dismissOmnibar() {
        DispatchQueue.main.async {
            self.stateSubject.send(.inactive)
        }
    }
    
    public func focusOmnibar() {
        GlobalWindowDelegate.instance.withWindow(.omnibar) {
            $0.makeKeyAndOrderFront(nil)
        }
    }
}

extension OmnibarManager {
    func lookup(_ input: String) -> [OmniAction] {
//        GlobalInstances
//            .searchState
//            .startSearch(for: input, caseInsensitive: true)
        
        return allActions(queryText: input)
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
                        
                        plan.rootGroup
                            .globalRootGrid
                            .displayFocused(GlobalInstances.debugCamera)
                    }
                }
            )
        }
    }
    
    func allActions(queryText: String) -> [OmniAction] {
        let gridActions = renderedGridsMatching(queryText).flatMap { foundGrid in
            [
                OmniAction(
                    trigger: .gridJump,
                    sourceQuery: queryText,
                    actionDisplay: "Jump to '\(foundGrid.fileName)'",
                    perform: {
                        foundGrid.displayFocused(GlobalInstances.debugCamera)
                    }
                ),
                OmniAction(
                    trigger: .gridClose,
                    sourceQuery: queryText,
                    actionDisplay: "Derez '\(foundGrid.fileName)'",
                    perform: { [weak foundGrid] in
                        foundGrid?.derez_global()
                    }
                )
            ]
        }
        
        let scopeActions = scopesMatching(queryText).map { scope in
            OmniAction(
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
                        
                        plan.rootGroup
                            .globalRootGrid
                            .displayFocused(GlobalInstances.debugCamera)
                    }
                }
            )
        }
        
        return gridActions
            + scopeActions
    }
    
    func scopesMatching(_ input: String) -> [FileBrowser.Scope] {
        GlobalInstances.fileBrowser.scopes.filter {
            $0.path.lastPathComponent.fuzzyMatch(input)
        }
    }
    
    func renderedGridsMatching(_ input: String) -> [CodeGrid] {
        GlobalInstances.gridStore.gridCache.cachedGrids.values.filter {
            print($0.fileName, "fuzzy match (\(input))->", $0.fileName.fuzzyMatch(input))
            return $0.fileName.fuzzyMatch(input)
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


