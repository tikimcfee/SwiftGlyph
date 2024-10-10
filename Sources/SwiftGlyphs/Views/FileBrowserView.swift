//
//  FileBrowserView.swift
//  LookAtThatMobile
//
//  Created by Ivan Lugo on 12/10/21.
//

import Combine
import SwiftUI
import Foundation
import BitHandling

let FileIcon = "📄"
let FocusIcon = "👁️‍🗨️"
let AddToOriginIcon = "🌐"
let DirectoryIconCollapsed = "􀆊"
let DirectoryIconExpanded = "􀆈"

extension FileBrowserView {
    var fileBrowser: FileBrowser {
        GlobalInstances.fileBrowser
    }
    
    func pathDepths(_ scope: FileBrowser.Scope) -> Int {
        fileBrowser.distanceToRoot(scope)
    }
}

public class FileBrowserViewState: ObservableObject {
    @Published public var files: FileBrowserView.RowType = []
    @Published public var filterText: String = ""
    
    private var selectedfiles: FileBrowserView.RowType = []
    private var bag = Set<AnyCancellable>()
    
    public init() {
        GlobalInstances.fileStream
            .subscribe(on: DispatchQueue.global())
            .receive(on: DispatchQueue.main)
            .sink { [weak self] selectedScopes in
                guard let self = self else { return }
                self.selectedfiles = selectedScopes
                self.files = self.filter(files: selectedScopes)
            }
            .store(in: &bag)
        
        $filterText.receive(on: DispatchQueue.main).sink { [weak self] _ in
            guard let self = self else { return }
            self.files = self.filter(files: self.selectedfiles)
        }.store(in: &bag)
    }
    
    public func filter(files: [FileBrowser.Scope]) -> [FileBrowser.Scope] {
        guard !filterText.isEmpty else { return files }
        return files.filter {
            $0.path.fileName.fuzzyMatch(filterText)
        }
    }
}

public struct FileBrowserView: View {
    
    public typealias RowType = [FileBrowser.Scope]
    @StateObject var browserState = FileBrowserViewState()
    @State var hoveredScope: FileBrowser.Scope? = .none
    func isHovered(_ scope: FileBrowser.Scope) -> Bool {
        hoveredScope == scope
    }
    
    public init(
        browserState: FileBrowserViewState
    ) {
        self._browserState = StateObject(wrappedValue: browserState)
    }
    
    public var body: some View {
        rootView
            .padding(4.0)
            .frame(
                minWidth: 256.0,
                maxWidth: 400.0,
                maxHeight: 768.0,
                alignment: .leading
            )
    }
    
    var rootView: some View {
        VStack(alignment: .leading) {
            fileRows(browserState.files)
            Spacer()
            searchInput
        }
    }
    
    
    var searchInput: some View {
        TextField(
            "🔍 Find",
            text: $browserState.filterText
        )
    }
    
    @ViewBuilder
    func fileRows(_ rows: RowType) -> some View {
        ScrollView {
            LazyVStack(spacing: 4) {
                ForEach(rows) { scope in
                    HStack(spacing: 0) {
                        makeSpacer(pathDepths(scope))
                        rowForScope(scope)
                    }
                    .background(hoveredScope == scope ? .blue.opacity(0.05) : .clear)
                    .onHover { isHovering in
                        if isHovering {
                            hoveredScope = scope
                        } else if hoveredScope == scope {
                            hoveredScope = nil
                        }
                    }
                }
            }
        }
    }
}

private extension FileBrowserView {
    
    @ViewBuilder
    func rowForScope(_ scope: FileBrowser.Scope) -> some View {
        switch scope {
        case let .file(path):
            fileView(scope, path)
                .background(Color.gray.opacity(0.001))
                .onTapGesture {
                    genericSelection(.newSingleCommand(path, .focusOnExistingGrid))
                }
        case let .directory(path):
            directoryView(scope, path)
                .background(Color.gray.opacity(0.001))
                .onTapGesture {
                    fileScopeSelected(scope)
                }
        case let .expandedDirectory(path):
            expandedDirectoryView(scope, path)
                .background(Color.gray.opacity(0.001))
                .onTapGesture {
                    fileScopeSelected(scope)
                }
        }
    }
    
    @ViewBuilder
    func makeSpacer(_ depth: Int?) -> some View {
        if let depth {
            if depth == 0 {
                EmptyView()
            } else {
                Spacer()
                    .frame(width: depth.cg * 8.0)
            }
        }
    }
    
    @ViewBuilder
    func fileView(_ scope: FileBrowser.Scope, _ path: URL) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "doc")
                .renderingMode(.template)
                .aspectRatio(contentMode: .fit)
                .font(.footnote)
                .padding(1)
                .padding(.leading, 12)
            Text(path.lastPathComponent)
                .fontWeight(.light)
            Spacer()
        }
    }
    
    @ViewBuilder
    func directoryView(_ scope: FileBrowser.Scope, _ path: URL) -> some View {
        HStack(spacing: 2) {
            Text(DirectoryIconCollapsed)
                .font(.footnote)
                .frame(width: 12)
            
            Image(systemName: "folder")
                .renderingMode(.template)
                .aspectRatio(contentMode: .fit)
                .font(.footnote)
                .padding(1)
            
            Text(path.lastPathComponent)
            
            Spacer()
            
            if isHovered(scope) {
                showDirectoryButton(path)
            }
        }
    }
    
    @ViewBuilder
    func expandedDirectoryView(_ scope: FileBrowser.Scope, _ path: URL) -> some View {
        HStack(spacing: 2) {
            Text(DirectoryIconExpanded)
                .font(.footnote)
                .frame(width: 12)
            
            Image(systemName: "folder")
                .renderingMode(.template)
                .aspectRatio(contentMode: .fit)
                .font(.footnote)
                .padding(1)
            
            Text(path.lastPathComponent)
                .bold()
            
            Spacer()

            if isHovered(scope) {
                showDirectoryButton(path)
            }
        }
    }
    
    func showDirectoryButton(
        _ path: URL
    ) -> some View {
        Button(
            action: {
                genericSelection(
                    .newMultiCommandRecursiveAllLayout(path, .addToWorld)
                )
            },
            label: {
                Text("Show All")
                    .font(.caption2)
            }
        )
        .padding(.horizontal, 4)
        .padding(.vertical, 1)
        .background(
            RoundedRectangle(cornerRadius: 4.0)
                .foregroundColor(.blue.opacity(0.6))
        )
        .buttonStyle(.plain)
        #if os(macOS)
        .onLongPressGesture(perform: {
            NSPasteboard.general.declareTypes([.string], owner: nil)
            NSPasteboard.general.setString(path.path, forType: .string)
        })
        #endif
    }
}

extension FileBrowser.Scope {
    var cachedGrid: CodeGrid? {
        GlobalInstances
            .gridStore
            .gridCache
            .get(path)
    }
}

extension GridInteractionState {
    func isScopeBookmarked(_ scope: FileBrowser.Scope) -> Bool {
        scope.cachedGrid.map { cached in
            GlobalInstances
                .gridStore
                .gridInteractionState
                .bookmarkedGrids
                .contains(cached)
        } ?? false
    }
}

private extension FileBrowserView {
    func fileSelected(_ path: URL, _ selectType: FileBrowser.Event.SelectType) {
        GlobalInstances
            .fileBrowser
            .fileSelectionEvents = .newSingleCommand(path, selectType)
    }
    
    func fileScopeSelected(_ scope: FileBrowser.Scope) {
        GlobalInstances
            .fileBrowser
            .onScopeSelected(scope)
    }
    
    func genericSelection(_ action: FileBrowser.Event) {
        GlobalInstances
            .fileBrowser
            .fileSelectionEvents = action
    }
}

// MARK: RectangleDivider
struct RectangleDivider: View {
    let color: Color = .secondary.opacity(0.4)
    let height: CGFloat = 8.0
    let width: CGFloat = 2.0
    var body: some View {
        Text("﹂")
            .foregroundColor(color)
    }
}

#if DEBUG
struct FileBrowserView_Previews: PreviewProvider {
    
    static let testPaths: [FileBrowser.Scope] = [
        .directory(URL(fileURLWithPath: "/Users/lugo/localdev/viz")),
    ]
    
    static let testState: FileBrowserViewState = {
        let state = FileBrowserViewState()
//        state.files = testFiles
        return state
    }()
    
    static var previews: some View {
        FileBrowserView(browserState: testState)
            .onAppear {
                GlobalInstances.fileBrowser.setRootScope(testPaths[0].path)
            }
            .frame(width: 600, height: 600)
    }
}
#endif
