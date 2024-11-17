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
                return GlobalLiveConfig.store.preference.coloring.someRepeat
            
            case .someLabel:
                return GlobalLiveConfig.store.preference.coloring.someLabel
                
            case .rawString:
                return GlobalLiveConfig.store.preference.coloring.rawString
            
            case .rawBoolean:
                return GlobalLiveConfig.store.preference.coloring.rawBool
            
            case .comment:
                return GlobalLiveConfig.store.preference.coloring.comment
            
            case .conditional:
                return GlobalLiveConfig.store.preference.coloring.conditional
            
            case .constructor:
                return GlobalLiveConfig.store.preference.coloring.constructor
            
            case .definition(let type):
                switch type {
                case .classDefinition:
                    return GlobalLiveConfig.store.preference.coloring.classDefinition
                case .method:
                    return GlobalLiveConfig.store.preference.coloring.methodDefinition
                case .property:
                    return GlobalLiveConfig.store.preference.coloring.propertyDefinition
                case .function:
                    return GlobalLiveConfig.store.preference.coloring.functionDeclaration
                case .importDefinition:
                    return GlobalLiveConfig.store.preference.coloring.importDefinition
                }
            
            case .float:
                return GlobalLiveConfig.store.preference.coloring.floatLiteral
            
            case .function(let type):
                switch type {
                case .call:
                    return GlobalLiveConfig.store.preference.coloring.functionCallExpression
                case .macro:
                    return GlobalLiveConfig.store.preference.coloring.macroFunction
                }
            
            case .include:
                return GlobalLiveConfig.store.preference.coloring.includeDirective
            
            case .keyword(let type):
                switch type {
                case .anyKeyword:
                    return GlobalLiveConfig.store.preference.coloring.anyKeyword
                case .elseKeyword:
                    return GlobalLiveConfig.store.preference.coloring.elseKeyword
                case .letKeyword:
                    return GlobalLiveConfig.store.preference.coloring.letKeyword
                case .throw_keyword:
                    return GlobalLiveConfig.store.preference.coloring.throwKeyword
                case .throwsKeyword:
                    return GlobalLiveConfig.store.preference.coloring.throwsKeyword
                case .visibility_modifier:
                    return GlobalLiveConfig.store.preference.coloring.visibilityModifier
                case .classKeyword:
                    return GlobalLiveConfig.store.preference.coloring.classDeclaration
                case .extensionKeyword:
                    return GlobalLiveConfig.store.preference.coloring.extensionKeyword
                case .function:
                    return GlobalLiveConfig.store.preference.coloring.functionKeyword
                case .varKeyword:
                    return GlobalLiveConfig.store.preference.coloring.variableKeyword
                case .operatorKeyword:
                    return GlobalLiveConfig.store.preference.coloring.operatorKeyword
                case .returnKeyword:
                    return GlobalLiveConfig.store.preference.coloring.returnToken
                }
            
            case .local(let type):
                switch type {
                case .scope(let scopeType):
                    switch scopeType {
                    case .class_declaration:
                        return GlobalLiveConfig.store.preference.coloring.localScopeClassDeclaration
                    case .function_declaration:
                        return GlobalLiveConfig.store.preference.coloring.localScopeFunctionDeclaration
                    case .guard_statement:
                        return GlobalLiveConfig.store.preference.coloring.localScopeGuardStatement
                    case .property_declaration:
                        return GlobalLiveConfig.store.preference.coloring.localScopePropertyDeclaration
                    case .statements:
                        return GlobalLiveConfig.store.preference.coloring.localScopeStatements
                    }
                }
            
            case .method:
                return GlobalLiveConfig.store.preference.coloring.method
            
            case .name(let type):
                switch type {
                case .initName:
                    return GlobalLiveConfig.store.preference.coloring.initName
                case .simple_identifier:
                    return GlobalLiveConfig.store.preference.coloring.simpleIdentifierName
                case .type_identifier:
                    return GlobalLiveConfig.store.preference.coloring.typeIdentifierName
                }
            
            case .number(let type):
                switch type {
                case .float:
                    return GlobalLiveConfig.store.preference.coloring.floatLiteral
                case .anyLiteral:
                    return GlobalLiveConfig.store.preference.coloring.numberLiteral
                case .integer_literal:
                    return GlobalLiveConfig.store.preference.coloring.integerLiteral
                }
            
            case .operatorType(let type):
                switch type {
                case .anyOperator:
                    return GlobalLiveConfig.store.preference.coloring.anyOperator
                case .lessThan:
                    return GlobalLiveConfig.store.preference.coloring.lessThanOperator
                case .equal:
                    return GlobalLiveConfig.store.preference.coloring.equalOperator
                case .greaterThan:
                    return GlobalLiveConfig.store.preference.coloring.greaterThanOperator
                case .addition:
                    return GlobalLiveConfig.store.preference.coloring.additionOperator
                case .subtraction:
                    return GlobalLiveConfig.store.preference.coloring.subtractionOperator
                }
            
            case .parameter:
                return GlobalLiveConfig.store.preference.coloring.parameter
            
            case .property:
                return GlobalLiveConfig.store.preference.coloring.property
            
            case .punctuation(let type):
                switch type {
                case .bracket(let bracketType):
                    switch bracketType {
                    case .anyBracket:
                        return GlobalLiveConfig.store.preference.coloring.bracket
                    case .roundOpen:
                        return GlobalLiveConfig.store.preference.coloring.roundOpenBracket
                    case .roundClose:
                        return GlobalLiveConfig.store.preference.coloring.roundCloseBracket
                    case .curlyOpen:
                        return GlobalLiveConfig.store.preference.coloring.curlyOpenBracket
                    case .curlyClose:
                        return GlobalLiveConfig.store.preference.coloring.curlyCloseBracket
                    case .squareOpen:
                        return GlobalLiveConfig.store.preference.coloring.squareOpenBracket
                    case .squareClose:
                        return GlobalLiveConfig.store.preference.coloring.squareCloseBracket
                    }
                case .delimiter(let delimiterType):
                    switch delimiterType {
                    case .anyDelimiter:
                        return GlobalLiveConfig.store.preference.coloring.anyDelimiter
                    case .comma:
                        return GlobalLiveConfig.store.preference.coloring.comma
                    case .period:
                        return GlobalLiveConfig.store.preference.coloring.period
                    case .colon:
                        return GlobalLiveConfig.store.preference.coloring.colon
                    }
                }
            
            case .type(let type):
                switch type {
                case .anyTypeIdentifier:
                    return GlobalLiveConfig.store.preference.coloring.typeIdentifier
                case .simple_identifier:
                    return GlobalLiveConfig.store.preference.coloring.simpleTypeIdentifier
                case .type_identifier:
                    return GlobalLiveConfig.store.preference.coloring.typeIdentifier
                }
            
            case .variable(let type):
                switch type {
                case .anyVariable:
                    return GlobalLiveConfig.store.preference.coloring.anyVariable
                case .builtin(let builtinType):
                    switch builtinType {
                    case .anyBuiltin:
                        return GlobalLiveConfig.store.preference.coloring.varableBuiltin
                    case .self_expression:
                        return GlobalLiveConfig.store.preference.coloring.variableSelfExpression
                    }
                case .pattern:
                    return GlobalLiveConfig.store.preference.coloring.variablePattern
                }
            
            case .unknown:
                return GlobalLiveConfig.store.preference.coloring.unknownToken
            }
        }
        set {
            switch self {
            case .someRepeat:
                GlobalLiveConfig.store.preference.coloring.someRepeat = newValue
            
            case .someLabel:
                GlobalLiveConfig.store.preference.coloring.someLabel = newValue
                
            case .rawString:
                GlobalLiveConfig.store.preference.coloring.rawString = newValue
            
            case .rawBoolean:
                GlobalLiveConfig.store.preference.coloring.rawBool = newValue
            
            case .comment:
                GlobalLiveConfig.store.preference.coloring.comment = newValue
            
            case .conditional:
                GlobalLiveConfig.store.preference.coloring.conditional = newValue
            
            case .constructor:
                GlobalLiveConfig.store.preference.coloring.constructor = newValue
            
            case .definition(let type):
                switch type {
                case .classDefinition:
                    GlobalLiveConfig.store.preference.coloring.classDefinition = newValue
                case .method:
                    GlobalLiveConfig.store.preference.coloring.methodDefinition = newValue
                case .property:
                    GlobalLiveConfig.store.preference.coloring.propertyDefinition = newValue
                case .function:
                    GlobalLiveConfig.store.preference.coloring.functionDeclaration = newValue
                case .importDefinition:
                    GlobalLiveConfig.store.preference.coloring.importDefinition = newValue
                }
            
            case .float:
                GlobalLiveConfig.store.preference.coloring.floatLiteral = newValue
            
            case .function(let type):
                switch type {
                case .call:
                    GlobalLiveConfig.store.preference.coloring.functionCallExpression = newValue
                case .macro:
                    GlobalLiveConfig.store.preference.coloring.macroFunction = newValue
                }
            
            case .include:
                GlobalLiveConfig.store.preference.coloring.includeDirective = newValue
            
            case .keyword(let type):
                switch type {
                case .anyKeyword:
                    GlobalLiveConfig.store.preference.coloring.anyKeyword = newValue
                case .elseKeyword:
                    GlobalLiveConfig.store.preference.coloring.elseKeyword = newValue
                case .letKeyword:
                    GlobalLiveConfig.store.preference.coloring.letKeyword = newValue
                case .throw_keyword:
                    GlobalLiveConfig.store.preference.coloring.throwKeyword = newValue
                case .throwsKeyword:
                    GlobalLiveConfig.store.preference.coloring.throwsKeyword = newValue
                case .visibility_modifier:
                    GlobalLiveConfig.store.preference.coloring.visibilityModifier = newValue
                case .classKeyword:
                    GlobalLiveConfig.store.preference.coloring.classDeclaration = newValue
                case .extensionKeyword:
                    GlobalLiveConfig.store.preference.coloring.extensionKeyword = newValue
                case .function:
                    GlobalLiveConfig.store.preference.coloring.functionKeyword = newValue
                case .varKeyword:
                    GlobalLiveConfig.store.preference.coloring.variableKeyword = newValue
                case .operatorKeyword:
                    GlobalLiveConfig.store.preference.coloring.operatorKeyword = newValue
                case .returnKeyword:
                    GlobalLiveConfig.store.preference.coloring.returnToken = newValue
                }
            
            case .local(let type):
                switch type {
                case .scope(let scopeType):
                    switch scopeType {
                    case .class_declaration:
                        GlobalLiveConfig.store.preference.coloring.localScopeClassDeclaration = newValue
                    case .function_declaration:
                        GlobalLiveConfig.store.preference.coloring.localScopeFunctionDeclaration = newValue
                    case .guard_statement:
                        GlobalLiveConfig.store.preference.coloring.localScopeGuardStatement = newValue
                    case .property_declaration:
                        GlobalLiveConfig.store.preference.coloring.localScopePropertyDeclaration = newValue
                    case .statements:
                        GlobalLiveConfig.store.preference.coloring.localScopeStatements = newValue
                    }
                }
            
            case .method:
                GlobalLiveConfig.store.preference.coloring.method = newValue
            
            case .name(let type):
                switch type {
                case .initName:
                    GlobalLiveConfig.store.preference.coloring.initName = newValue
                case .simple_identifier:
                    GlobalLiveConfig.store.preference.coloring.simpleIdentifierName = newValue
                case .type_identifier:
                    GlobalLiveConfig.store.preference.coloring.typeIdentifierName = newValue
                }
            
            case .number(let type):
                switch type {
                case .float:
                    GlobalLiveConfig.store.preference.coloring.floatLiteral = newValue
                case .anyLiteral:
                    GlobalLiveConfig.store.preference.coloring.numberLiteral = newValue
                case .integer_literal:
                    GlobalLiveConfig.store.preference.coloring.integerLiteral = newValue
                }
            
            case .operatorType(let type):
                switch type {
                case .anyOperator:
                    GlobalLiveConfig.store.preference.coloring.anyOperator = newValue
                case .lessThan:
                    GlobalLiveConfig.store.preference.coloring.lessThanOperator = newValue
                case .equal:
                    GlobalLiveConfig.store.preference.coloring.equalOperator = newValue
                case .greaterThan:
                    GlobalLiveConfig.store.preference.coloring.greaterThanOperator = newValue
                case .addition:
                    GlobalLiveConfig.store.preference.coloring.additionOperator = newValue
                case .subtraction:
                    GlobalLiveConfig.store.preference.coloring.subtractionOperator = newValue
                }
            
            case .parameter:
                GlobalLiveConfig.store.preference.coloring.parameter = newValue
            
            case .property:
                GlobalLiveConfig.store.preference.coloring.property = newValue
            
            case .punctuation(let type):
                switch type {
                case .bracket(let bracketType):
                    switch bracketType {
                    case .anyBracket:
                        GlobalLiveConfig.store.preference.coloring.bracket = newValue
                    case .roundOpen:
                        GlobalLiveConfig.store.preference.coloring.roundOpenBracket = newValue
                    case .roundClose:
                        GlobalLiveConfig.store.preference.coloring.roundCloseBracket = newValue
                    case .curlyOpen:
                        GlobalLiveConfig.store.preference.coloring.curlyOpenBracket = newValue
                    case .curlyClose:
                        GlobalLiveConfig.store.preference.coloring.curlyCloseBracket = newValue
                    case .squareOpen:
                        GlobalLiveConfig.store.preference.coloring.squareOpenBracket = newValue
                    case .squareClose:
                        GlobalLiveConfig.store.preference.coloring.squareCloseBracket = newValue
                    }
                case .delimiter(let delimiterType):
                    switch delimiterType {
                    case .anyDelimiter:
                        GlobalLiveConfig.store.preference.coloring.anyDelimiter = newValue
                    case .comma:
                        GlobalLiveConfig.store.preference.coloring.comma = newValue
                    case .period:
                        GlobalLiveConfig.store.preference.coloring.period = newValue
                    case .colon:
                        GlobalLiveConfig.store.preference.coloring.colon = newValue
                    }
                }
            
            case .type(let type):
                switch type {
                case .anyTypeIdentifier:
                    GlobalLiveConfig.store.preference.coloring.typeIdentifier = newValue
                case .simple_identifier:
                    GlobalLiveConfig.store.preference.coloring.simpleTypeIdentifier = newValue
                case .type_identifier:
                    GlobalLiveConfig.store.preference.coloring.typeIdentifier = newValue
                }
            
            case .variable(let type):
                switch type {
                case .anyVariable:
                    GlobalLiveConfig.store.preference.coloring.anyVariable = newValue
                case .builtin(let builtinType):
                    switch builtinType {
                    case .anyBuiltin:
                        GlobalLiveConfig.store.preference.coloring.varableBuiltin = newValue
                    case .self_expression:
                        GlobalLiveConfig.store.preference.coloring.variableSelfExpression = newValue
                    }
                case .pattern:
                    GlobalLiveConfig.store.preference.coloring.variablePattern = newValue
                }
            
            case .unknown:
                GlobalLiveConfig.store.preference.coloring.unknownToken = newValue
            }
        }
    }
}
