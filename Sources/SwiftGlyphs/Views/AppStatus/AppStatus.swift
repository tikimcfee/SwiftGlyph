//  
//
//  Created on 12/16/23.
//  

import SwiftUI
import BitHandling

public class AppStatus: ObservableObject {
    public let limit = 500
    
    private(set) var progress = AppProgress()
    private(set) var history = [AppProgress]()
    
    private let updateQueue = DispatchQueue(label: "AppStatusQueue", qos: .utility)
    
    func update(_ receiver: @escaping (inout AppProgress) -> Void) {
        updateQueue.async {
            var current = AppProgress()
            current.currentValue = self.progress.currentValue
            current.totalValue = self.progress.totalValue
            current.isActive = self.progress.isActive
            current.index = self.progress.index + 1
            receiver(&current)

            let newHistory = Array(self.history.suffix(self.limit) + [current])
            
            self.post()
            self.progress = current
            self.history = newHistory
        }
    }
    
    func post() {
        DispatchQueue.main.async {
            withAnimation(.easeOut(duration: GlobalLiveConfig.store.preference.uiAnimationDuration.double)) {
                self.objectWillChange.send()
            }
        }
    }
    
    func resetProgress() {
        updateQueue.async {
            self.post()
            self.progress = AppProgress()
        }
    }
}

public extension AppStatus {
    struct AppProgress: Identifiable {
        public var id = UUID()
        public var index = 0
        
        var message: String = ""
        var title: String = ""
        
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
