////
////  TokenSyntax+Coloring.swift
////  LookAtThat_AppKit
////
////  Created by Ivan Lugo on 5/9/22.
////
//
//import Foundation
//import MetalLink
//
//public enum TokenKind {
//    case arrow
//    case atSign
//    case backslash
//    case backtick
//    case colon
//    case comma
//    case ellipsis
//    case endOfFile
//    case equal
//    case exclamationMark
//    case infixQuestionMark
//    case leftAngle
//    case leftBrace
//    case leftParen
//    case leftSquare
//    case multilineStringQuote
//    case period
//    case postfixQuestionMark
//    case pound
//    case poundAvailable
//    case poundElse
//    case poundElseif
//    case poundEndif
//    case poundIf
//    case poundSourceLocation
//    case poundUnavailable
//    case prefixAmpersand
//    case regexSlash
//    case rightAngle
//    case rightBrace
//    case rightParen
//    case rightSquare
//    case semicolon
//    case singleQuote
//    case stringQuote
//    case wildcard
//    case binaryOperator
//    case dollarIdentifier
//    case floatLiteral
//    case identifier
//    case integerLiteral
//    case keyword
//    case postfixOperator
//    case prefixOperator
//    case rawStringPoundDelimiter
//    case regexLiteralPattern
//    case regexPoundDelimiter
//    case shebang
//    case stringSegment
//    case unknown
//}
//
//public extension TokenSyntax {
//    static let languageKeywords = NSUIColor(displayP3Red: 0.8, green: 0.2, blue: 0.2, alpha: 1.0)
//    static let controlFlowKeyword = NSUIColor(displayP3Red: 0.4, green: 0.6, blue: 0.6, alpha: 1.0)
//    static let enumSwitchKeyword = NSUIColor(displayP3Red: 0.5, green: 0.5, blue: 0.7, alpha: 1.0)
//    static let selfKeyword = NSUIColor(displayP3Red: 1.0, green: 0.6, blue: 0.8, alpha: 1.0)
//    static let selfClassKeyword = NSUIColor(displayP3Red: 1.0, green: 0.8, blue: 0.9, alpha: 1.0)
//    static let standardScopeColor = NSUIColor(displayP3Red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
//    static let actionableTokenColor = NSUIColor(displayP3Red: 1.0, green: 0.5, blue: 0.5, alpha: 1.0)
//    static let rawRegexString = NSUIColor(displayP3Red: 0.4, green: 0.4, blue: 0.9, alpha: 1.0)
//    static let rawRegexStringSlash = NSUIColor(displayP3Red: 0.8, green: 0.7, blue: 0.9, alpha: 1.0)
//    static let stringLiteral = NSUIColor(displayP3Red: 0.8, green: 0.3, blue: 0.2, alpha: 1.0)
//    static let numericLiteral = NSUIColor(displayP3Red: 0.123, green: 0.34, blue: 0.45, alpha: 1.0)
//    static let valueToken = NSUIColor(displayP3Red: 0.5, green: 0.5, blue: 0.0, alpha: 1.0)
//    static let operatorToken = NSUIColor(displayP3Red: 1.0, green: 1.0, blue: 0.0, alpha: 1.0)
//    static let wildcard = NSUIColor(displayP3Red: 0.3, green: 0.4, blue: 0.1234007, alpha: 1.0)
//    static let unknownToken = NSUIColor(displayP3Red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)
//    
//    var defaultColor: NSUIColor {
//        switch tokenKind {
//        
//        case .endOfFile:
//            return NSUIColor(displayP3Red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
//        case .keyword:
//            return Self.languageKeywords
//        case .leftParen:
//            return Self.controlFlowKeyword
//        case .rightParen:
//            return Self.controlFlowKeyword
//        case .leftBrace:
//            return Self.standardScopeColor
//        case .rightBrace:
//            return Self.standardScopeColor
//        case .leftSquare:
//            return Self.standardScopeColor
//        case .rightSquare:
//            return Self.standardScopeColor
//        case .leftAngle:
//            return Self.standardScopeColor
//        case .rightAngle:
//            return Self.standardScopeColor
//        case .period:
//            return Self.standardScopeColor
//        case .prefixOperator:
//            return Self.standardScopeColor
//        case .comma:
//            return Self.standardScopeColor
//        case .ellipsis:
//            return Self.standardScopeColor
//        case .colon:
//            return Self.standardScopeColor
//        case .semicolon:
//            return Self.standardScopeColor
//        case .equal:
//            return Self.standardScopeColor
//        case .atSign:
//            return Self.actionableTokenColor
//        case .pound:
//            return Self.actionableTokenColor
//        case .prefixAmpersand:
//            return Self.actionableTokenColor
//        case .arrow:
//            return Self.standardScopeColor
//        case .backtick:
//            return Self.standardScopeColor
//        case .backslash:
//            return Self.standardScopeColor
//        case .exclamationMark:
//            return Self.actionableTokenColor
//        case .postfixQuestionMark:
//            return Self.actionableTokenColor
//        case .infixQuestionMark:
//            return Self.actionableTokenColor
//        case .stringQuote:
//            return Self.standardScopeColor
//        case .singleQuote:
//            return Self.standardScopeColor
//        case .multilineStringQuote:
//            return Self.standardScopeColor
//        case .poundSourceLocation:
//            return Self.actionableTokenColor
//        case .poundIf:
//            return Self.actionableTokenColor
//        case .poundElse:
//            return Self.actionableTokenColor
//        case .poundElseif:
//            return Self.actionableTokenColor
//        case .poundEndif:
//            return Self.actionableTokenColor
//        case .poundAvailable:
//            return Self.actionableTokenColor
//        case .integerLiteral:
//            return Self.valueToken
//        case .unknown:
//            return Self.unknownToken
//        case .identifier:
//            return Self.valueToken
//        case .postfixOperator:
//            return Self.standardScopeColor
//        case .dollarIdentifier:
//            return Self.actionableTokenColor
//        case .stringSegment:
//            return Self.valueToken
//        case .regexLiteralPattern:
//            return Self.rawRegexString
//        case .binaryOperator:
//            return Self.operatorToken
//        case .poundUnavailable:
//            return Self.languageKeywords
//        case .regexSlash:
//            return Self.rawRegexStringSlash
//        case .wildcard:
//            return Self.wildcard
//        case .floatLiteral:
//            return Self.numericLiteral
//        case .rawStringPoundDelimiter:
//            return Self.languageKeywords
//        case .regexPoundDelimiter:
//            return Self.languageKeywords
//        case .shebang:
//            return Self.languageKeywords
//        }
//    }
//}
