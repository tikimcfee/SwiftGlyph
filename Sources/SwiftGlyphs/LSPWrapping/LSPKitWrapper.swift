//  
//
//  Created on 12/14/23.
//  

import Foundation

// I just like the name 'glyph server'.
public class GlyphServer {
    public var state = State.initial
    
    public func startup(
        location: URL
    ) async throws {
//        switch state {
//        case .initial:
//            let server = try await LSP.ServerManager.shared.initializeServer(for: location)
//            state = .ready(server)
//            
//        case .ready(let server):
//            print("Server already initialized, skipping for now")
//            print(await server.languageIdentifier)
//            
//        }
    }
}

private extension GlyphServer {
}

public extension GlyphServer {
    enum State {
        case initial
        case ready
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
        
        public func location(for path: URL) -> URL {
            return path
//            LSP.CodebaseLocation.init(
//                folder: path,
//                languageName: name,
//                codeFileEndings: suffixes
//            )
        }
    }
}
