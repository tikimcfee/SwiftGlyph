//
//  Instructions.swift
//  SwiftGlyph
//
//  Created by Ivan Lugo on 11/17/24.
//

import SwiftUI
import BitHandling
import MetalLink

public class InstructionsImages: ObservableObject {
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
    @StateObject var instructions = InstructionsImages()
    
    @State private var currentPage = 0
    @Environment(\.presentationMode) var presentationMode
    
    public var body: some View {
        VStack {
            PagerView(
                pageCount: instructions.imageModels.count,
                currentIndex: $currentPage
            ) {
                ForEach(instructions.imageModels) { imageModel in
                    Image(platformImage: imageModel.image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .tag(imageModel.id)
                }
            }
            .padding()
            
            if currentPage == instructions.imageModels.count - 1 {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Done")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding(.top, 20)
            }
            
            PageControl(
                currentPage: $currentPage,
                numberOfPages: instructions.imageModels.count
            )
            .padding(.top, 10)
            
        }
        .padding()
    }
}

struct PageControl: View {
    @Binding var currentPage: Int
    let numberOfPages: Int
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<numberOfPages, id: \ .self) { index in
                Circle()
                    .frame(width: 20, height: 20)
                    .contentShape(Rectangle())
                    .foregroundColor(index == currentPage ? .blue : .gray)
                    .onTapGesture {
                        currentPage = index
                    }
            }
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
                        withAnimation(.easeInOut(duration: 0.167)){
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
