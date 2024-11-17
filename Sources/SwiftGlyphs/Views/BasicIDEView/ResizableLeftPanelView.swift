import SwiftUI
import MetalLink
import BitHandling
import STTextViewSwiftUI

struct ResizableLeftPanelView: View {
    enum LayoutMode {
        case vertical, horizontal
    }

    @State private var upperHeight: CGFloat = 500
    @State private var lowerHeight: CGFloat = 200
    @State private var leftWidth: CGFloat = 300
    @State private var rightWidth: CGFloat = 300
    @State private var setInitial = false

    @ObservedObject var panelState = GlobalInstances.appPanelState
    @ObservedObject var fileBrowserState = GlobalInstances.fileBrowserState
    
    var layoutMode: LayoutMode

    // Constants
    private let minHeight: CGFloat = 50
    private let minWidth: CGFloat = 100
    private let dividerThickness: CGFloat = 8

    var body: some View {
        GeometryReader { geometry in
            switch layoutMode {
            case .horizontal:
                HStack(spacing: 0) {
                    left
                    dividerLeft(geometry: geometry)
                    middleHorizontal(geometry: geometry)
                    dividerRight(geometry: geometry)
                    right
                }
                .onAppear {
                    guard !setInitial else { return }
                    setInitial = true
                    leftWidth = geometry.size.width / 4
                    rightWidth = geometry.size.width / 4
                }
            case .vertical:
                VStack(spacing: 0) {
                    top
                    dividerTop(geometry: geometry)
                    middleVertical(geometry: geometry)
                    dividerBottom(geometry: geometry)
                    bottom
                }
                .onAppear {
                    guard !setInitial else { return }
                    setInitial = true
                    upperHeight = geometry.size.height / 2
                    lowerHeight = geometry.size.height / 5
                }
            }
        }
    }

    // Vertical Layout Views
    var top: some View {
        FileBrowserView(browserState: fileBrowserState, setMin: false)
            .frame(height: upperHeight)
    }

    func middleVertical(geometry: GeometryProxy) -> some View {
        AppWindowTogglesView(state: panelState)
            .frame(height: geometry.size.height - upperHeight - lowerHeight)
    }

    var bottom: some View {
        AppStatusView(status: GlobalInstances.appStatus)
            .frame(height: lowerHeight)
    }

    // Horizontal Layout Views
    var left: some View {
        FileBrowserView(browserState: fileBrowserState, setMin: false)
            .frame(width: leftWidth)
    }

    func middleHorizontal(geometry: GeometryProxy) -> some View {
        AppWindowTogglesView(state: panelState)
            .frame(width: geometry.size.width - leftWidth - rightWidth)
    }

    var right: some View {
        AppStatusView(status: GlobalInstances.appStatus)
            .frame(width: rightWidth)
    }

    // Dividers for Vertical Layout
    func dividerTop(geometry: GeometryProxy) -> some View {
        ZStack {
            Divider()
                .background(Color.gray)
            Image(systemName: "line.3.horizontal")
                .resizable()
                .aspectRatio(contentMode: .fit)
        }
        .frame(height: dividerThickness)
        .contentShape(Rectangle())
        .gesture(topDragGesture(geometry: geometry))
        .onHover { hovering in
            if hovering {
                NSCursor.resizeUpDown.push()
            } else {
                NSCursor.pop()
            }
        }
    }

    func dividerBottom(geometry: GeometryProxy) -> some View {
        ZStack {
            Divider()
                .background(Color.gray)
            Image(systemName: "line.3.horizontal")
                .resizable()
                .aspectRatio(contentMode: .fit)
        }
        .frame(height: dividerThickness)
        .contentShape(Rectangle())
        .gesture(bottomDragGesture(geometry: geometry))
        .onHover { hovering in
            if hovering {
                NSCursor.resizeUpDown.push()
            } else {
                NSCursor.pop()
            }
        }
    }

    // Dividers for Horizontal Layout
    func dividerLeft(geometry: GeometryProxy) -> some View {
        Divider()
            .background(Color.gray)
            .frame(width: dividerThickness)
            .contentShape(Rectangle())
            .gesture(leftDragGesture(geometry: geometry))
            .onHover { hovering in
                if hovering {
                    NSCursor.resizeLeftRight.push()
                } else {
                    NSCursor.pop()
                }
            }
    }

    func dividerRight(geometry: GeometryProxy) -> some View {
        Divider()
            .background(Color.gray)
            .frame(width: dividerThickness)
            .contentShape(Rectangle())
            .gesture(rightDragGesture(geometry: geometry))
            .onHover { hovering in
                if hovering {
                    NSCursor.resizeLeftRight.push()
                } else {
                    NSCursor.pop()
                }
            }
    }

    // Drag Gestures for Vertical Layout
    private func topDragGesture(geometry: GeometryProxy) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                let totalHeight = geometry.size.height
                let newHeight = upperHeight + value.translation.height
                if newHeight > minHeight && (newHeight + lowerHeight) < totalHeight - minHeight {
                    upperHeight = newHeight
                }
            }
    }

    private func bottomDragGesture(geometry: GeometryProxy) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                let totalHeight = geometry.size.height
                let newHeight = lowerHeight - value.translation.height
                if newHeight > minHeight && (upperHeight + newHeight) < totalHeight - minHeight {
                    lowerHeight = newHeight
                }
            }
    }

    // Drag Gestures for Horizontal Layout
    private func leftDragGesture(geometry: GeometryProxy) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                let totalWidth = geometry.size.width
                let newWidth = leftWidth + value.translation.width
                if newWidth > minWidth && (newWidth + rightWidth) < totalWidth - minWidth {
                    leftWidth = newWidth
                }
            }
    }

    private func rightDragGesture(geometry: GeometryProxy) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                let totalWidth = geometry.size.width
                let newWidth = rightWidth - value.translation.width
                if newWidth > minWidth && (leftWidth + newWidth) < totalWidth - minWidth {
                    rightWidth = newWidth
                }
            }
    }
}

#Preview {
    ResizableLeftPanelView(layoutMode: .vertical)
        .frame(height: 800)
}
