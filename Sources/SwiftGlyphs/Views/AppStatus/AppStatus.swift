//  
//
//  Created on 12/16/23.
//  

import SwiftUI
import BitHandling

public class AppStatus: ObservableObject {
    @Published private(set) var progress = AppProgress()
    @Published private(set) var history = [AppProgress]()
    
    func update(_ receiver: @escaping (inout AppProgress) -> Void) {
        DispatchQueue.main.async {
            var current = self.progress
            current.id = .init()
            receiver(&current)
            
            withAnimation(.easeOut(duration: GlobalLiveConfig.Default.uiAnimationDuration)) {
                self.progress = current
            }
            
            self.history = self.history.suffix(500) + [current]
        }
    }
    
    func resetProgress() {
        DispatchQueue.main.async {
            self.progress = AppProgress()
        }
    }
}

public extension AppStatus {
    struct AppProgress: Identifiable {
        public var id = UUID()
        var message: String = ""
        var detail: String = ""
        var totalValue: Double = 0
        var currentValue: Double = 0
        var isActive: Bool = false
        
        var isReportedProgressActive: Bool {
            currentValue < totalValue
        }
        
        var roundedTotal: Int {
            Int(totalValue)
        }
        
        var roundedCurrent: Int {
            Int(currentValue)
        }
    }
}
