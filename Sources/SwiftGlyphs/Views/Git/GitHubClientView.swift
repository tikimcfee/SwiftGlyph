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
            .padding()
            .background(Color.primaryBackground)
            .onReceive(clientState.$progress) { progress in
                self.progress = progress
            }
            #if os(macOS)
            .frame(maxWidth: 800, maxHeight: 480)
            #endif
    }
    
#if os(iOS)
    @ViewBuilder
    var rootBodyView: some View {
        VStack(alignment: .leading) {
            repoListView
            repoInfoCaptureView
                .border(.gray, width: 1.0)
            repoDownloadStateView
            if let progress = clientState.progress {
                ProgressWrapperView(progress: progress)
            }
        }
    }
#elseif os(macOS)
    @ViewBuilder
    var rootBodyView: some View {
        HStack(alignment: .top) {
            VStack {
                repoInfoCaptureView
                repoDownloadStateView
                
                ProgressWrapperView(progress: progress)
                    .id(UUID()) // SwiftUI doesn't like `progress` equality checks
            }
            repoListView
        }
    }
#endif
    
    @ViewBuilder
    var repoInfoCaptureView: some View {
        VStack(alignment: .leading) {
            Text("Repository Download")
            TextField("Name", text: $clientState.repoName)
            TextField("Owner", text: $clientState.owner)
            TextField("Branch (optional)", text: $clientState.branch)
        }
    }
    
    @ViewBuilder
    var repoDownloadStateView: some View {
        VStack {
            if let task = clientState.progressTask {
                Button("Cancel") {
                    task.cancel()
                }
            } else {
                Button("Download Repo") {
                    clientState.doRepositoryDownload()
                }
                .disabled(!clientState.enabled)
                .buttonStyle(.bordered)
            }
            
            if let error = clientState.error {
                VStack {
                    Text("Download error")
                    Text("\(error.localizedDescription)")
                        .lineLimit(32)
                        .frame(maxWidth: 240)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .foregroundColor(.red)
            }
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
        return state
    }()
    
    static var previews: some View {
        VStack {
            GitHubClientView(clientState: sampleState)
        }
            
    }
}
#endif
