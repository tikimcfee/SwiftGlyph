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
    let textWidth = 320.0
    
    public init(status: AppStatus) {
        self.status = status
    }
    
    public var body: some View {
        ScrollView {
            mainView
        }
    }
    
    @ViewBuilder
    var mainView: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .top) {
                VStack (alignment: .leading) {
                    Text(statusText)
                        .font(.headline)
                        .frame(alignment: .leading)
                    
                    Text(status.progress.message)
                        .font(.subheadline)
                        .frame(alignment: .leading)
                        .lineLimit(2, reservesSpace: true)
                }
            }
            
            clampedProgressViewLabel
            
            Text(status.progress.detail)
            
            countView
        }
        
    }
    
    @ViewBuilder
    var countView: some View {
        Text(
            String(format: "%.f/%.f",
                    status.progress.currentValue,
                    status.progress.totalValue)
        )
        .font(.subheadline)
        .lineLimit(1, reservesSpace: true)
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
            label: { EmptyView() }
        )
        .labelsHidden()
        .opacity(status.progress.isActive ? 1 : 0)
    }
}

extension AppStatusView {
    var statusText: String {
        status.progress.isReportedProgressActive
             ? "AppStatus: active, reported"
             : status.progress.isActive
             ? "AppStatus: active, flag"
             : "AppStatus: not active"
    }
}

private extension View {
    func disableAnimation(_ shouldDisable: Bool) -> some View {
        transaction {
            if shouldDisable {
                $0.animation = nil
            }
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
    
    static let testSubDetails = [
        "A once of the dunce can munch lunch",
        "Sometimes the things do",
        "How come but like maybe how",
        "Did you ever see the did",
        "Whenever you can you can",
        "Whenever can you can you",
        "Fun fun bun bun",
        "If you apply a long series of glyphs into a line and then separate the glyphs with not glyphs you end up with words and then you if you use the same glyphs and spaces over and over again sometimes the words becomes real.",
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
                interval: .milliseconds(100),
                loop: {
                    status.update {
                        $0.currentValue += 1
                        $0.message = testSubDetails.randomElement()!
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
        }
    }
}
