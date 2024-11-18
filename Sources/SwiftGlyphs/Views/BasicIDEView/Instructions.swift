//
//  Instructions.swift
//  SwiftGlyph
//
//  Created by Ivan Lugo on 11/17/24.
//

import SwiftUI
import BitHandling
import MetalLink

public class InstructionsController: ObservableObject {
    let firstImageName = 1
    let lastImageName = 16
    lazy var range = firstImageName...lastImageName
    
    var imageIterator: ClosedRange<Int>.Iterator { range.makeIterator() }
    var coreImages: [NSUIImage] { imageIterator.compactMap { NSUIImage(named: "\($0)") } }
    lazy var imageModels = coreImages.enumerated().map { ImageModel(id: $0, image: $1) }
    
    struct ImageModel: Identifiable {
        let id: Int
        let image: NSUIImage
    }
}

public extension Image {
    init(platformImage: NSUIImage) {
#if os(iOS)
        self.init(uiImage: platformImage)
#else
        self.init(nsImage: platformImage)
#endif
    }
}

public struct InstructionsView: View {
    @StateObject var instructions = InstructionsController()
    
    @State private var currentPage = 0
    @Environment(\.dismiss) var dismiss
    
    public var body: some View {
        content
            .frame(width: 1024, height: 800)
    }
    
    public var content: some View {
        ZStack {
            Color.secondaryBackground
            
            VStack {
                PagerView(
                    pageCount: instructions.imageModels.count,
                    currentIndex: $currentPage
                ) {
                    ForEach(instructions.imageModels) { imageModel in
                        ZStack {
                            Color.secondaryBackground
                            
                            Image(platformImage: imageModel.image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .zIndex(Double(imageModel.id))
                                .tag(imageModel.id)
                        }
                    }
                }
                .padding()
                
                Button(action: {
                    dismiss()
                }) {
                    Text("Start Rendering")
                        .padding()
                        .background(Color.primaryBackground)
                        .foregroundColor(Color.primaryForeground)
                        .cornerRadius(8)
                        .contentShape(Rectangle())
                }
                .padding(.top, 20)
                .buttonStyle(.plain)
                
                PageControl(
                    currentPage: $currentPage,
                    numberOfPages: instructions.imageModels.count
                )
                .padding(.vertical, 10)
            }
        }
    }
}

struct PageControl: View {
    @Binding var currentPage: Int
    let numberOfPages: Int
    
    var body: some View {
        HStack(spacing: 8) {
            Button(
                action: {
                    withAnimation {
                        currentPage = max(0, currentPage - 1)
                    }
                },
                label: {
                    Image(systemName: "chevron.left")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(8)
                        .frame(width: 40, height: 40)
                        .background(Color.primaryBackground)
                        .foregroundStyle(Color.primaryForeground)
                        .clipShape(Circle())
                }
            )
            .buttonStyle(.plain)
            
            
            ForEach(0..<numberOfPages, id: \ .self) { index in
                Circle()
                    .frame(width: 20, height: 20)
                    .contentShape(Rectangle())
                    .foregroundColor(index == currentPage ? .blue : .gray)
                    .onTapGesture {
                        currentPage = index
                    }
            }
            
            Button(
                action: {
                    withAnimation {
                        currentPage = min(numberOfPages - 1, currentPage + 1)
                    }
                },
                label: {
                    Image(systemName: "chevron.right")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(8)
                        .frame(width: 40, height: 40)
                        .background(Color.primaryBackground)
                        .foregroundStyle(Color.primaryForeground)
                        .clipShape(Circle())
                }
            )
            .buttonStyle(.plain)
        }
    }
}

struct PagerView<Content: View>: View {
    let pageCount: Int
    @Binding var currentIndex: Int
    let content: () -> Content
    
    @GestureState private var dragOffset: CGFloat = 0
    
    init(
        pageCount: Int,
        currentIndex: Binding<Int>,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.pageCount = pageCount
        self._currentIndex = currentIndex
        self.content = content
    }
    
    var body: some View {
        GeometryReader { geometry in
            LazyHStack(spacing: 0) {
                content()
                    .frame(width: geometry.size.width)
            }
            .contentShape(Rectangle())
            .offset(x: -CGFloat(currentIndex) * geometry.size.width + dragOffset)
            .animation(.easeInOut(duration: 0.167), value: dragOffset)
            .gesture(
                DragGesture()
                    .updating($dragOffset) { value, state, _ in
                        state = value.translation.width
                    }
                    .onEnded { value in
                        withAnimation(.easeInOut(duration: 0.167)) {
                            let threshold = geometry.size.width / 5
                            if value.translation.width > threshold {
                                currentIndex = max(currentIndex - 1, 0)
                            } else if value.translation.width < -threshold {
                                currentIndex = min(currentIndex + 1, pageCount - 1)
                            }
                        }
                    }
            )
        }
    }
}

struct InstructionsView_Previews: PreviewProvider {
    static var previews: some View {
        InstructionsView()
    }
}
