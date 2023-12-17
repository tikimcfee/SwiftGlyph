//  
//
//  Created on 12/16/23.
//  

import SwiftUI

struct ProgressWrapperView: View {
    var progress: Progress?

    var body: some View {
        if let progress {
            VStack(alignment: .leading) {
                if progress.isCancelled {
                    isCancelledView
                } else if progress.isFinished {
                    isFinishedView
                } else {
                    progressView(progress)
                        .onAppear {
                            print(progress)
                        }
                }
            }
        }
    }
    
    var isCancelledView: some View {
        Text("Cancelled")
            .font(.headline)
    }
    
    var isFinishedView: some View {
        Text("Done!")
            .font(.headline)
    }
    
    @ViewBuilder
    func progressView(_ progress: Progress) -> some View {
        ProgressView(value: progress.fractionCompleted)
            .progressViewStyle(LinearProgressViewStyle(tint: .blue))
        
        HStack(alignment: .top) {
            VStack(alignment: .leading) {
                if progress.completedUnitCount > 0 {
                    HStack {
                        Text("Completed Units:")
                        Text("\(progress.completedUnitCount)")
                    }
                }
                
                if progress.totalUnitCount > 0 {
                    HStack {
                        Text("Total:")
                        Text("\(progress.totalUnitCount)")
                    }
                }
            }.layoutPriority(1)
            
            if progress.fractionCompleted > 0 {
                HStack {
                    Spacer()
                    Text(String(format: "%.2f%%", progress.fractionCompleted * 100))
                }
            }
        }
    }
}
