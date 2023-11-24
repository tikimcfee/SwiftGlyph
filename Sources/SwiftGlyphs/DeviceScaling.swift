//
//  DeviceScaling.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 8/31/22.
//

#if os(OSX)
import AppKit
#elseif os(iOS)
import UIKit
#endif
import Foundation
import MetalLink

// MARK: -- Global Scaling Defaults --

public var DeviceScaleEnabled = false // Disabled because of switch to root geometry global scaling
public var DeviceScaleRootEnabled = true // Enabled by default to take advantage of global relative measurements within a node

#if os(iOS)
public let DeviceScaleRoot = Float(0.001)
public let DeviceScaleRootInverse = Float(1000.0)
public let DeviceScale = DeviceScaleEnabled ? Float(0.001) : 1.0
public let DeviceScaleInverse = DeviceScaleEnabled ? Float(1000.0) : 1.0
#elseif os(macOS)
public let DeviceScaleRoot = Float(1.0)
public let DeviceScaleRootInverse = Float(1.0)
public let DeviceScale = Float(1.0)
public let DeviceScaleInverse = Float(1.0)
#endif

public let DeviceScaleUnitVector = LFloat3(x: 1.0, y: 1.0, z: 1.0)

public let DeviceScaleVector = DeviceScaleEnabled
? LFloat3(x: DeviceScale, y: DeviceScale, z: DeviceScale)
: DeviceScaleUnitVector

public let DeviceScaleVectorInverse = DeviceScaleEnabled
? LFloat3(x: DeviceScaleInverse, y: DeviceScaleInverse, z: DeviceScaleInverse)
: DeviceScaleUnitVector

public let DeviceScaleRootVector = DeviceScaleRootEnabled
? LFloat3(x: DeviceScaleRoot, y: DeviceScaleRoot, z: DeviceScaleRoot)
: DeviceScaleUnitVector
