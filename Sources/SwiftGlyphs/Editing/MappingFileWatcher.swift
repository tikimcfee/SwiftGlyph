//
//  File.swift
//
//
//  Created by Ivan Lugo on 8/18/24.
//

import Foundation

final class MappingFileWatcher<MappedResult> {
    typealias CancelBlock = () -> Void
    typealias UpdateClosure = (RefreshResult) -> Void
    typealias PathReader = (URL) throws -> MappedResult
    typealias DifferenceReader = (MappedResult, MappedResult) throws -> Bool
    
    enum WatchError: Error {
        case alreadyStarted
        case alreadyStopped
        case failedToStart(reason: String)
    }
    
    public enum RefreshResult {
        case noChanges
        case updated(MappedResult)
    }
    
    private enum State {
        struct Started {
            let source: DispatchSourceFileSystemObject
            let fileHandle: CInt
            let callback: UpdateClosure
            let cancel: CancelBlock
        }
        case started(Started)
        case stopped
    }
    
    private let path: String
    private let refreshInterval: TimeInterval
    private let queue: DispatchQueue
    private let pathReader: PathReader
    private let differenceReader: DifferenceReader
    private var state: State = .stopped
    private var isProcessing: Bool = false
    private var cancelReload: CancelBlock?
    private var previousContent: MappedResult?
    
    /** Initializes watcher to specified path.
        parameter path:     Path of file to observe.parameter refreshInterval: Refresh interval to use for updates.
        parameter queue:    Queue to use for firing onChange callback.
            note: By default it throttles to 60 FPS, some editors can generate stupid multiple saves that mess with file system e.g.
            Sublime with AutoSave plugin is a mess and generates different file sizes, this will limit wasted time trying to load faster
            than 60 FPS, and no one should even notice it's throttled.
     */
    public init(
        path: String,
        refreshInterval: TimeInterval = 1/60,
        queue: DispatchQueue = DispatchQueue.main,
        pathReader: @escaping PathReader,
        differenceReader: @escaping DifferenceReader
    ) {
        self.path = path
        self.refreshInterval = refreshInterval
        self.queue = queue
        self.pathReader = pathReader
        self.differenceReader = differenceReader
    }
    
    /* Starts observing file changes.throws: FileWatcher.Error */
    
    public func start(closure: @escaping UpdateClosure) throws {
        guard case .stopped = state else { throw WatchError.alreadyStarted }
        try startObserving(closure)
    }
    
    /* Stops observing file changes. */
    
    public func stop() throws {
        guard case let .started(model) = state else { throw WatchError.alreadyStopped }
        cancelReload?()
        cancelReload = nil
        model.cancel()
        isProcessing = false
        state = .stopped
    }
    
    deinit {
        if case .started = state {
            _ = try? stop()
        }
    }
    
    private func startObserving(_ closure: @escaping UpdateClosure) throws {
        let handle = open(path, O_EVTONLY)
        
        if handle == -1 {
            throw WatchError.failedToStart(reason: "Failed to open file")
        }
        
        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: handle,
            eventMask: [.delete, .write, .extend, .attrib, .link, .rename, .revoke],
            queue: queue
        )
        source.setEventHandler {
            self.onDispatchSourceEvent(source, closure)
        }
        source.setCancelHandler {
            close(handle)
        }
        source.resume()
        
        let cancelBlock = {
            source.cancel()
        }
        
        let started = State.Started(
            source: source,
            fileHandle: handle,
            callback: closure,
            cancel: cancelBlock
        )
        state = .started(started)
        refresh()
    }
    
    private func onDispatchSourceEvent( 
        _ source: any DispatchSourceFileSystemObject,
        _ closure: @escaping UpdateClosure
    ) {
        let flags = source.data
        if flags.contains(.delete) || flags.contains(.rename) {
            _ = try? stop()
            do {
                try startObserving(closure)
            } catch {
                queue.asyncAfter(deadline: .now() + refreshInterval) {
                    _ = try? self.startObserving(closure)
                }
            }
            return
        }
        needsToReload()
    }
    
    private func needsToReload() {
        guard case .started = state else { return }
        cancelReload?()
        cancelReload = throttle(after: refreshInterval) { self.refresh() }
    }
    
    /* Force refresh, can only be used if the watcher was started and it's not processing. */
    public func refresh() { 
        guard case let .started(model) = state, isProcessing == false else { return }
        
        isProcessing = true
        let url = URL(fileURLWithPath: path)
        do {
            let newContent = try pathReader(url)
            let hasChanged = if let previousContent {
                try differenceReader(previousContent, newContent)
            } else {
                true
            }
            previousContent = newContent
            let result: RefreshResult = hasChanged ? .updated(newContent) : .noChanges
            queue.async { model.callback(result) }
        } catch {
            print(error)
            isProcessing = false
            return
        }
        
        isProcessing = false
        cancelReload = nil
    }
    
    private func throttle(after: Double, action: @escaping () -> Void) -> CancelBlock {
        var isCancelled = false 
        DispatchQueue.main.asyncAfter(deadline: .now() + after) {
            if !isCancelled { action() }
        }
        return { isCancelled = true }
    }
    
}
