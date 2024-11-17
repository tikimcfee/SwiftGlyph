//
//  FloatingControlsCombo.swift
//  SwiftGlyph
//
//  Created by Ivan Lugo on 11/16/24.
//


import SwiftUI
import MetalLink
import BitHandling
import STTextViewSwiftUI

public struct FloatingControlsCombo: View {
    @State var showWindowing: Bool
    @State var showControls = true
    
    let sections: [PanelSections]
    
    init(
        showWindowing initialWindowingState: Bool = true,
        sections: [PanelSections]
    ) {
        self.showWindowing = initialWindowingState
        self.sections = sections
    }
    
    public var body: some View {
        if showControls {
            AppControlPanelView(sections: sections)
        }
        
        FloatingControlsStack(
            showWindowing: $showWindowing,
            showControls: $showControls
        )
    }
}

public struct FloatingControlsStack: View {
    @Binding var showWindowing: Bool
    @Binding var showControls: Bool
    
    public var body: some View {
        VStack {
            Spacer()
            
            HStack {
                Spacer()
                
                VStack {
                    FABImage("macwindow.on.rectangle").opacity(
                        showWindowing ? 1.0 : 0.5
                    ).onTapGesture {
                        GlobalInstances.appPanelState.toggleWindowControlsVisible()
                        showWindowing = GlobalInstances.appPanelState.isVisible(.windowControls)
                    }.onLongPressGesture {
                        GlobalInstances.appPanelState.resetSection(.windowControls)
                    }
                    .onReceive(GlobalInstances.appPanelState.objectWillChange) {
                        showWindowing = GlobalInstances.appPanelState.isVisible(.windowControls)
                    }
                    
                    FABImage("wrench.and.screwdriver").opacity(
                        showControls ? 1.0 : 0.5
                    ).onTapGesture {
                        showControls.toggle()
                    }
                }
            }
        }
        .padding()
    }
}
