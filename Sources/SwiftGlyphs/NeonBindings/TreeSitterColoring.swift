//  
//
//  Created on 12/17/23.
//  

import Foundation
import BitHandling
import MetalLink

extension SyntaxType {
    var foregroundColor: SerialColor {
        switch self {
        case .someRepeat:
            return GlobalLiveConfig.Default.coloring.unknownToken
            
        case .someLabel:
            return GlobalLiveConfig.Default.coloring.rawString
            
        case .rawString:
            return GlobalLiveConfig.Default.coloring.rawString
            
        case .rawBoolean:
            return GlobalLiveConfig.Default.coloring.rawBool
            
        case .comment:
            return GlobalLiveConfig.Default.coloring.comment
            
        case .conditional(let type):
            switch type {
            case .anyConditional:
                return GlobalLiveConfig.Default.coloring.conditionalGuard
            case .ifConditional:
                return GlobalLiveConfig.Default.coloring.conditionalGuard
            case .guardConditional:
                return GlobalLiveConfig.Default.coloring.conditionalGuard
            }
            
        case .constructor(let type):
            switch type {
            case .initConstructor:
                return GlobalLiveConfig.Default.coloring.initConstructor
            }
            
        case .definition(let type):
            switch type {
            case .classDefinition:
                return GlobalLiveConfig.Default.coloring.classDeclaration
            case .function:
                return GlobalLiveConfig.Default.coloring.functionDeclaration
            case .importDefinition:
                return GlobalLiveConfig.Default.coloring.token
            case .method:
                return GlobalLiveConfig.Default.coloring.classDeclaration
            case .property:
                return GlobalLiveConfig.Default.coloring.classDeclaration
            }
            
        case .float(let type):
            switch type {
            case .real_literal:
                return GlobalLiveConfig.Default.coloring.token
            }
            
        case .function(let type):
            switch type {
            case .call:
                return GlobalLiveConfig.Default.coloring.functionCallExpression
            case .macro:
                return GlobalLiveConfig.Default.coloring.token
            }
            
        case .include(let type):
            switch type {
            case .importInclude:
                return GlobalLiveConfig.Default.coloring.token
            }
            
        case .keyword(let type):
            switch type {
            case .anyKeyword:
                return GlobalLiveConfig.Default.coloring.token
            case .classKeyword:
                return GlobalLiveConfig.Default.coloring.classDeclaration
            case .elseKeyword:
                return GlobalLiveConfig.Default.coloring.token
            case .extensionKeyword:
                return GlobalLiveConfig.Default.coloring.extensionDeclaration
            case .function(let funcType):
                switch funcType {
                case .funcType:
                    return GlobalLiveConfig.Default.coloring.functionDeclaration
                }
            case .letKeyword:
                return GlobalLiveConfig.Default.coloring.token
            case .throw_keyword:
                return GlobalLiveConfig.Default.coloring.token
            case .throwsKeyword:
                return GlobalLiveConfig.Default.coloring.token
            case .varKeyword:
                return GlobalLiveConfig.Default.coloring.variableDeclaration
            case .visibility_modifier:
                return GlobalLiveConfig.Default.coloring.token
            case .returnKeyword:
                return GlobalLiveConfig.Default.coloring.returnToken
            case .operatorKeyword:
                return GlobalLiveConfig.Default.coloring.variableDeclaration
            }
            
        case .local(let type):
            switch type {
            case .scope(let scopeType):
                switch scopeType {
                case .class_declaration:
                    return GlobalLiveConfig.Default.coloring.classDeclaration
                case .function_declaration:
                    return GlobalLiveConfig.Default.coloring.functionDeclaration
                case .guard_statement:
                    return GlobalLiveConfig.Default.coloring.conditionalGuard
                case .property_declaration:
                    return GlobalLiveConfig.Default.coloring.classDeclaration
                case .statements:
                    return GlobalLiveConfig.Default.coloring.token
                }
            }
            
        case .method(let type):
            switch type {
            case .simple_identifier:
                return GlobalLiveConfig.Default.coloring.memeberAccessExpression
            }
            
        case .name(let type):
            switch type {
            case .initName:
                return GlobalLiveConfig.Default.coloring.initConstructor
            case .simple_identifier:
                return GlobalLiveConfig.Default.coloring.token
            case .type_identifier:
                return GlobalLiveConfig.Default.coloring.token
            }
            
        case .number(let type):
            switch type {
            case .float:
                return GlobalLiveConfig.Default.coloring.rawNumber
            case .anyLiteral:
                return GlobalLiveConfig.Default.coloring.rawNumber
            case .integer_literal:
                return GlobalLiveConfig.Default.coloring.token
            }
            
        case .operatorType(let type):
            switch type {
            case .anyOperator:
                return GlobalLiveConfig.Default.coloring.token
            case .lessThan:
                return GlobalLiveConfig.Default.coloring.token
            case .equal:
                return GlobalLiveConfig.Default.coloring.token
            case .greaterThan:
                return GlobalLiveConfig.Default.coloring.token
            case .addition:
                return GlobalLiveConfig.Default.coloring.token
            case .subtraction:
                return GlobalLiveConfig.Default.coloring.token
            }
            
        case .parameter(let type):
            switch type {
            case .simple_identifier:
                return GlobalLiveConfig.Default.coloring.token
            }
            
        case .property(let type):
            switch type {
            case .simple_identifier:
                return GlobalLiveConfig.Default.coloring.token
            }
            
        case .punctuation(let type):
            switch type {
            case .bracket(let bracketType):
                switch bracketType {
                case .anyBracket:
                    return GlobalLiveConfig.Default.coloring.token
                case .roundOpen, .roundClose, .curlyOpen, .curlyClose, .squareOpen, .squareClose:
                    return GlobalLiveConfig.Default.coloring.token
                }
            case .delimiter(let delimiterType):
                switch delimiterType {
                case .anyDelimiter:
                    return GlobalLiveConfig.Default.coloring.token
                case .comma, .period, .colon:
                    return GlobalLiveConfig.Default.coloring.token
                }
            }
            
        case .type(let type):
            switch type {
            case .anyTypeIdentifier:
                return GlobalLiveConfig.Default.coloring.token
            case .simple_identifier:
                return GlobalLiveConfig.Default.coloring.token
            case .type_identifier:
                return GlobalLiveConfig.Default.coloring.token
            }
            
        case .variable(let type):
            switch type {
            case .anyVariable:
                return GlobalLiveConfig.Default.coloring.token
            case .builtin(let builtinType):
                switch builtinType {
                case .anyBuiltin:
                    return GlobalLiveConfig.Default.coloring.token
                case .self_expression:
                    return GlobalLiveConfig.Default.coloring.token
                }
            case .pattern:
                return GlobalLiveConfig.Default.coloring.token
            }
        case .unknown:
            return GlobalLiveConfig.Default.coloring.unknownToken
        }
    }
}
