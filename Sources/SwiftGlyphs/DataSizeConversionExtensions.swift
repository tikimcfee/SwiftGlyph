//
//  ConversionExtensions.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 8/26/22.
//

import Foundation

public extension Int {
    var kb: Float { return Float(self) / 1024 }
    var mb: Float { return kb / 1024 }
}

public extension Data {
    var kb: Float { return Float(count) / 1024 }
    var mb: Float { return kb / 1024 }
    var nsData: NSData { return self as NSData }
}

public extension NSData {
    var kb: Float { return Float(count) / 1024 }
    var mb: Float { return kb / 1024 }
    var swiftData: Data { return self as Data }
}
