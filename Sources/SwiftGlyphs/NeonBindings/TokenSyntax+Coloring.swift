//
//  TokenSyntax+Coloring.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 5/9/22.
//

import Foundation
import MetalLink

public enum TokenKind {
    case arrow
    case atSign
    case backslash
    case backtick
    case colon
    case comma
    case ellipsis
    case endOfFile
    case equal
    case exclamationMark
    case infixQuestionMark
    case leftAngle
    case leftBrace
    case leftParen
    case leftSquare
    case multilineStringQuote
    case period
    case postfixQuestionMark
    case pound
    case poundAvailable
    case poundElse
    case poundElseif
    case poundEndif
    case poundIf
    case poundSourceLocation
    case poundUnavailable
    case prefixAmpersand
    case regexSlash
    case rightAngle
    case rightBrace
    case rightParen
    case rightSquare
    case semicolon
    case singleQuote
    case stringQuote
    case wildcard
    case binaryOperator
    case dollarIdentifier
    case floatLiteral
    case identifier
    case integerLiteral
    case keyword
    case postfixOperator
    case prefixOperator
    case rawStringPoundDelimiter
    case regexLiteralPattern
    case regexPoundDelimiter
    case shebang
    case stringSegment
    case unknown
}

public class SyntaxColoring {
    public var variableDeclaration     = NSUIColor(displayP3Red: 1.0, green: 0.5, blue: 0.5, alpha: 1.0)
    public var extensionDeclaration    = NSUIColor(displayP3Red: 0.4, green: 0.6, blue: 0.6, alpha: 1.0)
    public var classDeclaration        = NSUIColor(displayP3Red: 0.5, green: 0.5, blue: 0.7, alpha: 1.0)
    public var structDeclaration       = NSUIColor(displayP3Red: 0.8, green: 0.2, blue: 0.2, alpha: 1.0)
    public var functionDeclaration     = NSUIColor(displayP3Red: 0.123, green: 0.34, blue: 0.45, alpha: 1.0)
    public var token                   = NSUIColor(displayP3Red: 1.0, green: 1.0, blue: 0.0, alpha: 1.0)
    public var functionCallExpression  = NSUIColor(displayP3Red: 0.4, green: 0.4, blue: 0.9, alpha: 1.0)
    public var memeberAccessExpression = NSUIColor(displayP3Red: 0.8, green: 0.7, blue: 0.9, alpha: 1.0)
    public var protocolDeclaration     = NSUIColor(displayP3Red: 1.0, green: 0.8, blue: 0.9, alpha: 1.0)
    public var typeAliasDeclaration    = NSUIColor(displayP3Red: 1.0, green: 0.6, blue: 0.8, alpha: 1.0)
    public var enumDeclaration         = NSUIColor(displayP3Red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
    
    public var unknownToken = NSUIColor(displayP3Red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)
    
    func defaultColor(for node: SyntaxNodeType) -> NSUIColor {
        switch node {
        case .unknown(_):           return unknownToken
        case .variableDecl(_):      return variableDeclaration
        case .extensionDecl(_):     return extensionDeclaration
        case .classDecl(_):         return classDeclaration
        case .structDecl(_):        return structDeclaration
        case .functionDecl(_):      return functionDeclaration
        case .token(_):             return token
        case .functionCallExpr(_):  return functionCallExpression
        case .memberAccessExpr(_):  return memeberAccessExpression
        case .protocolDecl(_):      return protocolDeclaration
        case .typeAliasDecl(_):     return typeAliasDeclaration
        case .enumDecl(_):          return enumDeclaration
        }
    }
}
