//
//  File.swift
//  
//
//  Created by Ivan Lugo on 8/17/24.
//

import SwiftUI
import Combine
import BitHandling

public struct EditPair: Equatable {
    let selectedFile: URL
    var userInput: AttributedString
}

public struct WatchPair: Equatable {
    let sourceData: Data
    let attributedString: AttributedString
}

public typealias Watcher = MappingFileWatcher<WatchPair>

public class UserTextEditingStateHolder: ObservableObject {
    @Published var userTextInput = AttributedString("")
    @Published var userTextSelection: NSRange?
    @Published var userSelectedFile: URL?
    
    @Published private var editPairs: EditPair?
    @Published private var watchData: Data?
    
    private var fileWatcher: Watcher?
    private var bag = Set<AnyCancellable>()
    
    public init() {
        bind()
    }
    
    private func bind() {
        $userSelectedFile
//            .throttle(
//                for: .milliseconds(300),
//                scheduler: WorkerPool.shared.nextWorker(),
//                latest: true
//            )
            .compactMap { $0 }
            .removeDuplicates()
            .receive(on: WorkerPool.shared.nextWorker())
            .compactMap { selectedFile in
                do {
                    let selectedFileText = try String(contentsOf: selectedFile)
                    let attributedContents = AttributedString(
                        selectedFileText,
                        attributes: .init([.foregroundColor: NSUIColor.white])
                    )
                    return EditPair(selectedFile: selectedFile, userInput: attributedContents)
                } catch {
                    print(error)
                    return nil
                }
            }
            .receive(on: DispatchQueue.main)
            .sink { (pair: EditPair) in
                // TODO: Use a different editor. Lol.
                // Always update text selection when setting new content to ensure TextViewWrapper updates
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(50)) {
                    self.userTextSelection = .none
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) {
                    self.userTextInput = pair.userInput
                }
                
                
                self.restartFileWatcher(fileURL: pair.selectedFile)
                self.editPairs = pair
            }
            .store(in: &bag)
        
        $userTextInput
            .removeDuplicates()
            .sink { input in
                self.editPairs?.userInput = input
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
                let (selectedFile, input) = (pair.selectedFile, pair.userInput)
                do {
                    let inputStagingFile = AppFiles.file(
                        named: "inputStagingFile",
                        in: AppFiles.glyphSceneDirectory
                    )
                    let inputData = NSAttributedString(input).string
                    try inputData.write(
                        to: inputStagingFile,
                        atomically: true,
                        encoding: .utf8
                    )
                    
                    let currentFileContents = try Data(contentsOf: selectedFile, options: .alwaysMapped)
                    let newFileContents = try Data(contentsOf: inputStagingFile, options: .uncached)
                    
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

extension UserTextEditingStateHolder {
    private func restartFileWatcher(fileURL: URL) {
        do {
            if let fileWatcher {
                try fileWatcher.stop()
            }
            let newWatcher = makeWatcher(fileURL: fileURL)
            
            var droppedFirst = false
            try newWatcher.start(closure: {
                guard droppedFirst else {
                    droppedFirst = true
                    return
                }
                self.onFileWatcherEvent($0)
            })
            
            fileWatcher = newWatcher
        } catch {
            print(error)
        }
    }
    
    private func makeWatcher(
        fileURL: URL
    ) -> Watcher {
        MappingFileWatcher(
            path: fileURL.path(),
            pathReader: { url in
                let data = try Data(contentsOf: url)
                let selectedFileText = try String(contentsOf: url)
                let attributedString = AttributedString(
                    selectedFileText,
                    attributes: .init([.foregroundColor: NSUIColor.white])
                )
                return .init(sourceData: data, attributedString: attributedString)
            },
            differenceReader: { left, right in
                left != right
            }
        )
    }
    
    private func onFileWatcherEvent(
        _ result: Watcher.RefreshResult
    ) {
        switch result {
        case .noChanges:
            break
            
        case .updated(let result):
            print("- New string set")
            userTextInput = result.attributedString
            watchData = result.sourceData
        }
    }
}
