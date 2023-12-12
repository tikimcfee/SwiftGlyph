//
//
//public extension Trivia {
//    var stringified: String {
//        text
//    }
//}
//
//public extension Syntax {
//    var allText: String {
//        return tokens(viewMode: .all).reduce(into: "") { result, token in
//            result.append(token.triviaAndText)
//        }
//    }
//    
//    var strippedText: String {
//        return tokens(viewMode: .all).reduce(into: "") { result, token in
//            result.append(token.text)
//        }
//    }
//    
//    func cornerText(_ count: Int) -> String {
////        let stripped = description
////        return String(stripped.prefix(count) + stripped.suffix(count))
//        
//        return String(description.prefix(count))
//        
////        return tokens.prefix(count).reduce(into: "") { result, token in
////            result.append(token.text)
////        }
//    }
//}
//
//public extension TokenSyntax {
//    var triviaAndText: String {
//        leadingTrivia.stringified
//            .appending(text)
//            .appending(trailingTrivia.stringified)
//    }
//    
//    var splitText: [String] {
//        switch tokenKind {
//        case let .stringSegment(literal):
//            return literal.stringLines
//        default:
//            return [text]
//        }
//    }
//}
//
//public extension SyntaxChildren {
//    func listOfChildren() -> String {
//        reduce(into: "") { result, element in
//            let elementList = element
//                .children(viewMode: .all)
//                .listOfChildren()
//            
//            result.append(
//                String(describing: element.syntaxNodeType)
//            )
//            result.append(
//                "\n\t\t\(elementList)"
//            )
//            if element != last { result.append("\n\t") }
//        }
//    }
//}
