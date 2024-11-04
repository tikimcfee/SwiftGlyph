//
//  ScopeExtensions.swift
//  SwiftGlyph
//
//  Created by Ivan Lugo on 10/27/24.
//


import Combine
import SwiftUI
import Foundation
import BitHandling

extension FileBrowser.Scope {
    var cachedGrid: CodeGrid? {
        GlobalInstances
            .gridStore
            .gridCache
            .get(path)
    }
    
    var isBookmarked: Bool {
        cachedGrid.map {
            GlobalInstances
                .gridStore
                .gridInteractionState
                .bookmarkedGrids
                .contains($0)
        } ?? false
    }
}



extension FileBrowser.Scope {
    var directoryStateIconName: String {
        switch self {
        case .file(_):
            ""
        case .directory(_):
            "chevron.right"
        case .expandedDirectory(_):
            "chevron.down"
        }
    }
    
    var mainIconName: String {
        switch self {
        case .file(_):
            "doc"
        case .directory(_):
            "folder"
        case .expandedDirectory(_):
            "folder.fill"
        }
    }
    
    var fontWeight: Font.Weight {
        switch self {
        case .file(_):
            .light
        case .directory(_):
            .regular
        case .expandedDirectory(_):
            .bold
        }
    }
}
