//  
//
//  Created on 12/17/23.
//  

import Foundation
import BitHandling
import MetalLink

public struct TreeSitterColor {
    public var comment              = NSUIColor(displayP3Red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
    public var conditionalGuard     = NSUIColor(displayP3Red: 0.7, green: 0.2, blue: 0.6, alpha: 1.0)
    public var initConstructor      = NSUIColor(displayP3Red: 0.7, green: 0.5, blue: 0.6, alpha: 1.0)

}


extension SyntaxType {
    var foregroundColor: NSUIColor {
        switch self {
        case .comment:
            return GlobalLiveConfig.Default.coloring.comment
        case .conditional(let type):
            switch type {
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
            case .classDefinition(let classDeclarationType):
                return GlobalLiveConfig.Default.coloring.classDeclaration
            case .function(let functionDeclarationType):
                return GlobalLiveConfig.Default.coloring.functionDeclaration
            case .importDefinition(let identifierType):
                return GlobalLiveConfig.Default.coloring.token
            case .method(let classDeclarationType):
                return GlobalLiveConfig.Default.coloring.classDeclaration
            case .property(let propertyDeclarationType):
                return GlobalLiveConfig.Default.coloring.classDeclaration
            }
        case .float(let type):
            switch type {
            case .real_literal:
                return GlobalLiveConfig.Default.coloring.token
            }
        case .function(let type):
            switch type {
            case .call(let simpleIdentifierType):
                return GlobalLiveConfig.Default.coloring.functionCallExpression
            case .macro(let macroType):
                return GlobalLiveConfig.Default.coloring.token
            }
        case .include(let type):
            switch type {
            case .importInclude:
                return GlobalLiveConfig.Default.coloring.token
            }
        case .keyword(let type):
            switch type {
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
            case .integer_literal:
                return GlobalLiveConfig.Default.coloring.token
            }
        case .operatorType(let type):
            switch type {
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
                case .roundOpen, .roundClose, .curlyOpen, .curlyClose, .squareOpen, .squareClose:
                    return GlobalLiveConfig.Default.coloring.token
                }
            case .delimiter(let delimiterType):
                switch delimiterType {
                case .comma, .period, .colon:
                    return GlobalLiveConfig.Default.coloring.token
                }
            }
        case .type(let type):
            switch type {
            case .simple_identifier:
                return GlobalLiveConfig.Default.coloring.token
            case .type_identifier:
                return GlobalLiveConfig.Default.coloring.token
            }
        case .variable(let type):
            switch type {
            case .builtin(let builtinType):
                switch builtinType {
                case .self_expression:
                    return GlobalLiveConfig.Default.coloring.token
                }
            case .pattern:
                return GlobalLiveConfig.Default.coloring.token
            }
        }
    }
}
