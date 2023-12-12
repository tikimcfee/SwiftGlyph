//
//  SemanticInfoBuilder.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 10/28/21.
//

import Foundation

public class SemanticInfoBuilder {
    func semanticInfo(
        for node: Syntax,
        fileName: String? = nil
    ) -> SemanticInfo {
        let info = makeDefaultInfo(for: node, fileName: fileName)
        
        // TODO: Make all the info again. The abstraction.. ya did good.
        
        return info
    }
}

private extension SemanticInfoBuilder {
    func makeDefaultInfo(
        for node: Syntax,
        fileName: String? = nil
    ) -> SemanticInfo {
        let blankSyntax = Syntax()
        return SemanticInfo(
            node: blankSyntax,
            fileName: fileName
        )
    }
}
