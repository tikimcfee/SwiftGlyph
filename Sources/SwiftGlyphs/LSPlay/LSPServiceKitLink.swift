//  
//
//  Created on 11/23/23.
//  

import Foundation
import LSPServiceKit
import SwiftLSP

public class SwiftGlyphLSPWrapper {
    public enum State {
        case ready
        case loaded(LSP.Server)
    }
    
    var state: State = .ready
    
    public init() {
        
    }
    
    @discardableResult
    public func quickNewServer(at url: URL) async throws -> LSP.Server {        
        // Locate the codebase
        let codebase = LSP.CodebaseLocation(folder: url,
                                            languageName: "Swift",
                                            codeFileEndings: ["swift"])

        // Create and initialize the LSP server
        let server = try await LSP.ServerManager.shared.initializeServer(for: codebase)
        self.state = .loaded(server)
        
        let folder = codebase.folder
        
        return server
    }
}

extension SwiftGlyphLSPWrapper {
    private func pocOld() throws {
        // Connect to Swift LSP websocket
        let webSocket = LSPService.api.language("Swift").websocket
        let webSocketConnection = try LSP.WebSocketConnection(webSocket: webSocket.connect())

        // Create "server" with websocket connection
        _ = LSP.Server(connection: webSocketConnection, languageName: "Swift")
    }
    
    private func initializeNewServer(at url: URL) async throws {
        let server = try LSPService.connectToLSPServer(forLanguageNamed: "Swift")

        await server.handleNotificationFromServer { notification in
            print("-==--==-")
            print(notification)
            print("-==--==-")
        }
                    
        await server.handleErrorOutputFromServer { errorOutput in
            print(errorOutput)
        }

        await server.handleConnectionShutdown { error in
            print(error)
        }
        
        // Initialize server with codebase folder
        let response = try await server.request(.initialize(folder: url))
        
        // Notify server that we are initialized
        try await server.notify(.initialized)
    }
    
}
