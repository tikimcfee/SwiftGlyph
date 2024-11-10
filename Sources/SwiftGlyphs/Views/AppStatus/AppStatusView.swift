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
        VStack {
            mainView
            List(status.history.reversed()) { progress in
                cell(progress)
                    .listRowInsets(.none)
                    .listRowBackground(Color.gray.opacity(progress.index % 2 == 0 ? 0.2 : 0.1))
            }
            .listStyle(.plain)
        }
        .padding(8)
    }
    
    @ViewBuilder
    func cell(_ progress: AppStatus.AppProgress) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text(progress.title)
                    .font(.subheadline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .italic()
                Spacer()
                Text("\(progress.index)")
                    .font(.subheadline)
                    .italic()
            }

            if !progress.message.isEmpty {
                Text(progress.message)
                    .font(.subheadline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading)
            }

        }
        .padding(4)
    }
    
    @ViewBuilder
    var mainView: some View {
        VStack(alignment: .leading) {
            VStack (alignment: .leading) {
                Text(statusText)
                    .font(.headline)
                    .frame(alignment: .leading)
                
                Text(status.progress.title)
                    .font(.subheadline)
                    .frame(alignment: .leading)
            }
            
            clampedProgressViewLabel
            
            Text(status.progress.message)
                .lineLimit(1, reservesSpace: true)

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
        "a b c d e f",
        "g h i j k l",
    ]
    
    static var status: AppStatus {
        let status = AppStatus()
        status.update {
            $0.currentValue = 0
            $0.isActive = true
            $0.message = "Loading grids..."
            $0.totalValue = 15
        }

        QuickLooper(
            interval: .milliseconds(500),
            loop: {
                status.update {
                    $0.currentValue += 1
                    $0.message = testSubDetails.randomElement()!
                    $0.title = testDetails.randomElement()!
                }
//                
//                if status.progress.index > 100 {
//                    status.resetProgress()
//                }
            }
        ).runUntil(
            onStop: {
                status.update {
                    $0.message = "Done!"
                    $0.currentValue = $0.totalValue
                    $0.isActive = false
                }
            },
            stopIf: {
                status.progress.index > 5000
            }
        )
        
        return status
    }
    static var previews: some View {
        VStack {
            AppStatusView(status: status)
        }
    }
}
