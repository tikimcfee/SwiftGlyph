//
//  Content.swift
//  SwiftGlyph
//
//  Created by Ivan Lugo on 11/17/24.
//


import SwiftUI
import BitHandling
import MetalLink

public class InstructionsController: ObservableObject {
    let firstImageName = 1
    let lastImageName = 16
    lazy var range = firstImageName...lastImageName
    
    lazy var coreImages = range.map {
        ($0, NSUIImage(named: "\($0)"))
    }

    lazy var imageModels = coreImages.compactMap { id, image in
        image.map { ImageModel(id: id, image: $0) }
    }
    
    struct ImageModel: Identifiable {
        let id: Int
        let image: NSUIImage
    }
}

public extension Image {
    init(platformImage: NSUIImage) {
#if os(iOS)
        self.init(uiImage: platformImage)
#else
        self.init(nsImage: platformImage)
#endif
    }
}

extension InstructionsController.ImageModel {
    struct Content {
        let title: String
        let messages: [(Int, String)]
        
        init(
            _ title: String,
            _ messages: String...
        ) {
            self.title = title
            self.messages = Array(messages.enumerated())
        }
    }
    
    var content: Content {
        switch id {
        case 1:
                .init(
                    "Main Screen",
                    "The app will open with a default view.",
                    "Windows can be popped out, docked, or hidden."
                )
        case 2:
                .init(
                    "Basic Usage",
                    "Docked windows can be moved and resized.",
                    "A compact overlay sidebar is available for core controls."
                )
        case 4:
                .init(
                    "Windows",
                    "Most controls can be undocked as a separate panel.",
                    "These work like any other platform window."
                )
        case 5:
                .init(
                    "Docked Panels",
                    "Most controls can be docked to overlay in the main window."
                )
        case 6:
                .init(
                    "Settings - Clearing Cache",
                    "Render something weird? Experiment with fonts?",
                    "Clear and Preload to return to defaults."
                )
        case 7:
                .init(
                    "Settings - CodeGrids",
                    "Text is rendered in grid glyphs - 'CodeGrids'.",
                    "RAM, CPU, and GPU usage have performance controls."
                )
        case 8:
                .init(
                    "Settings - Colorizing",
                    "If you choose to load Swift code, syntax can be colorized.",
                    "You can control the colors of general token types."
                )
        case 10:
                .init(
                    "Import Your Data",
                    "Use the GitHub panel to download any public repository by name or URL.",
                    "Use 'Open Folder' in the File Browser panel to select an existing directory."
                )
        case 11:
                .init(
                    "Render Your Data",
                    "The File Browser works in groups.",
                    "'Show All' renders, or hides, all enumerated content of a directory.",
                    "Control which files are rendered by default in Settings",
                    "Use the App Status panel to monitor rendering performance."
                )
        case 12:
                .init(
                    "Navigate Your Data",
                    "Use your touchpad, mouse, and keyboard to move your perspective around in 3D space.",
                    "Clicking and draging controls in which directions you look",
                    "Scrolling controls your position, and can be accelerated by holding 'Shift'",
                    "CodeGrids are interactive. Click one to bookmark it in the Focus panel"
                )
        case 13:
                .init(
                    "Data Paging (1 / 2)",
                    "Large files are truncated by default to conserve performance.",
                    "Your settings dictate how 'pages' render for each file.",
                    "Use the slider to change your active page..."
                )
        case 15:
                .init(
                    "Data Paging (2 / 2)",
                    "... and change the size of the page by change the value directly above.",
                    "This creates 'slices' of visible data.",
                    "You can increase the size of a 'slice' at cost of framerate."
                )
        case 16:
                .init(
                    "Multiple Windows and Controls",
                    "Setup a visualization layout, including a 2D text editor.",
                    "Panels are configurable and save their positions."
                )
        default:
                .init("Thanks for trying Glyph3D!")
        }
    }
}
