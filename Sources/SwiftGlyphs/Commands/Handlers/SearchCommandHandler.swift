//
//  SearchCommandHandler.swift
//  SwiftGlyph
//
//  Created by Ivan Lugo on 2026-03-31.
//

import Foundation

// MARK: - search.text

/// Searches for text across all grids using the existing SearchContainer.
///
/// Usage: `search.text <query>`
///
/// Dispatches the search to `GridStore.searchContainer` and returns
/// immediately with the query echoed. The actual search executes
/// asynchronously on a background queue; results surface through the
/// existing render task pipeline.
public struct SearchTextHandler: CommandHandler {
    public let name = "search.text"

    public func execute(args: [String], context: CommandContext) async -> CommandResult {
        let query = args.joined(separator: " ")
        guard !query.isEmpty else {
            return .error("Usage: search.text <query>")
        }

        let searchContainer = GlobalInstances.gridStore.searchContainer
        searchContainer.search(query) { _ in
            // Search results are consumed by the existing render pipeline.
            // No additional handling needed here.
        }

        return .ok(
            message: "Search started for: \(query)",
            payload: ["query": query]
        )
    }
}

// MARK: - search.clear

/// Clears the current search highlight / filter.
///
/// Usage: `search.clear`
///
/// Sends an empty search string to reset the render task.
public struct SearchClearHandler: CommandHandler {
    public let name = "search.clear"

    public func execute(args: [String], context: CommandContext) async -> CommandResult {
        let searchContainer = GlobalInstances.gridStore.searchContainer
        searchContainer.search("") { _ in }

        return .ok(message: "Search cleared")
    }
}
