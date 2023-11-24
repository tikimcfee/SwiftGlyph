import SwiftLSP
import SwiftyToolz

/**
 ⛔️ Do not change! This is part of the ".codebase" file format.
 */
final class CodeSymbol: Codable, Sendable
{
    init(lspDocumentySymbol: LSPDocumentSymbol,
         referenceLocations: [ReferenceLocation],
         children: [CodeSymbol]) throws
    {
        guard let decodedKind = lspDocumentySymbol.decodedKind else
        {
            throw "Could not decode LSP document symbol kind of value \(lspDocumentySymbol.kind)"
        }
        
        name = lspDocumentySymbol.name
        kind = decodedKind
        range = lspDocumentySymbol.range
        selectionRange = lspDocumentySymbol.selectionRange
        references = referenceLocations.isEmpty ? nil : referenceLocations
        
        self.children = children.isEmpty ? nil : children
    }
    
    let name: String
    let kind: LSPDocumentSymbol.SymbolKind
    let range: LSPRange
    let selectionRange: LSPRange
    
    let references: [ReferenceLocation]?
    
    struct ReferenceLocation: Codable, Sendable
    {
        /// without root folder, like: `"SubfolderOfRoot/Deeper/Subfolders/myFile.swift"`
        let filePathRelativeToRoot: String
        
        let range: LSPRange
    }
    
    let children: [CodeSymbol]?
}
