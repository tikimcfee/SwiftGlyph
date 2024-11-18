//
//  Instructions.swift
//  SwiftGlyph
//
//  Created by Ivan Lugo on 11/17/24.
//

import SwiftUI
import BitHandling
import MetalLink

public struct InstructionsView: View {
    @StateObject var instructions = InstructionsController()
    
    @State private var currentPage = 0
    @Environment(\.dismiss) var dismiss
    
    public var body: some View {
        content
            .frame(width: 1280, height: 960)
    }
    
    public var content: some View {
        ZStack {
            Color.primaryBackground
            
            VStack {
                PagerView(
                    pageCount: instructions.imageModels.count,
                    currentIndex: $currentPage
                ) {
                    ForEach(instructions.imageModels) { imageModel in
                        Page(imageModel: imageModel)
                    }
                }
                .padding()
                
                Divider()
                    .padding(.bottom)
                
                PageControl(
                    currentPage: $currentPage,
                    numberOfPages: instructions.imageModels.count
                )
                .padding(.vertical, 10)
            }
            
            dismissButtonGroup
        }
    }
    
    var dismissButtonGroup: some View {
        VStack {
            Spacer()
            
            HStack {
                Spacer()
                
                Button(action: {
                    dismiss()
                }) {
                    Text("Close Instructions")
                        .padding()
                        .background(Color.secondaryBackground)
                        .foregroundColor(Color.primaryForeground)
                        .cornerRadius(8)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
    }
}

struct Page: View {
    let imageModel: InstructionsController.ImageModel
    
    var body: some View {
        ZStack {
            Color.primaryBackground
            
            VStack {
                imageContent
                titleContent
                messageContent
            }
        }
    }
    
    var imageContent: some View {
        Image(platformImage: imageModel.image)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .zIndex(Double(imageModel.id))
            .tag(imageModel.id)
    }
    
    @ViewBuilder
    var titleContent: some View {
        Text(imageModel.content.title)
            .font(.title)
            .padding(.bottom)
    }
        
    @ViewBuilder
    var messageContent: some View {
        ForEach(imageModel.content.messages, id: \.0) { index, message in
            Text(message)
                .font(.title2)
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
                    .foregroundColor(
                        index == currentPage ? .blue : .gray
                    )
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
