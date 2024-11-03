//
//
//  Created on 12/17/23.
//

import Foundation
import BitHandling
import MetalLink

extension SyntaxType {
    var foregroundColor: SerialColor {
        get {
            switch self {
            case .someRepeat:
                return GlobalLiveConfig.Default.coloring.someRepeat
            
            case .someLabel:
                return GlobalLiveConfig.Default.coloring.someLabel
                
            case .rawString:
                return GlobalLiveConfig.Default.coloring.rawString
            
            case .rawBoolean:
                return GlobalLiveConfig.Default.coloring.rawBool
            
            case .comment:
                return GlobalLiveConfig.Default.coloring.comment
            
            case .conditional:
                return GlobalLiveConfig.Default.coloring.conditional
            
            case .constructor:
                return GlobalLiveConfig.Default.coloring.constructor
            
            case .definition(let type):
                switch type {
                case .classDefinition:
                    return GlobalLiveConfig.Default.coloring.classDefinition
                case .method:
                    return GlobalLiveConfig.Default.coloring.methodDefinition
                case .property:
                    return GlobalLiveConfig.Default.coloring.propertyDefinition
                case .function:
                    return GlobalLiveConfig.Default.coloring.functionDeclaration
                case .importDefinition:
                    return GlobalLiveConfig.Default.coloring.importDefinition
                }
            
            case .float:
                return GlobalLiveConfig.Default.coloring.floatLiteral
            
            case .function(let type):
                switch type {
                case .call:
                    return GlobalLiveConfig.Default.coloring.functionCallExpression
                case .macro:
                    return GlobalLiveConfig.Default.coloring.macroFunction
                }
            
            case .include:
                return GlobalLiveConfig.Default.coloring.includeDirective
            
            case .keyword(let type):
                switch type {
                case .anyKeyword:
                    return GlobalLiveConfig.Default.coloring.anyKeyword
                case .elseKeyword:
                    return GlobalLiveConfig.Default.coloring.elseKeyword
                case .letKeyword:
                    return GlobalLiveConfig.Default.coloring.letKeyword
                case .throw_keyword:
                    return GlobalLiveConfig.Default.coloring.throwKeyword
                case .throwsKeyword:
                    return GlobalLiveConfig.Default.coloring.throwsKeyword
                case .visibility_modifier:
                    return GlobalLiveConfig.Default.coloring.visibilityModifier
                case .classKeyword:
                    return GlobalLiveConfig.Default.coloring.classDeclaration
                case .extensionKeyword:
                    return GlobalLiveConfig.Default.coloring.extensionKeyword
                case .function:
                    return GlobalLiveConfig.Default.coloring.functionKeyword
                case .varKeyword:
                    return GlobalLiveConfig.Default.coloring.variableKeyword
                case .operatorKeyword:
                    return GlobalLiveConfig.Default.coloring.operatorKeyword
                case .returnKeyword:
                    return GlobalLiveConfig.Default.coloring.returnToken
                }
            
            case .local(let type):
                switch type {
                case .scope(let scopeType):
                    switch scopeType {
                    case .class_declaration:
                        return GlobalLiveConfig.Default.coloring.localScopeClassDeclaration
                    case .function_declaration:
                        return GlobalLiveConfig.Default.coloring.localScopeFunctionDeclaration
                    case .guard_statement:
                        return GlobalLiveConfig.Default.coloring.localScopeGuardStatement
                    case .property_declaration:
                        return GlobalLiveConfig.Default.coloring.localScopePropertyDeclaration
                    case .statements:
                        return GlobalLiveConfig.Default.coloring.localScopeStatements
                    }
                }
            
            case .method:
                return GlobalLiveConfig.Default.coloring.method
            
            case .name(let type):
                switch type {
                case .initName:
                    return GlobalLiveConfig.Default.coloring.initName
                case .simple_identifier:
                    return GlobalLiveConfig.Default.coloring.simpleIdentifierName
                case .type_identifier:
                    return GlobalLiveConfig.Default.coloring.typeIdentifierName
                }
            
            case .number(let type):
                switch type {
                case .float:
                    return GlobalLiveConfig.Default.coloring.floatLiteral
                case .anyLiteral:
                    return GlobalLiveConfig.Default.coloring.numberLiteral
                case .integer_literal:
                    return GlobalLiveConfig.Default.coloring.integerLiteral
                }
            
            case .operatorType(let type):
                switch type {
                case .anyOperator:
                    return GlobalLiveConfig.Default.coloring.anyOperator
                case .lessThan:
                    return GlobalLiveConfig.Default.coloring.lessThanOperator
                case .equal:
                    return GlobalLiveConfig.Default.coloring.equalOperator
                case .greaterThan:
                    return GlobalLiveConfig.Default.coloring.greaterThanOperator
                case .addition:
                    return GlobalLiveConfig.Default.coloring.additionOperator
                case .subtraction:
                    return GlobalLiveConfig.Default.coloring.subtractionOperator
                }
            
            case .parameter:
                return GlobalLiveConfig.Default.coloring.parameter
            
            case .property:
                return GlobalLiveConfig.Default.coloring.property
            
            case .punctuation(let type):
                switch type {
                case .bracket(let bracketType):
                    switch bracketType {
                    case .anyBracket:
                        return GlobalLiveConfig.Default.coloring.bracket
                    case .roundOpen:
                        return GlobalLiveConfig.Default.coloring.roundOpenBracket
                    case .roundClose:
                        return GlobalLiveConfig.Default.coloring.roundCloseBracket
                    case .curlyOpen:
                        return GlobalLiveConfig.Default.coloring.curlyOpenBracket
                    case .curlyClose:
                        return GlobalLiveConfig.Default.coloring.curlyCloseBracket
                    case .squareOpen:
                        return GlobalLiveConfig.Default.coloring.squareOpenBracket
                    case .squareClose:
                        return GlobalLiveConfig.Default.coloring.squareCloseBracket
                    }
                case .delimiter(let delimiterType):
                    switch delimiterType {
                    case .anyDelimiter:
                        return GlobalLiveConfig.Default.coloring.anyDelimiter
                    case .comma:
                        return GlobalLiveConfig.Default.coloring.comma
                    case .period:
                        return GlobalLiveConfig.Default.coloring.period
                    case .colon:
                        return GlobalLiveConfig.Default.coloring.colon
                    }
                }
            
            case .type(let type):
                switch type {
                case .anyTypeIdentifier:
                    return GlobalLiveConfig.Default.coloring.typeIdentifier
                case .simple_identifier:
                    return GlobalLiveConfig.Default.coloring.simpleTypeIdentifier
                case .type_identifier:
                    return GlobalLiveConfig.Default.coloring.typeIdentifier
                }
            
            case .variable(let type):
                switch type {
                case .anyVariable:
                    return GlobalLiveConfig.Default.coloring.anyVariable
                case .builtin(let builtinType):
                    switch builtinType {
                    case .anyBuiltin:
                        return GlobalLiveConfig.Default.coloring.varableBuiltin
                    case .self_expression:
                        return GlobalLiveConfig.Default.coloring.variableSelfExpression
                    }
                case .pattern:
                    return GlobalLiveConfig.Default.coloring.variablePattern
                }
            
            case .unknown:
                return GlobalLiveConfig.Default.coloring.unknownToken
            }
        }
        set {
            switch self {
            case .someRepeat:
                GlobalLiveConfig.Default.coloring.someRepeat = newValue
            
            case .someLabel:
                GlobalLiveConfig.Default.coloring.someLabel = newValue
                
            case .rawString:
                GlobalLiveConfig.Default.coloring.rawString = newValue
            
            case .rawBoolean:
                GlobalLiveConfig.Default.coloring.rawBool = newValue
            
            case .comment:
                GlobalLiveConfig.Default.coloring.comment = newValue
            
            case .conditional:
                GlobalLiveConfig.Default.coloring.conditional = newValue
            
            case .constructor:
                GlobalLiveConfig.Default.coloring.constructor = newValue
            
            case .definition(let type):
                switch type {
                case .classDefinition:
                    GlobalLiveConfig.Default.coloring.classDefinition = newValue
                case .method:
                    GlobalLiveConfig.Default.coloring.methodDefinition = newValue
                case .property:
                    GlobalLiveConfig.Default.coloring.propertyDefinition = newValue
                case .function:
                    GlobalLiveConfig.Default.coloring.functionDeclaration = newValue
                case .importDefinition:
                    GlobalLiveConfig.Default.coloring.importDefinition = newValue
                }
            
            case .float:
                GlobalLiveConfig.Default.coloring.floatLiteral = newValue
            
            case .function(let type):
                switch type {
                case .call:
                    GlobalLiveConfig.Default.coloring.functionCallExpression = newValue
                case .macro:
                    GlobalLiveConfig.Default.coloring.macroFunction = newValue
                }
            
            case .include:
                GlobalLiveConfig.Default.coloring.includeDirective = newValue
            
            case .keyword(let type):
                switch type {
                case .anyKeyword:
                    GlobalLiveConfig.Default.coloring.anyKeyword = newValue
                case .elseKeyword:
                    GlobalLiveConfig.Default.coloring.elseKeyword = newValue
                case .letKeyword:
                    GlobalLiveConfig.Default.coloring.letKeyword = newValue
                case .throw_keyword:
                    GlobalLiveConfig.Default.coloring.throwKeyword = newValue
                case .throwsKeyword:
                    GlobalLiveConfig.Default.coloring.throwsKeyword = newValue
                case .visibility_modifier:
                    GlobalLiveConfig.Default.coloring.visibilityModifier = newValue
                case .classKeyword:
                    GlobalLiveConfig.Default.coloring.classDeclaration = newValue
                case .extensionKeyword:
                    GlobalLiveConfig.Default.coloring.extensionKeyword = newValue
                case .function:
                    GlobalLiveConfig.Default.coloring.functionKeyword = newValue
                case .varKeyword:
                    GlobalLiveConfig.Default.coloring.variableKeyword = newValue
                case .operatorKeyword:
                    GlobalLiveConfig.Default.coloring.operatorKeyword = newValue
                case .returnKeyword:
                    GlobalLiveConfig.Default.coloring.returnToken = newValue
                }
            
            case .local(let type):
                switch type {
                case .scope(let scopeType):
                    switch scopeType {
                    case .class_declaration:
                        GlobalLiveConfig.Default.coloring.localScopeClassDeclaration = newValue
                    case .function_declaration:
                        GlobalLiveConfig.Default.coloring.localScopeFunctionDeclaration = newValue
                    case .guard_statement:
                        GlobalLiveConfig.Default.coloring.localScopeGuardStatement = newValue
                    case .property_declaration:
                        GlobalLiveConfig.Default.coloring.localScopePropertyDeclaration = newValue
                    case .statements:
                        GlobalLiveConfig.Default.coloring.localScopeStatements = newValue
                    }
                }
            
            case .method:
                GlobalLiveConfig.Default.coloring.method = newValue
            
            case .name(let type):
                switch type {
                case .initName:
                    GlobalLiveConfig.Default.coloring.initName = newValue
                case .simple_identifier:
                    GlobalLiveConfig.Default.coloring.simpleIdentifierName = newValue
                case .type_identifier:
                    GlobalLiveConfig.Default.coloring.typeIdentifierName = newValue
                }
            
            case .number(let type):
                switch type {
                case .float:
                    GlobalLiveConfig.Default.coloring.floatLiteral = newValue
                case .anyLiteral:
                    GlobalLiveConfig.Default.coloring.numberLiteral = newValue
                case .integer_literal:
                    GlobalLiveConfig.Default.coloring.integerLiteral = newValue
                }
            
            case .operatorType(let type):
                switch type {
                case .anyOperator:
                    GlobalLiveConfig.Default.coloring.anyOperator = newValue
                case .lessThan:
                    GlobalLiveConfig.Default.coloring.lessThanOperator = newValue
                case .equal:
                    GlobalLiveConfig.Default.coloring.equalOperator = newValue
                case .greaterThan:
                    GlobalLiveConfig.Default.coloring.greaterThanOperator = newValue
                case .addition:
                    GlobalLiveConfig.Default.coloring.additionOperator = newValue
                case .subtraction:
                    GlobalLiveConfig.Default.coloring.subtractionOperator = newValue
                }
            
            case .parameter:
                GlobalLiveConfig.Default.coloring.parameter = newValue
            
            case .property:
                GlobalLiveConfig.Default.coloring.property = newValue
            
            case .punctuation(let type):
                switch type {
                case .bracket(let bracketType):
                    switch bracketType {
                    case .anyBracket:
                        GlobalLiveConfig.Default.coloring.bracket = newValue
                    case .roundOpen:
                        GlobalLiveConfig.Default.coloring.roundOpenBracket = newValue
                    case .roundClose:
                        GlobalLiveConfig.Default.coloring.roundCloseBracket = newValue
                    case .curlyOpen:
                        GlobalLiveConfig.Default.coloring.curlyOpenBracket = newValue
                    case .curlyClose:
                        GlobalLiveConfig.Default.coloring.curlyCloseBracket = newValue
                    case .squareOpen:
                        GlobalLiveConfig.Default.coloring.squareOpenBracket = newValue
                    case .squareClose:
                        GlobalLiveConfig.Default.coloring.squareCloseBracket = newValue
                    }
                case .delimiter(let delimiterType):
                    switch delimiterType {
                    case .anyDelimiter:
                        GlobalLiveConfig.Default.coloring.anyDelimiter = newValue
                    case .comma:
                        GlobalLiveConfig.Default.coloring.comma = newValue
                    case .period:
                        GlobalLiveConfig.Default.coloring.period = newValue
                    case .colon:
                        GlobalLiveConfig.Default.coloring.colon = newValue
                    }
                }
            
            case .type(let type):
                switch type {
                case .anyTypeIdentifier:
                    GlobalLiveConfig.Default.coloring.typeIdentifier = newValue
                case .simple_identifier:
                    GlobalLiveConfig.Default.coloring.simpleTypeIdentifier = newValue
                case .type_identifier:
                    GlobalLiveConfig.Default.coloring.typeIdentifier = newValue
                }
            
            case .variable(let type):
                switch type {
                case .anyVariable:
                    GlobalLiveConfig.Default.coloring.anyVariable = newValue
                case .builtin(let builtinType):
                    switch builtinType {
                    case .anyBuiltin:
                        GlobalLiveConfig.Default.coloring.varableBuiltin = newValue
                    case .self_expression:
                        GlobalLiveConfig.Default.coloring.variableSelfExpression = newValue
                    }
                case .pattern:
                    GlobalLiveConfig.Default.coloring.variablePattern = newValue
                }
            
            case .unknown:
                GlobalLiveConfig.Default.coloring.unknownToken = newValue
            }
        }
    }
}
