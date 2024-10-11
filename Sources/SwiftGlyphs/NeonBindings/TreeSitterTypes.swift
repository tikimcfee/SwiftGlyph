//  
//
//  Created on 12/17/23.
//

extension SyntaxType: Hashable, Equatable { }
extension ConditionalType: Hashable, Equatable { }
extension ConstructorType: Hashable, Equatable { }
extension DefinitionType: Hashable, Equatable { }
extension FloatType: Hashable, Equatable { }
extension FunctionType: Hashable, Equatable { }
extension IncludeType: Hashable, Equatable { }
extension KeywordType: Hashable, Equatable { }
extension LocalType: Hashable, Equatable { }
extension MethodType: Hashable, Equatable { }
extension NameType: Hashable, Equatable { }
extension NumberType: Hashable, Equatable { }
extension OperatorType: Hashable, Equatable { }
extension ParameterType: Hashable, Equatable { }
extension PropertyType: Hashable, Equatable { }
extension PunctuationType: Hashable, Equatable { }
extension TypeType: Hashable, Equatable { }
extension VariableType: Hashable, Equatable { }

enum SyntaxType {
    case unknown
    case comment
    case rawString
    case rawBoolean
    case someLabel
    case someRepeat
    case conditional(ConditionalType)
    case constructor(ConstructorType)
    case definition(DefinitionType)
    case float(FloatType)
    case function(FunctionType)
    case include(IncludeType)
    case keyword(KeywordType)
    case local(LocalType)
    case method(MethodType)
    case name(NameType)
    case number(NumberType)
    case operatorType(OperatorType)
    case parameter(ParameterType)
    case property(PropertyType)
    case punctuation(PunctuationType)
    case type(TypeType)
    case variable(VariableType)
    
    static func fromComponents(_ components: [String]) -> SyntaxType {
        switch components.count {
        case 0:
            return .unknown
            
        case 1:
            return fromOne(components[0])
            
        case 2:
            return fromTwo(components[0],
                           components[1])
        default:
            return .unknown
        }
    }
    
    static func fromOne(
        _ string: String
    ) -> SyntaxType {
        switch string {
        case "spell": return .unknown
        case "comment": /* "spell" // Ignoring 'spell'.. wth is it? */
            return .comment
            
        case "include":
            return .include(.importInclude)
        case "keyword":
            return .keyword(.anyKeyword)
        case "type":
            return .type(.anyTypeIdentifier)
        case "property":
            return .property(.simple_identifier)
        case "variable":
            return .variable(.anyVariable)
        case "constructor":
            return .constructor(.initConstructor)
        case "parameter":
            return .parameter(.simple_identifier)
        case "operator":
            return .operatorType(.anyOperator)
        case "method":
            return .method(.simple_identifier)
        case "conditional":
            return .conditional(.anyConditional)
        case "string":
            return .rawString
        case "boolean":
            return .rawBoolean
        case "number":
            return .number(.anyLiteral)
        case "float":
            return .number(.float)
        case "label":
            return .someLabel
        case "repeat":
            return .someRepeat
        default:
            print("unknown syntax type: \(string)")
            return .unknown
        }
    }
    
    static func fromTwo(
        _ left: String,
        _ right: String
    ) -> SyntaxType {
        switch (left, right) {
        case ("function", "call"):
            return .function(.call(.identifier))
        case ("function", "macro"):
            return .function(.macro(.directive))
        case ("keyword", "function"):
            return .keyword(.function(.funcType))
        case ("keyword", "operator"):
            return .keyword(.operatorKeyword)
        case ("keyword", "return"):
            return .keyword(.returnKeyword)
        case ("punctuation", "bracket"):
            return .punctuation(.bracket(.anyBracket))
        case ("punctuation", "delimiter"):
            return .punctuation(.delimiter(.anyDelimiter))
        case ("variable", "builtin"):
            return .variable(.builtin(.anyBuiltin))
        default:
            print("unknown components: |\(left)| |\(right)|")
            return .unknown
        }
    }
}

enum ConditionalType {
    case anyConditional
    case guardConditional
    case ifConditional
}

enum ConstructorType {
    case initConstructor
}

enum DefinitionType {
    case classDefinition(ClassDeclarationType)
    case function(FunctionDeclarationType)
    case importDefinition(IdentifierType)
    case method(ClassDeclarationType)
    case property(PropertyDeclarationType)
}

enum ClassDeclarationType {
    case class_declaration
}

enum FunctionDeclarationType {
    case function_declaration
    case simple_identifier
}

enum IdentifierType {
    case identifier
}

enum PropertyDeclarationType {
    case class_declaration
    case property_declaration
}

enum FloatType {
    case real_literal
}

enum FunctionType {
    case call(IdentifierType)
    case macro(MacroType)
}

enum MacroType {
    case directive
}

enum IncludeType {
    case importInclude
}

enum KeywordType {
    case anyKeyword
    case returnKeyword
    case operatorKeyword
    case classKeyword
    case elseKeyword
    case extensionKeyword
    case function(FuncType)
    case letKeyword
    case throw_keyword
    case throwsKeyword
    case varKeyword
    case visibility_modifier
}

enum FuncType {
    case funcType
}

enum LocalType {
    case scope(ScopeType)
}

enum ScopeType {
    case class_declaration
    case function_declaration
    case guard_statement
    case property_declaration
    case statements
}

enum MethodType {
    case simple_identifier
}

enum NameType {
    case initName
    case simple_identifier
    case type_identifier
}

enum NumberType {
    case anyLiteral
    case integer_literal
    case float
}

enum OperatorType {
    case anyOperator
    case lessThan
    case equal
    case greaterThan
    case addition
    case subtraction
}

enum ParameterType {
    case simple_identifier
}

enum PropertyType {
    case simple_identifier
}

enum PunctuationType {
    case bracket(BracketType)
    case delimiter(DelimiterType)
}

enum BracketType {
    case anyBracket
    case roundOpen
    case roundClose
    case curlyOpen
    case curlyClose
    case squareOpen
    case squareClose
}

enum DelimiterType {
    case anyDelimiter
    case comma
    case period
    case colon
}

enum TypeType {
    case anyTypeIdentifier
    case simple_identifier
    case type_identifier
}

enum VariableType {
    case anyVariable
    case builtin(BuiltinType)
    case pattern
}

enum BuiltinType {
    case anyBuiltin
    case self_expression
}
