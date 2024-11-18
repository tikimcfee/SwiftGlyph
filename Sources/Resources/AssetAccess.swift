//  
//
//  Created on 12/16/23.
//  

import SwiftUI

private extension String {
    var assetColor: Color {
        Color(self, bundle: .module)
    }
}

private enum ColorName: String {
    case primaryForeground
    case primaryBackground
    case primarySGButtonBackground
    case secondaryBackground
    
    var assetColor: Color {
        rawValue.assetColor
    }
}

public extension Color {
    static var primaryForeground         = ColorName.primaryForeground.assetColor
    static var primaryBackground         = ColorName.primaryBackground.assetColor
    static var primarySGButtonBackground = ColorName.primarySGButtonBackground.assetColor
    
    static var secondaryBackground       = ColorName.secondaryBackground.assetColor
}
