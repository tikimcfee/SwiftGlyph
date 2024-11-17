import SwiftUI
import MetalLink
import BitHandling
import STTextViewSwiftUI

struct ResizableLeftPanelView<Content: View>: View {
    enum LayoutMode {
        case vertical, horizontal
    }

    @State private var sizes: [CGFloat]
    @State private var setInitial = false

    @ObservedObject var panelState = GlobalInstances.appPanelState
    @ObservedObject var fileBrowserState = GlobalInstances.fileBrowserState
    
    var layoutMode: LayoutMode
    let content: () -> [Content]

    // Constants
    private let minHeight: CGFloat = 50
    private let minWidth: CGFloat = 100
    private let dividerThickness: CGFloat = 8

    init(layoutMode: LayoutMode, content: @escaping () -> [Content]) {
        self.layoutMode = layoutMode
        self._sizes = State(initialValue: [])
        self.content = content
    }

    var body: some View {
        GeometryReader { geometry in
            if layoutMode == .horizontal {
                HStack(spacing: 0) {
                    ForEach(Array(content().enumerated()), id: \.offset) { index, view in
                        if index > 0 {
                            dividerHorizontal(geometry: geometry, index: index)
                        }
                        view.frame(width: sizes[safe: index] ?? defaultWidth(geometry))
                    }
                }
                .onAppear {
                    guard !setInitial else { return }
                    setInitial = true
                    initializeSizes(count: content().count, totalLength: geometry.size.width)
                }
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(content().enumerated()), id: \.offset) { index, view in
                        if index > 0 {
                            dividerVertical(geometry: geometry, index: index)
                        }
                        view.frame(height: sizes[safe: index] ?? defaultHeight(geometry))
                    }
                }
                .onAppear {
                    guard !setInitial else { return }
                    setInitial = true
                    initializeSizes(count: content().count, totalLength: geometry.size.height)
                }
            }
        }
    }

    // Helpers for initialization
    private func initializeSizes(count: Int, totalLength: CGFloat) {
        sizes = Array(repeating: totalLength / CGFloat(count), count: count)
    }

    private func defaultWidth(_ geometry: GeometryProxy) -> CGFloat {
        geometry.size.width / CGFloat(content().count)
    }

    private func defaultHeight(_ geometry: GeometryProxy) -> CGFloat {
        geometry.size.height / CGFloat(content().count)
    }

    // Dividers
    func dividerVertical(geometry: GeometryProxy, index: Int) -> some View {
        DividerView(isForVerticalStack: true)
            .frame(height: dividerThickness)
            .gesture(verticalDragGesture(geometry: geometry, index: index))
            .onHoverCursor(NSCursor.resizeUpDown)
    }

    func dividerHorizontal(geometry: GeometryProxy, index: Int) -> some View {
        DividerView(isForVerticalStack: false)
            .frame(width: dividerThickness)
            .gesture(horizontalDragGesture(geometry: geometry, index: index))
            .onHoverCursor(NSCursor.resizeLeftRight)
    }

    // Drag Gestures for resizing
    private func verticalDragGesture(geometry: GeometryProxy, index: Int) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                adjustSizeForVerticalDrag(value.translation.height, index: index)
            }
    }

    private func horizontalDragGesture(geometry: GeometryProxy, index: Int) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                adjustSizeForHorizontalDrag(value.translation.width, index: index)
            }
    }

    // Resizing logic
    private func adjustSizeForVerticalDrag(_ translation: CGFloat, index: Int) {
        guard index > 0, index < sizes.count else { return }
        let newSize = sizes[index - 1] + translation
        let nextSize = sizes[index] - translation
        if newSize > minHeight, nextSize > minHeight {
            sizes[index - 1] = newSize
            sizes[index] = nextSize
        }
    }

    private func adjustSizeForHorizontalDrag(_ translation: CGFloat, index: Int) {
        guard index > 0, index < sizes.count else { return }
        let newSize = sizes[index - 1] + translation
        let nextSize = sizes[index] - translation
        if newSize > minWidth, nextSize > minWidth {
            sizes[index - 1] = newSize
            sizes[index] = nextSize
        }
    }
}

#Preview {
    ResizableLeftPanelView(layoutMode: .vertical) {
        [
            FileBrowserView(browserState: GlobalInstances.fileBrowserState, setMin: false)
                .eraseToAnyView(),
            AppWindowTogglesView(state: GlobalInstances.appPanelState)
                .eraseToAnyView(),
            AppStatusView(status: GlobalInstances.appStatus)
                .eraseToAnyView()
        ]
    }
    .frame(height: 800)
}

extension View {
    func eraseToAnyView() -> AnyView {
        AnyView(self)
    }

    func onHoverCursor(_ cursor: NSCursor) -> some View {
        self.onHover { hovering in
            if hovering {
                cursor.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}

struct DividerView: View {
    let isForVerticalStack: Bool
    
    var body: some View {
        if isForVerticalStack {
            ZStack {
                Divider()
                    .background(Color.gray)
                Image(systemName: "line.3.horizontal")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            }
            
        } else {
            Divider()
                .background(Color.gray)
        }
    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
