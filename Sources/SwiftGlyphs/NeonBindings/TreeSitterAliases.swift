//  
//
//  Created on 12/11/23.
//  

import Foundation

public typealias TreeSitterConverting = Identifiable & Hashable & Equatable

// TODO: A UUID is probably safe and not OK. Well... we'll try.
public struct SyntaxIdentifier: TreeSitterConverting {
    public let id: UUID = UUID()
}

public extension SyntaxIdentifier {
    // TODO: I may be able to be stupid if I switch to tree sitter
    // to compute the id as an instance map to UUIDs
    // ----- wow that's been here a while. how the turn circle comes full table.
    var stringIdentifier: String { "\(hashValue)" }
}

public struct Syntax: TreeSitterConverting {
    public static let TREE_SITTER_CONVERSION_EMPTY = Syntax()
    
    public let id = SyntaxIdentifier()
    public let leadingTrivia: Trivia = .TREE_SITTER_CONVERSION_EMPTY
    public let trailingTrivia: Trivia = .TREE_SITTER_CONVERSION_EMPTY
    
//    public var children: [Syntax] = []
    
    public var name: String? = nil
    public var text: String = ""
    
    public var nodeSyntaxType: SyntaxNodeType = .unknown
}
//
public struct Trivia: TreeSitterConverting {
    public static let TREE_SITTER_CONVERSION_EMPTY = Trivia(text: "")
    
    public let id = SyntaxIdentifier()
    public let text: String
    public var stringified: String { text }
}
//
public enum SyntaxNodeType: TreeSitterConverting {
    public static let UNKNOWN_DECL_ID = "heyrememebrthatblazeit"
    
    case unknown
    case variableDecl(VariableDecl)
    case extensionDecl(ExtensionDecl)
    case classDecl(ClassDecl)
    case structDecl(StructDecl)
    case functionDecl(FunctionDecl)
    case token(Token)
    case functionCallExpr(FunctionCallExpr)
    case memberAccessExpr(MemberAccessExpr)
    case protocolDecl(ProtocolDecl)
    case typeAliasDecl(TypeAliasDecl)
    case enumDecl(EnumDecl)
    
    public var id: String {
        switch self {
        case .unknown:
            return Self.UNKNOWN_DECL_ID
        case .variableDecl(let item):
            return item.id
        case .extensionDecl(let item):
            return item.id
        case .classDecl(let item):
            return item.id
        case .structDecl(let item):
            return item.id
        case .functionDecl(let item):
            return item.id
        case .token(let item):
            return item.id
        case .functionCallExpr(let item):
            return item.id
        case .memberAccessExpr(let item):
            return item.id
        case .protocolDecl(let item):
            return item.id
        case .typeAliasDecl(let item):
            return item.id
        case .enumDecl(let item):
            return item.id
        }
    }
    
    public struct VariableDecl: TreeSitterConverting {
        public let id: String = UUID().uuidString
    }

    public struct ExtensionDecl: TreeSitterConverting {
        public let id: String = UUID().uuidString
    }

    public struct ClassDecl: TreeSitterConverting {
        public let id: String = UUID().uuidString
    }

    public struct StructDecl: TreeSitterConverting {
        public let id: String = UUID().uuidString
    }

    public struct FunctionDecl: TreeSitterConverting {
        public let id: String = UUID().uuidString
    }

    public struct Token: TreeSitterConverting {
        public let id: String = UUID().uuidString
    }

    public struct FunctionCallExpr: TreeSitterConverting {
        public let id: String = UUID().uuidString
    }

    public struct MemberAccessExpr: TreeSitterConverting {
        public let id: String = UUID().uuidString
    }

    public struct ProtocolDecl: TreeSitterConverting {
        public let id: String = UUID().uuidString
    }

    public struct TypeAliasDecl: TreeSitterConverting {
        public let id: String = UUID().uuidString
    }

    public struct EnumDecl: TreeSitterConverting {
        public let id: String = UUID().uuidString
    }
}
//
//public struct TokenSyntax: TreeSitterConverting {
//    var tokenKind: TokenKind
//}
