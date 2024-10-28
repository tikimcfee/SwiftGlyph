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
    var path: URL {
        switch self {
        case .file(let url),
             .directory(let url),
             .expandedDirectory(let url):
            return url
        }
    }

    var isFile: Bool {
        if case .file = self { return true }
        return false
    }

    var isDirectory: Bool {
        if case .directory = self { return true }
        return false
    }

    var isExpandedDirectory: Bool {
        if case .expandedDirectory = self { return true }
        return false
    }

    var isDirectoryType: Bool {
        isDirectory || isExpandedDirectory
    }
}

extension FileBrowser.Scope {
    var directoryStateIconName: String {
        switch self {
        case .file(_):
            ""
        case .directory(_):
            "􀆊"
        case .expandedDirectory(_):
            "􀆈"
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
