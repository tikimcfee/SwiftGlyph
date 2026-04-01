//
//  CameraCommandHandler.swift
//  SwiftGlyph
//
//  Created by Ivan Lugo on 2026-03-31.
//

import Foundation
import simd
import MetalLink

// MARK: - camera.move

/// Moves the debug camera by a relative offset.
///
/// Usage: `camera.move <dx> <dy> <dz>`
///
/// All three components are required. Values are in world-space units
/// and are applied through `DebugCamera.moveCameraLocation`, which
/// respects the current camera rotation.
public struct CameraMoveHandler: CommandHandler {
    public let name = "camera.move"

    public func execute(args: [String], context: CommandContext) async -> CommandResult {
        guard args.count >= 3,
              let dx = Float(args[0]),
              let dy = Float(args[1]),
              let dz = Float(args[2])
        else {
            return .error("Usage: camera.move <dx> <dy> <dz>")
        }

        let camera = GlobalInstances.debugCamera
        camera.moveCameraLocation(dx, dy, dz)

        return .ok(
            message: "Camera moved by (\(dx), \(dy), \(dz))",
            payload: [
                "x": "\(camera.position.x)",
                "y": "\(camera.position.y)",
                "z": "\(camera.position.z)",
            ]
        )
    }
}

// MARK: - camera.focus

/// Moves the camera to look at a specific world position.
///
/// Usage: `camera.focus <x> <y> <z>`
///
/// Sets the camera position directly. A future iteration may compute
/// an orbit position that keeps the target centered.
public struct CameraFocusHandler: CommandHandler {
    public let name = "camera.focus"

    public func execute(args: [String], context: CommandContext) async -> CommandResult {
        guard args.count >= 3,
              let x = Float(args[0]),
              let y = Float(args[1]),
              let z = Float(args[2])
        else {
            return .error("Usage: camera.focus <x> <y> <z>")
        }

        let camera = GlobalInstances.debugCamera
        camera.position = LFloat3(x, y, z)

        return .ok(
            message: "Camera focused at (\(x), \(y), \(z))",
            payload: [
                "x": "\(x)",
                "y": "\(y)",
                "z": "\(z)",
            ]
        )
    }
}

// MARK: - camera.reset

/// Resets the camera to the origin with zero rotation.
///
/// Usage: `camera.reset`
public struct CameraResetHandler: CommandHandler {
    public let name = "camera.reset"

    public func execute(args: [String], context: CommandContext) async -> CommandResult {
        let camera = GlobalInstances.debugCamera
        camera.position = .zero
        camera.rotation = .zero

        return .ok(message: "Camera reset to origin")
    }
}

// MARK: - camera.orbit

/// Adjusts camera rotation (orbit angles).
///
/// Usage: `camera.orbit <pitch> <yaw> [roll]`
///
/// Angles are in radians. Roll defaults to 0 if omitted.
public struct CameraOrbitHandler: CommandHandler {
    public let name = "camera.orbit"

    public func execute(args: [String], context: CommandContext) async -> CommandResult {
        guard args.count >= 2,
              let pitch = Float(args[0]),
              let yaw = Float(args[1])
        else {
            return .error("Usage: camera.orbit <pitch> <yaw> [roll]")
        }

        let roll = args.count >= 3 ? Float(args[2]) ?? 0 : 0
        let camera = GlobalInstances.debugCamera
        camera.rotation = LFloat3(pitch, yaw, roll)

        return .ok(
            message: "Camera orbit set to pitch=\(pitch), yaw=\(yaw), roll=\(roll)",
            payload: [
                "pitch": "\(pitch)",
                "yaw": "\(yaw)",
                "roll": "\(roll)",
            ]
        )
    }
}
