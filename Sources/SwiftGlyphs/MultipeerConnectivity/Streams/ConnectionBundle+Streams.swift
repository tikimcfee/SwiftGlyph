import Foundation
import MultipeerConnectivity

public enum StreamError: Error {
    case readError(error: Error?, partialData: [UInt8])
}

public struct ReceivedInputStream: Identifiable, Hashable {
    let stream: InputStream
    let target: MCPeerID
    public let id = UUID().uuidString

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(target)
    }
}

public struct PreparedOutputStream: Identifiable, Hashable {
    let stream: OutputStream
    let target: MCPeerID
    public let id = UUID().uuidString
    
    func send(_ data: Data) {
        let streamedBytes = stream.writeDataWithBoundPointer(data)
        print("Stream finished with written bytes [\(streamedBytes)]")
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(target)
    }
}

public typealias OutputStreamReceiver = (PreparedOutputStream) -> Void
public typealias InputStreamReceiver = (ReceivedInputStream) -> Void

public extension ConnectionBundle {

    func prepareInputStream(for peer: MCPeerID, _ stream: InputStream, _ receiver: @escaping InputStreamReceiver) {
        streamWorker.run {
            stream.schedule(in: .current, forMode: .default)
            receiver(
                ReceivedInputStream(stream: stream, target: peer)
            )
        }
    }

    func makeOutputStream(for peer: MCPeerID, _ receiver: @escaping OutputStreamReceiver) {
        streamWorker.run {
            guard let newOutputStream = self.createStream(for: peer) else { return }
            print("Stream created '\(newOutputStream.description)' - scheduling in \(Thread.current)")
            newOutputStream.schedule(in: .current, forMode: .default)
            receiver(
                PreparedOutputStream(stream: newOutputStream, target: peer)
            )
        }
    }

    private func createStream(for peer: MCPeerID) -> OutputStream? {
        do {
            return try globalSession.startStream(withName: "default-stream", toPeer: peer)
        } catch {
            print("Failed to create stream to \(peer)", error)
            return nil
        }
    }
}

public extension OutputStream {
    func writeDataWithBoundPointer(_ data: Data) -> Int {
        return data.withUnsafeBytes { bufferPointer in
            guard let baseAddress = bufferPointer.bindMemory(to: UInt8.self).baseAddress else {
                print("Data could not be bound \(data)")
                return 0
            }
            return write(baseAddress, maxLength: data.count)
        }
    }
}

public extension Stream {
    var whyIsItBroken: String {
        let error = streamError?.localizedDescription ?? "nil error"
        let ioInput = (self as? InputStream)?.hasBytesAvailable
        let ioOutputSpace = (self as? OutputStream)?.hasSpaceAvailable
        let ioOut = "\(String(describing: ioInput)) ; \(String(describing: ioOutputSpace))"
        return "\(streamStatus.name) :: \(error) :: \(ioOut) :: \(self.description)"
    }
}

public extension Stream.Status {
    var name: String {
        switch self {
        case .notOpen: return "notOpen"
        case .opening: return "opening"
        case .open: return "open"
        case .reading: return "reading"
        case .writing: return "writing"
        case .atEnd: return "atEnd"
        case .closed: return "closed"
        case .error: return "error"
        @unknown default: return "unknownDefault"
        }
    }
}
