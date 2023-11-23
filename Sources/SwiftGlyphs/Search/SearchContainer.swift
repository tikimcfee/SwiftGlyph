//
//  SearchContainer.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 12/5/21.
//

import Foundation

public class SearchContainer {
    public enum Mode {
        case inPlace
    }
    
    private let searchQueue = DispatchQueue(label: "GridTextSearch", qos: .userInitiated)
    private var currentRenderTask: SearchFocusRenderTask?
    
    private let gridCache: GridCache
    public var mode: Mode = .inPlace
    
    public init(gridCache: GridCache) {
        self.gridCache = gridCache
    }
        
    public func search(
        _ newInput: String,
        _ completion: @escaping (SearchFocusRenderTask) -> Void
    ) {
        currentRenderTask?.task.cancel()
        let renderTask = SearchFocusRenderTask(
            newInput: newInput,
            gridCache: gridCache,
            mode: mode,
            onComplete: completion
        )
        currentRenderTask = renderTask
        searchQueue.async(execute: renderTask.task)
    }
}
