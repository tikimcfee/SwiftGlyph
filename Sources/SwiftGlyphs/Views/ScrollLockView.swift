//
//  File.swift
//  
//
//  Created by Ivan Lugo on 8/17/24.
//

import SwiftUI
import BitHandling
import MetalLink

struct ScrollLockView: View {
    @State var searchScrollLock = Set<ScrollLock>()
    
    var body: some View {
        HStack {
            scrollLocks
        }
        .onChange(of: searchScrollLock) { oldValue, newValue in
            GlobalInstances.debugCamera.scrollLock = newValue
        }
    }
    
    var scrollLocks: some View {
        VStack {
            Text("Camera Lock")
            HStack {
                ForEach(ScrollLock.allCases) {
                    scrollToggleButton($0)
                }
            }
        }
        .padding()
        .border(.gray)
    }
    
    func scrollToggleButton(_ lock: ScrollLock) -> some View {
        Button(
            action: {
                _ = searchScrollLock.toggle(lock)
            },
            label: {
                Label(
                    lock.rawValue,
                    systemImage: lock.systemImageName
                )
                .foregroundStyle(
                    searchScrollLock.contains(lock)
                        ? Color.green
                        : Color.primary
                )
            }
        )
    }
}
