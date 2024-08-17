//
//  File.swift
//  
//
//  Created by Ivan Lugo on 8/17/24.
//

import SwiftUI
import Combine
import BitHandling

struct EditPair: Equatable {
    let file: URL
    var input: AttributedString
}

class UserTextEditingStateHolder: ObservableObject {
    @Published var userTextInput = AttributedString("")
    @Published var userTextSelection: NSRange?
    @Published var userSelectedFile: URL?
    
    @Published private var editPairs: EditPair?
    
    private var bag = Set<AnyCancellable>()
    
    init() {
        bind()
    }
    
    private func bind() {
        $userSelectedFile
            .receive(on: WorkerPool.shared.nextWorker())
//            .throttle(
//                for: .milliseconds(300),
//                scheduler: WorkerPool.shared.nextWorker(),
//                latest: true
//            )
            .compactMap { $0 }
            .removeDuplicates()
            .compactMap { selectedFile in
                do {
                    let selectedFileText = try String(contentsOf: selectedFile)
                    let attributedContents = AttributedString(selectedFileText)
                    return EditPair(file: selectedFile, input: attributedContents)
                } catch {
                    print(error)
                    return nil
                }
            }
            .receive(on: DispatchQueue.main)
            .sink { pair in
                // TODO: Use a different editor. Lol.
                // Always update text selection when setting new content to ensure TextViewWrapper updates
                self.userTextSelection = .none
                self.userTextInput = pair.input
                self.editPairs = .init(file: pair.file, input: pair.input)
            }
            .store(in: &bag)
        
        $userTextInput
            .removeDuplicates()
            .sink { input in
                self.editPairs?.input = input
            }
            .store(in: &bag)
        
        $editPairs
            .debounce(
                for: .milliseconds(300),
                scheduler: WorkerPool.shared.nextWorker()
            )
            .compactMap { $0 }
            .removeDuplicates()
            .sink { pair in
                let (selectedFile, input) = (pair.file, pair.input)
                do {
                    let inputStagingFile = AppFiles.file(named: "inputStagingFile", in: AppFiles.glyphSceneDirectory)
                    let inputData = NSAttributedString(input).string
                    try inputData.write(
                        to: inputStagingFile,
                        atomically: true,
                        encoding: .utf8
                    )
                    
                    let currentFileContents = try Data(contentsOf: selectedFile, options: .alwaysMapped)
                    let newFileContents = try Data(contentsOf: inputStagingFile, options: .alwaysMapped)
                    
                    if currentFileContents != newFileContents {
                        try AppFiles.replace(fileUrl: selectedFile, with: inputStagingFile)
                    }
                } catch {
                    print(error)
                }
            }
            .store(in: &bag)
    }
}
