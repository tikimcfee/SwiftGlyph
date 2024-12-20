import Foundation

func fileData(_ name: String, _ type: String = "") -> Data {
    return fileHandle(name, type)?.availableData ?? Data()
}

func fileHandle(_ name: String, _ type: String = "") -> FileHandle? {
    guard let filepath = Bundle.main.path(
        forResource: name, ofType: type
    ) else { return nil }

    return FileHandle(forReadingAtPath: filepath)
}

extension Array {
    func slices(sliceSize: Int) -> [ArraySlice<Element>] {
        return (0...(count / sliceSize)).reduce(into: [ArraySlice<Element>]()) { result, slicePosition in
            let sliceStart = slicePosition * sliceSize
            let sliceEnd = Swift.min(sliceStart + sliceSize, count)
            result.append(self[sliceStart..<sliceEnd])
        }
    }
}

public class QuickLooper {
    public let loop: (DispatchTime) -> Void
    public let queue: DispatchQueue
    
    public var interval: DispatchTimeInterval
    public var nextDispatch: DispatchTime { .now() + interval }
    
    public init(
        interval: DispatchTimeInterval = .seconds(1),
        queue: DispatchQueue = .main,
        loop: @escaping (DispatchTime) -> Void
    ) {
        self.interval = interval
        self.loop = loop
        self.queue = queue
    }
    
    public init(
        interval: DispatchTimeInterval = .seconds(1),
        queue: DispatchQueue = .main,
        loop: @escaping () -> Void
    ) {
        self.interval = interval
        self.loop = { _ in loop() }
        self.queue = queue
    }
    
    public func runUntil(
        onStop: (() -> Void)? = nil,
        stopIf: @escaping () -> Bool
    ) {
        guard !stopIf() else {
            onStop?()
            return
        }
        let next = nextDispatch
        loop(next)
        queue.asyncAfter(deadline: next) {
            self.runUntil(onStop: onStop, stopIf: stopIf)
        }
    }
}

func currentQueueName() -> String { queueName }

private var queueName: String {
    if let queueName = String(validatingUTF8: __dispatch_queue_get_label(nil)) {
        return queueName
    } else if let operationQueueName = OperationQueue.current?.name, !operationQueueName.isEmpty {
        return operationQueueName
    } else if let dispatchQueueName = OperationQueue.current?.underlyingQueue?.label, !dispatchQueueName.isEmpty {
        return dispatchQueueName
    } else {
        return "n/a"
    }
}

extension URL {
    var hasData: Bool {
        let attributes = try? FileManager.default.attributesOfItem(atPath: path) as NSDictionary
        let size = attributes?.fileSize() ?? 0
        return size > 0
    }
}
