//
//  Structures.swift
//
//  Created by Ivan Lugo on 10/5/21.
//

import Foundation

public struct CodableAutoCache<Key: Hashable & Codable, Value: Codable>: Codable {
    var source = [Key: Value]()
    mutating func retrieve(
        key: Key,
        defaulting: @autoclosure () -> Value
    ) -> Value {
        source[key] ?? {
            let new = defaulting()
            source[key] = new
            return new
        }()
    }
}


public struct AutoCache<Key: Hashable, Value> {
    var source = [Key: Value]()
    mutating func retrieve(
        key: Key,
        defaulting: @autoclosure () -> Value
    ) -> Value {
        source[key] ?? {
            let new = defaulting()
            source[key] = new
            return new
        }()
    }
}

public class LList<NodeValue>: Sequence {
    typealias Node = LNode<NodeValue>
    
    private var head: Node?
    private var tail: Node?
    
    func removeAll() {
        head = nil
        tail = nil
    }
    
    func append(_ value: NodeValue) {
        listAppend(LNode(value))
    }
    
    private func listAppend(_ node: Node) {
        if head == nil {
            head = node
        }
        tail?.next = node
        tail = node
    }
    
    public func makeIterator() -> LLIterator {
        LLIterator(pointer: head)
    }
}

public extension LList {
    struct LLIterator: IteratorProtocol {
        var pointer: Node?
        var lastNodeOnEmpty: Node?
        
        public mutating func next() -> NodeValue? {
            if pointer == nil && lastNodeOnEmpty?.next != nil {
                pointer = lastNodeOnEmpty?.next
                lastNodeOnEmpty = nil
            }
            if let pointer = pointer, pointer.next == nil {
                lastNodeOnEmpty = pointer
            }
            
            let currentElement = pointer?.element
            pointer = pointer?.next
            
            return currentElement
        }
    }
}

public class LNode<Element> {
    typealias Node = LNode<Element>
    var element: Element?
    var next: Node?
    init(_ element: Element) {
        self.element = element
    }
}
