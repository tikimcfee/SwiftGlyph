//
//  DictionaryController.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 2/17/23.
//

import Foundation
import MetalLink
import BitHandling

public class DictionaryController: ObservableObject {

    @Published public var dictionary = WordDictionary()
    @Published public var sortedDictionary = SortedDictionary()
    public var nodeController = GlobalNodeController()
    
    //    var nodeMap = [String: WordNode]()
    public var nodeMap = ConcurrentDictionary<String, WordNode>()
    public var lastLinkLine: MetalLinkLine?
    public var lastRootNode: MetalLinkNode? {
        didSet { nodeMap = .init() }
    }
    
    lazy var scale: Float = 120.0
    lazy var scaleVector = LFloat3(scale, scale, scale)
    lazy var scaleVectorNested = LFloat3(scale / 2.0, scale / 2.0, scale / 2.0)
    
    lazy var inverseScale: Float = pow(scale, -1)
    lazy var inverseScaleVector = LFloat3(1, 1, 1)
    
    lazy var rootNodePositionTranslation = LFloat3(0, 0, 16)
    lazy var inversePositionVector = LFloat3(0, 0, -16)
    
    lazy var colorVector = LFloat4(0.65, 0.30, 0.0, 0.0)
    lazy var colorVectorNested = LFloat4(-0.65, 0.55, 0.55, 0.0)
    
    lazy var focusedColor =    LFloat4(1.0, 0.0, 0.0, 0.0)
    lazy var ancestorColor =   LFloat4(0.0, 1.0, 0.0, 0.0)
    lazy var descendantColor = LFloat4(0.0, 0.0, 1.0, 0.0)
    
    public init() {

    }
    
    public var focusedWordNode: WordNode? {
        willSet {
            onWillSetFocusedWordNode(newValue)
        }
    }
    
    public func start() {
        openFile { file in
            switch file {
            case .success(let url):
                self.kickoffJsonLoad(url)
                
            case .failure(let error):
                print(error)
                break
            }
        }
    }
    
    public func start(with url: URL) {
        kickoffJsonLoad(url)
    }
    
    public func start(then action: @escaping () -> Void) {
        openFile { file in
            switch file {
            case .success(let url):
                self.kickoffJsonLoad(url)
                action()
                
            case .failure(let error):
                print(error)
                break
            }
        }
    }
    
    public func kickoffJsonLoad(_ url: URL) {
        if url.pathExtension == "wordnik" {
            let parsedDictionary = WordnikGameDictionary(from: url)
            let dictionary = WordDictionary(
                words: parsedDictionary.map
            )
            self.dictionary = dictionary
        } else {
            let dictionary = WordDictionary(file: url)
            self.dictionary = dictionary
        }
        self.sortedDictionary = SortedDictionary(dictionary: dictionary)
    }
    
    public func doWordChunking(using builder: CodeGridGlyphCollectionBuilder) {
        fatalError("you moved everything yo")
    }
}

public extension DictionaryController {
    class Styler {
        public enum Style {
            case rootWord
            case definitionDescendant(depth: Double)
        }
        
        lazy var rootNodeColor = LFloat4(1.0, 0.0, 0.0, 0.0)
        lazy var rootNodeScale = LFloat3(30.0, 30.0, 30.0)
        lazy var rootNodeTranslation = LFloat3(0, 0, 16)
        
        lazy var colors = ColorGenerator(maxColorCount: 500)
        lazy var depths: [WordNode: LFloat3] = [:]
        
        func focusWord(
            _ wordNode: WordNode,
            _ style: Style
        ) {
            switch style {
            case .rootWord:
                rootWord = wordNode
                
            case .definitionDescendant(_):
                break
            }
        }
        
        var rootWord: WordNode? {
            willSet {
                guard rootWord != newValue else { return }
                
                rootWord?.position -= rootNodeTranslation
                rootWord?.scale = .one
                newValue?.position += rootNodeTranslation
                newValue?.scale = .one
            }
        }
        
        func updateDepth(of word: WordNode, to depth: Float) {
            let lastUpdate = depths[word, default: .zero]
            guard lastUpdate.z != depth else { return }
            
            word.position -= lastUpdate
            word.position += LFloat3(0.0, 0.0, depth)
        }
    }
}

// MARK: - Focusing
extension DictionaryController {
    
    func onWillSetFocusedWordNode(_ newValue: WordNode?) {
        guard newValue != focusedWordNode else { return }
        
        if let focusedWordNode {
            defocusWord(focusedWordNode, defocusNested: true)
        }
        
        if let newValue {
            focusWord(newValue, focusNested: true)
        } else {
            if let rootNode = lastRootNode {
                if let lastLinkLine {
                    rootNode.remove(child: lastLinkLine)
                }
            }
        }
    }
    
    func focusWord(
        _ wordNode: WordNode,
        focusNested: Bool = false,
        isNested: Bool = false
    ) {
        wordNode.position
            .translateBy(dZ: self.rootNodePositionTranslation.z)
        
        wordNode.scale = isNested
            ? self.scaleVectorNested
            : self.scaleVector
        
        wordNode.glyphs.forEach { toUpdate in
            self.focusedColor.setAddedColor(on: &toUpdate.instanceConstants)
        }
    }
    
    func defocusWord(
        _ wordNode: WordNode,
        defocusNested: Bool = false,
        isNested: Bool = false
    ) {
        wordNode.position.translateBy(dZ: self.inversePositionVector.z)
        wordNode.scale = self.inverseScaleVector
        wordNode.glyphs.forEach { toUpdate in
            LFloat4.zero.setAddedColor(on: &toUpdate.instanceConstants)
        }
    }
}
