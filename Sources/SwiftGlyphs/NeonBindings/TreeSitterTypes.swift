//  
//
//  Created on 12/17/23.
//  


enum SyntaxType {
    case comment
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
}

enum ConditionalType {
    case guardConditional
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

enum IdentifierType {}

enum PropertyDeclarationType {
    case class_declaration
    case property_declaration
}

enum FloatType {
    case real_literal
}

enum FunctionType {
    case call(SimpleIdentifierType)
    case macro(MacroType)
}

enum MacroType {
    case directive
}

enum IncludeType {
    case importInclude
}

enum KeywordType {
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
    case integer_literal
}

enum OperatorType {
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
    case roundOpen
    case roundClose
    case curlyOpen
    case curlyClose
    case squareOpen
    case squareClose
}

enum DelimiterType {
    case comma
    case period
    case colon
}

enum TypeType {
    case simple_identifier
    case type_identifier
}

enum VariableType {
    case builtin(BuiltinType)
    case pattern
}

enum BuiltinType {
    case self_expression
}

enum SimpleIdentifierType {}
