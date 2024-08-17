//
//  File.swift
//  
//
//  Created by Ivan Lugo on 8/17/24.
//

import SwiftUI
import Combine
import BitHandling

class UserTextEditingStateHolder {
    struct Inputs {
        var userTextInput = AttributedString("")
        var userTextSelection: NSRange?
        var userSelectedFile: URL?
    }
    
    let userSelectedFileDataSubject = CurrentValueSubject<Data, Never>(Data())
    lazy var userSelectedFileDataBinding = Binding(
        get: { self.userSelectedFileDataSubject.value },
        set: { self.userSelectedFileDataSubject.send($0) }
    )
    
    let userTextInputSubject = CurrentValueSubject<Inputs, Never>(Inputs())
    lazy var userTextInputBinding = Binding(
        get: { self.userTextInputSubject.value },
        set: { self.userTextInputSubject.send($0) }
    )
    
    private var bag = Set<AnyCancellable>()
    
    init() {
        bind()
    }
    
    private func bind() {
        userTextInputSubject
            .receive(on: WorkerPool.shared.nextWorker())
//            .throttle(
//                for: .milliseconds(300),
//                scheduler: WorkerPool.shared.nextWorker(),
//                latest: true
//            )
            .compactMap { $0.userSelectedFile }
            .removeDuplicates()
            .sink { input in
                do {
                    let text = try String(contentsOf: input)
                    let attributedContents = AttributedString(text)
                    self.userTextInputSubject.value.userTextInput = attributedContents
                } catch {
                    print(error)
                }
//                do {
//                    let data = try Data(contentsOf: input)
//                    self.userSelectedFileDataSubject.send(data)
//                } catch {
//                    print(error)
//                }
            }
            .store(in: &bag)
    }
}
