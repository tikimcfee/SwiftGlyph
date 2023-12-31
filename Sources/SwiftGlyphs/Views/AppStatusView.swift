//
//  AppStatusView.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 6/10/22.
//

import SwiftUI

public struct AppStatusView: View {
    @ObservedObject var status: AppStatus
    
    public init(status: AppStatus) {
        self.status = status
    }
    
    public var body: some View {
        mainView
            .padding()
            .frame(width: 640.0)
    }
    
    @ViewBuilder
    var mainView: some View {
        VStack {
            Text(status.progress.isReportedProgressActive
                 ? "AppStatus: active, reported"
                 : status.progress.isActive
                 ? "AppStatus: active, flag"
                 : "AppStatus: not active")
            
            if status.progress.isActive {
                clampedProgressViewLabel
            } else {
                progressLabel
            }
            
            Divider()
            
            HStack {
                Button("Save Glyph Atlas") {
                    GlobalInstances.defaultAtlas.save()
                }
                
                Button("Load glyph Atlas") {
                    GlobalInstances.defaultAtlas.load()
                }
            }
        }
    }
    
    @ViewBuilder
    var clampedProgressViewLabel: some View {
        let (safeValue, safeTotal) = (
            min(status.progress.currentValue, status.progress.totalValue),
            max(status.progress.currentValue, status.progress.totalValue)
        )
        ProgressView(
            value: safeValue,
            total: safeTotal,
            label: { progressLabel }
        )
    }
    
    @ViewBuilder
    var progressLabel: some View {
        HStack(alignment: .lastTextBaseline) {
            VStack(alignment: .leading) {
                Text(status.progress.message)
                Text("\(status.progress.roundedCurrent) / \(status.progress.roundedTotal)")
            }
            Spacer()
            Text(status.progress.detail)
        }
    }
}

public class AppStatus: ObservableObject {
    public struct AppProgress {
        var message: String = ""
        var detail: String = ""
        var totalValue: Double = 0
        var currentValue: Double = 0
        var isActive: Bool = false
        var isReportedProgressActive: Bool { currentValue < totalValue }
        
        var roundedTotal: Int { Int(totalValue) }
        var roundedCurrent: Int { Int(currentValue) }
    }
    
    @Published private(set) var progress = AppProgress()
    
    func update(_ receiver: @escaping (inout AppProgress) -> Void) {
        DispatchQueue.main.async {
            var current = self.progress
            receiver(&current)
            self.progress = current
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
            $0.isActive = true
            $0.message = "Loading grids..."
            $0.totalValue = 15
        }

        QuickLooper(
            interval: .milliseconds(100),
            loop: {
                status.update {
                    $0.currentValue += 1
                    $0.detail = testDetails.randomElement()!
                }
            }
        ).runUntil(onStop: {
            status.update { $0.message = "Done!" }
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) {
                status.update { $0.isActive = false }
            }
        }) {
            status.progress.currentValue >= status.progress.totalValue
        }
        return status
    }
    static var previews: some View {
        AppStatusView(status: status)
    }
}
