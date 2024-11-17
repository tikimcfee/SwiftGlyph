//
//  WorldFocusView.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 9/17/22.
//

import SwiftUI

public struct WorldFocusView: View {
    @ObservedObject var focus: WorldGridFocusController
    
    public init(focus: WorldGridFocusController) {
        self.focus = focus
    }
    
    public var body: some View {
        focusList
            .padding()
    }
    
    @ViewBuilder
    var focusList: some View {
        HStack {
            ScrollView {
                BookmarkListView()
            }
        }
    }
    
    func focusView() -> some View {
        ScrollView {
            VStack(alignment: .leading) {
                ForEach(focus.focusableGrids, id: \.targetGrid.id) { relationship in
                    HStack {
                        Text(relationship.direction.rawValue)
                        Spacer().frame(width: 32)
                        Text(relationship.targetGrid.fileName)
                    }
                    .padding()
                }
            }
        }
        .padding()
        .border(.gray, width: 1.0)
    }
}

struct WorldFocusView_Previews: PreviewProvider {
    static var testFocus: WorldGridFocusController {
        WorldGridFocusController(
            link: GlobalInstances.defaultLink,
            camera: GlobalInstances.debugCamera,
            editor: GlobalInstances.gridStore.editor
        )
    }
    
    static var previews: some View {
        WorldFocusView(
            focus: testFocus
        )
    }
}
