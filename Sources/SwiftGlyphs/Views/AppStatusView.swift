//
//  AppStatusView.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 6/10/22.
//

import SwiftUI
import BitHandling

public struct AppStatusView: View {
    @ObservedObject var status: AppStatus
    
    public init(status: AppStatus) {
        self.status = status
    }
    
    public var body: some View {
        mainView
            .padding()
    }
    
    var statusText: String {
        status.progress.isReportedProgressActive
             ? "AppStatus: active, reported"
             : status.progress.isActive
             ? "AppStatus: active, flag"
             : "AppStatus: not active"
    }
    
    @ViewBuilder
    var mainView: some View {
        VStack(alignment: .leading) {
            Text(statusText)
                .font(.headline)
            
            Text(status.progress.message)
                .font(.subheadline)
            
            Spacer().frame(height: 8)
            
            Text(status.progress.detail)
            
            if status.progress.isActive {
                clampedProgressViewLabel
                progressLabel
                    .padding(.bottom)
            }
            
            Divider()
        }
    }
    
    @ViewBuilder
    var clampedProgressViewLabel: some View {
        let (safeValue, safeTotal) = (
            min(status.progress.currentValue, status.progress.totalValue),
            max(status.progress.currentValue, status.progress.totalValue)
        )
        
        VStack {
            ProgressView(
                value: safeValue,
                total: safeTotal,
                label: { EmptyView() }
            )
        }
    }
    
    @ViewBuilder
    var progressLabel: some View {
        Text("\(status.progress.roundedCurrent) / \(status.progress.roundedTotal)")
    }
}

public class AppStatus: ObservableObject {
    public struct AppProgress {
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
    
    @Published private(set) var progress = AppProgress()
    @Published private(set) var history = [AppProgress]()
    
    func update(_ receiver: @escaping (inout AppProgress) -> Void) {
        DispatchQueue.main.async {
            var current = self.progress
            receiver(&current)
            self.progress = current
            
            self.history = self.history.suffix(24) + [current]
        }
    }
    
    func resetProgress() {
        DispatchQueue.main.async {
            self.progress = AppProgress()
        }
    }
}

struct AppStatusView_Previews: PreviewProvider {
    static let testDetails = [
        "Reticulating splines...",
        "Burrowing stash...",
        "Executing order 33...",
        "Building bridges...",
        "Burning built bridges...",
        "Repairing bridges...",
        "Attoning for sins...",
        "Supplying rebels with supplies...",
        "Narfling the Garthok..."
    ]
    
    static var status: AppStatus {
        let status = AppStatus()
        status.update {
            $0.currentValue = 0
            $0.isActive = true
            $0.message = "Loading grids..."
            $0.totalValue = 15
        }

        status.update { _ in
            QuickLooper(
                interval: .milliseconds(1000),
                loop: {
                    status.update {
                        $0.currentValue += 1
                        $0.detail = testDetails.randomElement()!
                    }
                }
            ).runUntil(
                onStop: {
                    status.update {
                        $0.message = "Done!"
                        $0.currentValue = $0.totalValue
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) {
                        status.update {
                            $0.isActive = false
                        }
                    }
                },
                stopIf: {
                    status.progress.currentValue >= status.progress.totalValue
                }
            )
        }
        
        return status
    }
    static var previews: some View {
        VStack {
            AppStatusView(status: status)
            Button("Lol Some big stuff ") { }
        }
    }
}
