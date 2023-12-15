//  
//
//  Created on 12/14/23.
//  

import Foundation
import LSPServiceKit
import SwiftLSP

// I just like the name 'glyph server'.
public class GlyphServer {
    public var state = State.initial
    
    public func startup(
        location: LSP.CodebaseLocation
    ) async throws {
        switch state {
        case .initial:
            let server = try await LSP.ServerManager.shared.initializeServer(for: location)
            state = .ready(server)
            
        case .ready(let server):
            print("Server already initialized, skipping for now")
            print(await server.languageIdentifier)
            
        }
    }
}

private extension GlyphServer {
    func onNotificationFromServer(_ notification: LSP.Message.Notification) {
        print("Got a notification")
        print("\(notification.method)")
        print("\(notification.params ?? .emptyObject)")
        print(notification)
    }
    
    func onConnectionShutdown(_ error: Error) {
        print("Got a shutdown error")
        print(error)
    }
    
    func onErrorOutputFromServer(_ output: String) {
        print("Got an error from the source server")
        print(output)
    }
}

public extension GlyphServer {
    enum State {
        case initial
        case ready(LSP.Server)
    }
}

public extension GlyphServer {
    enum Language {
        case Swift
        case Other(String, [String])
        
        public var name: String {
            switch self {
            case .Swift:
                return "Swift"
            case .Other(let name, _):
                return name
            }
        }
        
        public var suffixes: [String] {
            switch self {
            case .Swift:
                return ["swift"]
            case .Other(_, let suffixes):
                return suffixes
            }
        }
        
        public func location(for path: URL) -> LSP.CodebaseLocation {
            LSP.CodebaseLocation.init(
                folder: path,
                languageName: name,
                codeFileEndings: suffixes
            )
        }
    }
}
