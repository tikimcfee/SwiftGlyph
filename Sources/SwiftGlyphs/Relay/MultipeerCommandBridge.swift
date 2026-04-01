//
//  MultipeerCommandBridge.swift
//  SwiftGlyph
//
//  Created by Ivan Lugo on 2026-03-31.
//

import Foundation
import Combine

/// Bridges the existing `MultipeerConnectionManager` to the `CommandRouter`.
///
/// Subscribes to received messages from MultipeerConnectivity peers and
/// routes them as command strings through the `CommandRouter`. Results
/// are optionally sent back to the originating peer.
///
/// This is a thin adapter. The existing MultipeerConnectionManager handles
/// all connection lifecycle (advertising, browsing, session management).
/// This bridge only adds command routing on top.
///
/// If MultipeerConnectionManager is not available or not connected,
/// this bridge is a safe no-op.
public final class MultipeerCommandBridge {

    // MARK: - State

    private let router: CommandRouter
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init

    /// - Parameter router: The command router to dispatch received messages to.
    public init(router: CommandRouter) {
        self.router = router
    }

    // MARK: - Binding

    /// Starts observing the shared MultipeerConnectionManager for received messages.
    ///
    /// Each received message string is treated as a command and executed
    /// through the CommandRouter. Call this once at app startup.
    @MainActor
    public func bind() {
        let manager = MultipeerConnectionManager.shared

        // Observe received messages from all peers.
        // MultipeerConnectionManager publishes `receivedMessages` as a dictionary
        // of peer -> message arrays. We watch for changes and route new messages.
        manager.$receivedMessages
            .receive(on: DispatchQueue.main)
            .sink { [weak self] messages in
                self?.processMessages(messages)
            }
            .store(in: &cancellables)

        print("[MultipeerCommandBridge] Bound to MultipeerConnectionManager")
    }

    /// Stops observing multipeer messages.
    public func unbind() {
        cancellables.removeAll()
        print("[MultipeerCommandBridge] Unbound")
    }

    // MARK: - Message Processing

    /// Tracks how many messages we have processed per peer to avoid re-processing.
    private var processedCounts: [String: Int] = [:]

    private func processMessages(_ allMessages: MessageHistory) {
        let snapshot = allMessages.directCopy()
        for (peer, messages) in snapshot {
            let peerKey = peer.displayName
            let alreadyProcessed = processedCounts[peerKey] ?? 0

            guard messages.count > alreadyProcessed else { continue }

            let newMessages = messages.dropFirst(alreadyProcessed)
            processedCounts[peerKey] = messages.count

            for message in newMessages {
                let commandText = message.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                guard !commandText.isEmpty else { continue }

                Task { @MainActor [router] in
                    let result = await router.execute(commandText)
                    print("[MultipeerCommandBridge] \(peerKey) -> \(commandText) => \(result.status.rawValue)")
                }
            }
        }
    }
}
