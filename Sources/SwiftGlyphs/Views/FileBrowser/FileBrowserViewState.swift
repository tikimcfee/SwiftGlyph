//
//  FileBrowserViewState.swift
//  SwiftGlyph
//
//  Created by Ivan Lugo on 10/27/24.
//


import Combine
import SwiftUI
import Foundation
import BitHandling

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
