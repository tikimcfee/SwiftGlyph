//
//  GitHubClientView.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 6/1/22.
//

import SwiftUI
import Combine
import BitHandling

public struct GitHubClientView: View {
    
    @StateObject var clientState: GitHubClientViewState
    @State var progress: Progress?
    
    public init(
        clientState: GitHubClientViewState = GitHubClientViewState()
    ) {
        self._clientState = StateObject(wrappedValue: clientState)
    }
    
    @ViewBuilder
    public var body: some View {
        rootBodyView
            .background(Color.primaryBackground)
            .onReceive(clientState.$progress) { progress in
                self.progress = progress
            }
    }
    
#if os(iOS)
    @ViewBuilder
    var rootBodyView: some View {
        repoListView
            .overlay(alignment: .bottomTrailing) {
                Button("Download") {
                    clientState.showDownloadView = true
                }
                .buttonStyle(.bordered)
                .padding()
            }
            .sheet(isPresented: $clientState.showDownloadView) {
                VStack(alignment: .trailing, spacing: 16) {
                    repoInfoCaptureView
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    if let progress = progress {
                        ProgressWrapperView(progress: progress)
                            .background(Color.primaryBackground.opacity(0.5))
                            .id(UUID()) // SwiftUI doesn't like `progress` equality checks
                    }
                    
                    repoDownloadButtonView

                    repoDownloadErrorView
                }
                .padding()
                .presentationDetents([.medium])
                .interactiveDismissDisabled(progress != nil)
                .presentationDragIndicator(.visible)
                .background(Color.primaryBackground)
            }
    }
#elseif os(macOS)
    @ViewBuilder
    var rootBodyView: some View {
        HStack(alignment: .top) {
            VStack {
                repoInfoCaptureView
                
                ProgressWrapperView(progress: progress)
                    .id(UUID()) // SwiftUI doesn't like `progress` equality checks
            }
            repoListView
        }
        .frame(maxWidth: 800, maxHeight: 480)
    }
#endif
    
    @ViewBuilder
    var repoInfoCaptureView: some View {
        VStack(alignment: .leading) {
            TextField("GitHub Repository", text: $clientState.repoName)
                .padding()
                .lineLimit(1)
                .autocorrectionDisabled()
                .underline(clientState.repoName.isEmpty)
            
            TextField("Owner Name", text: $clientState.owner)
                .padding()
                .lineLimit(1)
                .autocorrectionDisabled()
                .underline(clientState.owner.isEmpty)
            
            TextField("Branch (optional)", text: $clientState.branch)
                .padding()
                .lineLimit(1)
                .autocorrectionDisabled()
                .underline(clientState.branch.isEmpty)
        }
        .foregroundStyle(Color.primaryForeground)
    }
    
    @ViewBuilder
    var repoDownloadButtonView: some View {
        if clientState.progressTask != nil {
            Button("Cancel") {
                clientState.resetDownload()
            }
            .buttonStyle(.bordered)
            .foregroundColor(.red)
        } else {
            Button("Download Repo") {
                clientState.doRepositoryDownload()
            }
            .disabled(!clientState.enabled)
            .buttonStyle(.bordered)
        }
    }
    
    @ViewBuilder
    var repoDownloadErrorView: some View {
        if let error = clientState.error {
            Text("\(error.localizedDescription)")
                .lineLimit(2, reservesSpace: true)
                .frame(maxWidth: .infinity, alignment: .center)
                .foregroundColor(.red)
        }
    }
    
    @ViewBuilder
    var repoListView: some View {
        List {
            ForEach(clientState.repoUrls, id: \.path) { url in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        let nameSuffix = url.pathComponents.suffix(2)
                        let name = nameSuffix.first ?? "<wut>"
                        let repo = nameSuffix.last ?? "<how>"
                        Text(repo)
                            .bold()
                        Text(name)
                            .font(.caption)
                            .italic()
                    }
                    Spacer()
                    Button(
                        action: { clientState.deleteURL(url) },
                        label: {
                            Image(systemName: "x.square.fill")
                                .renderingMode(.template)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 20)
                                .foregroundStyle(.red.opacity(0.75))
                        }
                    )
                    .buttonStyle(.plain)
                }
                .padding(8)
                .background(Color.gray.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .onTapGesture { onRepositoryUrlSelected(url) }
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 8, leading: 8, bottom: 0, trailing: 8))
                .listRowBackground(Color.clear)
            }
        }
        .listStyle(.plain)
    }
    
    func onRepositoryUrlSelected(_ url: URL) {
        GlobalInstances
            .fileBrowser
            .setRootScope(url)
    }
}

#if DEBUG
struct GitHubClientView_Preview: PreviewProvider {
    static let sampleState: GitHubClientViewState = {
        let state = GitHubClientViewState()
        state.repoUrls = [
            URL(fileURLWithPath: "/var/users/some-lib/Bill/ACoolName"),
            URL(fileURLWithPath: "/var/users/some-lib/Bob/A Very Lengthy Name with Stuff"),
            URL(fileURLWithPath: "/var/users/some-lib/DannyFrank/liblol")
        ]
        
//        state.progressTask = URLSessionDownloadTask()
//        state.progressTask?.progress.totalUnitCount = 64
//        state.progressTask?.progress.completedUnitCount = 31
//        state.progressTask?.progress.fileTotalCount = 33
//        state.progressTask?.progress.fileCompletedCount = 99
//        state.progressTask?.progress.estimatedTimeRemaining = 1000
//        state.progress = state.progressTask?.progress
//        state.error = NSError(domain: "Wut", code: 3)
        
        return state
    }()
    
    static var previews: some View {
        VStack {
            GitHubClientView(clientState: sampleState)
                .padding()
        }
            
    }
}
#endif
