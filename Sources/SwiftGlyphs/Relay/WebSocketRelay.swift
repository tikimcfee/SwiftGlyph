//
//  WebSocketRelay.swift
//  SwiftGlyph
//
//  Created by Ivan Lugo on 2026-03-31.
//

import Foundation
import Network

/// WebSocket relay that bridges external clients to the CommandRouter.
///
/// Listens on a configurable TCP port using Network framework's built-in
/// WebSocket support (`NWProtocolWebSocket`). Each connection:
///   1. Receives text messages as command strings
///   2. Hops to `@MainActor` to call `CommandRouter.execute`
///   3. Sends back the `CommandResult` serialized as JSON
///
/// Additionally, connected clients can subscribe to the router's
/// `eventStream` to receive all command events as they happen.
///
/// This class is NOT `@MainActor` -- network I/O runs on NWListener's
/// background queue. Only the `router.execute()` call hops to main.
public final class WebSocketRelay: @unchecked Sendable {

    // MARK: - Configuration

    public struct Configuration: Sendable {
        public var port: UInt16
        public var maxConnections: Int

        public init(port: UInt16 = 8765, maxConnections: Int = 8) {
            self.port = port
            self.maxConnections = maxConnections
        }
    }

    // MARK: - State

    private let configuration: Configuration
    private let router: CommandRouter
    private var listener: NWListener?
    private let queue = DispatchQueue(label: "WebSocketRelay", qos: .userInitiated)

    /// Active connections. Access only from `queue`.
    private var connections: [ObjectIdentifier: NWConnection] = [:]

    /// Event stream forwarding task. Cancelled on stop.
    private var eventForwardingTask: Task<Void, Never>?

    private let jsonEncoder = JSONEncoder()

    // MARK: - Init

    /// - Parameters:
    ///   - router: The command router to dispatch received commands to.
    ///   - configuration: Port and connection limit settings.
    public init(router: CommandRouter, configuration: Configuration = .init()) {
        self.router = router
        self.configuration = configuration
        jsonEncoder.outputFormatting = [.sortedKeys]
    }

    // MARK: - Lifecycle

    /// Starts the WebSocket listener on the configured port.
    ///
    /// Safe to call multiple times; subsequent calls are no-ops if
    /// the listener is already active.
    public func start() throws {
        guard listener == nil else { return }

        let parameters = NWParameters.tcp
        let wsOptions = NWProtocolWebSocket.Options()
        parameters.defaultProtocolStack.applicationProtocols.insert(wsOptions, at: 0)

        let port = NWEndpoint.Port(rawValue: configuration.port)!
        let newListener = try NWListener(using: parameters, on: port)

        newListener.stateUpdateHandler = { [weak self] state in
            self?.handleListenerState(state)
        }

        newListener.newConnectionHandler = { [weak self] connection in
            self?.handleNewConnection(connection)
        }

        newListener.start(queue: queue)
        listener = newListener

        startEventForwarding()
        print("[WebSocketRelay] Listening on port \(configuration.port)")
    }

    /// Stops the listener and disconnects all clients.
    public func stop() {
        eventForwardingTask?.cancel()
        eventForwardingTask = nil

        queue.sync {
            for (_, connection) in connections {
                connection.cancel()
            }
            connections.removeAll()
        }

        listener?.cancel()
        listener = nil
        print("[WebSocketRelay] Stopped")
    }

    // MARK: - Listener State

    private func handleListenerState(_ state: NWListener.State) {
        switch state {
        case .ready:
            print("[WebSocketRelay] Ready")
        case .failed(let error):
            print("[WebSocketRelay] Listener failed: \(error)")
            listener?.cancel()
            listener = nil
        case .cancelled:
            print("[WebSocketRelay] Listener cancelled")
        default:
            break
        }
    }

    // MARK: - Connection Handling

    private func handleNewConnection(_ connection: NWConnection) {
        let id = ObjectIdentifier(connection)

        if connections.count >= configuration.maxConnections {
            print("[WebSocketRelay] Rejecting connection, at capacity (\(configuration.maxConnections))")
            connection.cancel()
            return
        }

        connections[id] = connection

        connection.stateUpdateHandler = { [weak self] state in
            self?.handleConnectionState(id: id, state: state)
        }

        connection.start(queue: queue)
        receiveMessage(on: connection, id: id)
        print("[WebSocketRelay] Client connected (\(connections.count) active)")
    }

    private func handleConnectionState(id: ObjectIdentifier, state: NWConnection.State) {
        switch state {
        case .ready:
            break
        case .failed(let error):
            print("[WebSocketRelay] Connection failed: \(error)")
            removeConnection(id: id)
        case .cancelled:
            removeConnection(id: id)
        default:
            break
        }
    }

    private func removeConnection(id: ObjectIdentifier) {
        connections.removeValue(forKey: id)
        print("[WebSocketRelay] Client disconnected (\(connections.count) active)")
    }

    // MARK: - Message Receive Loop

    private func receiveMessage(on connection: NWConnection, id: ObjectIdentifier) {
        connection.receiveMessage { [weak self] content, context, isComplete, error in
            guard let self else { return }

            if let error {
                print("[WebSocketRelay] Receive error: \(error)")
                self.removeConnection(id: id)
                return
            }

            if let data = content, let text = String(data: data, encoding: .utf8) {
                self.handleReceivedText(text, connection: connection, id: id)
            }

            // Continue receiving
            self.receiveMessage(on: connection, id: id)
        }
    }

    private func handleReceivedText(_ text: String, connection: NWConnection, id: ObjectIdentifier) {
        Task { @MainActor in
            let result = await self.router.execute(text)
            self.sendResult(result, on: connection)
        }
    }

    // MARK: - Message Send

    private func sendResult(_ result: CommandResult, on connection: NWConnection) {
        do {
            let data = try jsonEncoder.encode(result)
            let metadata = NWProtocolWebSocket.Metadata(opcode: .text)
            let context = NWConnection.ContentContext(
                identifier: "commandResult",
                metadata: [metadata]
            )
            connection.send(
                content: data,
                contentContext: context,
                isComplete: true,
                completion: .contentProcessed { error in
                    if let error {
                        print("[WebSocketRelay] Send error: \(error)")
                    }
                }
            )
        } catch {
            print("[WebSocketRelay] Failed to encode result: \(error)")
        }
    }

    // MARK: - Event Stream Forwarding

    /// Forwards all CommandRouter events to all connected WebSocket clients.
    private func startEventForwarding() {
        eventForwardingTask = Task { [weak self] in
            guard let self else { return }

            // We need to access the event stream on MainActor since router is MainActor-isolated.
            let stream = await MainActor.run { self.router.eventStream }

            for await event in stream {
                guard !Task.isCancelled else { break }

                // Encode the event result and broadcast
                do {
                    let eventPayload = EventEnvelope(
                        command: event.command,
                        args: event.args,
                        result: event.result,
                        timestamp: event.timestamp.timeIntervalSince1970
                    )
                    let data = try self.jsonEncoder.encode(eventPayload)

                    self.queue.async {
                        for (_, connection) in self.connections {
                            let metadata = NWProtocolWebSocket.Metadata(opcode: .text)
                            let context = NWConnection.ContentContext(
                                identifier: "event",
                                metadata: [metadata]
                            )
                            connection.send(
                                content: data,
                                contentContext: context,
                                isComplete: true,
                                completion: .contentProcessed { _ in }
                            )
                        }
                    }
                } catch {
                    print("[WebSocketRelay] Failed to encode event: \(error)")
                }
            }
        }
    }
}

// MARK: - Event Envelope

/// JSON-serializable wrapper for events broadcast to WebSocket clients.
private struct EventEnvelope: Codable {
    let type: String = "event"
    let command: String
    let args: [String]
    let result: CommandResult
    let timestamp: Double
}
