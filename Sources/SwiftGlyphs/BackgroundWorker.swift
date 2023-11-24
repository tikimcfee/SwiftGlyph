import Foundation

public typealias BackgroundClosure = () -> Void

open class BackgroundWorker: NSObject {
    private var started = false

    private lazy var workerThread: Thread = {
        let newThread = Thread { [weak self] in self?.monitorThread() }
        newThread.name = "BackgroundWorker"
        return newThread
    }()

    public func start() {
        guard !started else { return }
        started.toggle()
        workerThread.start()
    }

    public func stop() {
        workerThread.cancel()
    }

    public func run(_ block: @escaping BackgroundClosure) {
        start()

        perform(#selector(execute),
          on: workerThread,
          with: block,
          waitUntilDone: false,
          modes: [RunLoop.Mode.default.rawValue])
    }

    // Signature *must me* of the form `(_ closure: Any!) -> Unmanaged<AnyObject>!`,
    // such that perform(selector:) delivers the current untyped object to cast
    @objc private func execute(_ closure: Any!) -> Unmanaged<AnyObject>! {
        if let closure = closure as? BackgroundClosure {
            closure()
        }
        return nil
    }

    public func monitorThread() {
        while !workerThread.isCancelled {
            RunLoop.current.run(
                mode: RunLoop.Mode.default,
                before: Date.distantFuture
            )
        }
        Thread.exit()
    }
}

