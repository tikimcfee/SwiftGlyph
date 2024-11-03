//
//  LaZTrace.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 12/6/21.
//

import Foundation
import BitHandling

let traceBox = LaZTraceBox()

@inline(__always)
func laztrace(
    _ fileID: String,
    _ function: String,
    _ args: Any?...
) {
//    traceBox.laztrace(fileID, function, args)
}

func lazdump() {
    for call in traceBox.recordedCalls {
        print(call)
    }
}

class LaZTraceBox {
    struct Call: Equatable, CustomStringConvertible {
        let fileID: String
        let function: String
        let args: [Any?]
        var calls: Int = 1
        let queueName: String
        
        static func == (_ left: Call, _ right: Call) -> Bool {
            return left.fileID == right.fileID
                && left.function == right.function
                && left.queueName == right.queueName
        }
        
        mutating func increment() -> Call {
            self.calls += 1
            return self
        }
        
        var description: String {
            return "\(fileID).\(function).[\(calls)]~\(queueName)"
        }
    }
    
    let queue = DispatchQueue(label: "LaZTracing", qos: .background)
    var recordedCalls = [Call]()
    
    func laztrace(
        _ fileID: String,
        _ function: String,
        _ args: Any?...
    ) {
        let call = Call(
            fileID: fileID,
            function: function,
            args: args,
            queueName: currentQueueName()
        )
        queue.async {
            self.appendOrIncrement(call)
        }
    }
    
    private func appendOrIncrement(_ call: Call) {
        switch recordedCalls.last {
        case var .some(lastCall) where lastCall == call:
            recordedCalls[recordedCalls.endIndex - 1] = lastCall.increment()
        default:
            recordedCalls.append(call)
        }
    }
}

class TracingFileFinder {
    private let toSkip = [
        ".git",
        ".xcodeproj",
        ".xcassets",
        "Libraries",
        "AppKitTests",
    ]
    
    func findFiles(_ root: String) -> [URL] {
        URL(fileURLWithPath: root)
            .children(recursive: true)
            .filter(fileMatches)
    }
    
    private func fileMatches(_ path: URL) -> Bool {
        return path.pathExtension == "swift"
            && toSkip.allSatisfy { !path.absoluteString.contains($0) }
    }
}
