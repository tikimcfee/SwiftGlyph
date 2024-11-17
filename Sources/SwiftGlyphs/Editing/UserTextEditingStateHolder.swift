//
//  File.swift
//  
//
//  Created by Ivan Lugo on 8/17/24.
//

import SwiftUI
import Combine
import BitHandling
import MetalLink

public struct EditPair: Equatable {
    let selectedFile: URL
    var userInput: AttributedString
}

public struct WatchPair: Equatable {
    let sourceURL: URL
    let sourceData: Data
    let string: String
}

public typealias Watcher = MappingFileWatcher<WatchPair>

public class UserTextEditingStateHolder: ObservableObject {
    private let link: MetalLink
    
    @Published var userTextInput = AttributedString("")
    @Published var userTextSelection: NSRange?
    @Published var userSelectedGrid: CodeGrid?
    
    @Published private var editPairs: EditPair?
    @Published public private(set) var watchData: Data?
    
    private var fileWatcher: Watcher?
    private var bag = Set<AnyCancellable>()
    
    public init(
        link: MetalLink
    ) {
        self.link = link
        
        bind()
    }
    
    private func bind() {
        $userSelectedGrid
//            .throttle(
//                for: .milliseconds(300),
//                scheduler: WorkerPool.shared.nextWorker(),
//                latest: true
//            )
            .compactMap { $0?.sourcePath }
            .removeDuplicates()
            .receive(on: WorkerPool.shared.nextWorker())
            .compactMap { selectedFile in
                do {
                    let selectedFileText = try String(contentsOf: selectedFile)
                    let attributedContents = self.__demo_TerminalAttributedString(selectedFileText)
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
        
//        $userTextSelection
//            .removeDuplicates()
//            .compactMap { $0 }
//            .combineLatest($userSelectedGrid.compactMap { $0 })
//            .sink { selection, grid in
//                let new = selection.location
//                let (count, pointer) = grid.rootNode.instancePointerPair
//                guard new > 0 && new < count else { return }
//                
//                GlobalInstances
//                    .defaultLink
//                    .glyphPickingTexture
//                    .currentHover = pointer[new].instanceID
//            }
//            .store(in: &bag)
            
        $editPairs
            .throttle(
                for: .milliseconds(16),
                scheduler: WorkerPool.shared.nextWorker(),
                latest: true
            )
            .receive(on: WorkerPool.shared.nextWorker())
            .compactMap { $0 }
            .removeDuplicates()
            .sink { pair in
                self.onEditPairChanged(pair)
            }
            .store(in: &bag)
    }
    
    func onEditPairChanged(_ pair: EditPair) {
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
                try AppFiles.oneTimeBackupOf(fileUrl: selectedFile, with: inputStagingFile)
                
                DispatchQueue.main.async {
                    self.watchData = newFileContents
                }
            }
        } catch {
            print(error)
        }
    }
}

private extension UserTextEditingStateHolder {
    func __demo_TerminalAttributedString(
        _ text: String
    ) -> AttributedString {
        AttributedString(
            text,
            attributes: .init([
                .foregroundColor: NSUIColor.white,
                .font: NSUIFont.monospacedSystemFont(ofSize: 14, weight: .regular)
            ])
        )
    }

    
    func restartFileWatcher(fileURL: URL) {
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
                self.onFileWatcherEvent(source: fileURL, $0)
            })
            
            fileWatcher = newWatcher
        } catch {
            print(error)
        }
    }
    
    func makeWatcher(
        fileURL: URL
    ) -> Watcher {
        MappingFileWatcher(
            path: fileURL.path(),
            refreshInterval: 1.0, // Refresh from FS slower than the throttle to avoid rewriting data
            pathReader: { url in
                let data = try Data(contentsOf: url)
                let selectedFileText = try String(contentsOf: url)
                return .init(
                    sourceURL: url,
                    sourceData: data,
                    string: selectedFileText
                )
            },
            differenceReader: { left, right in
                left != right
            }
        )
    }
    
    func onFileWatcherEvent(
        source: URL,
        _ result: Watcher.RefreshResult
    ) {
        switch result {
        case .noChanges:
            break
            
        case .updated(let result) where (
            result.string != NSAttributedString(userTextInput).string
            && watchData != result.sourceData
        ):
            print("- New string set")
            let attributedString = self.__demo_TerminalAttributedString(result.string)
            userTextInput = attributedString
            watchData = result.sourceData
            
        default:
            break
        }
    }
}
