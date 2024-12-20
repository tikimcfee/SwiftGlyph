//  
//
//  Created on 12/16/23.
//  

import SwiftUI
import Combine
import BitHandling

public class GitHubClientViewState: NSObject, ObservableObject {
    @Published var repoUrls: [URL] = []
    
    @Published var enabled: Bool = true
    @Published var showDownloadView = false
    
    @Published var repoUrl: String = "" { didSet { evalInput() }}
    @Published var repoName: String = "" { didSet { evalInput() }}
    @Published var owner: String = "" { didSet { evalInput() }}
    @Published var branch: String = "" { didSet { evalInput() }}
    
    @Published var progressTask: URLSessionTask?
    @Published var progress: Progress?
    @Published var downloadArgs: GitHubClient.RepositoryZipArgs?
    
    @Published var error: Error?
    private lazy var session: URLSession = URLSession(
        configuration: .default,
        delegate: self,
        delegateQueue: nil
    )
    
    override public init() {
        super.init()
        self.repoUrls = AppFiles.allDownloadedRepositories
        self.evalInput()
    }
    
    private func evalInput() {
        enabled = !(
            repoName.isEmpty
            || owner.isEmpty
        )   || (
            !repoUrl.isEmpty
        )
    }
    
    func doRepositoryDownload() {
        guard enabled else { return }
        enabled = false
        
        let args = zipArgumentsFromRepoUrl() ?? zipArgumentsFromInput()
        self.downloadArgs = args
        
        let task = GitHubClient(session: session)
            .fetch(endpoint: .repositoryZip(args))
        self.progressTask = task
        self.progress = task.progress
        task.resume()
    }
    
    func deleteURL(_ url: URL) {
        guard let index = repoUrls.firstIndex(of: url) else {
            print("Man where did you get that that url from?")
            return
        }
        AppFiles.delete(fileUrl: url)
        repoUrls.remove(at: index)
    }
    
    func resetDownload() {
        progressTask?.cancel()
        progressTask = nil
        progress = nil
        downloadArgs = nil
        
        self.showDownloadView = false
        self.enabled = true
        self.downloadArgs = nil
        self.progress = nil
        self.progressTask = nil
    }
    
    private func onRepositoryDownloaded(_ downloadResult: Result<URL, Error>) {
        switch downloadResult {
        case .success(let url):
            print("Retrieved URL: \(url)")
            self.repoUrls.append(url)
            
        case .failure(let error):
            self.error = error
        }
        
        resetDownload()
    }
    
    private func zipArgumentsFromInput() -> GitHubClient.RepositoryZipArgs {
        let repoFileDownloadTarget = AppFiles
            .githubRepositoriesRoot
            .appendingPathComponent(repoName, isDirectory: true)
        
        return GitHubClient.RepositoryZipArgs(
            owner: owner,
            repo: repoName,
            branchRef: branch,
            unzippedResultTargetUrl: repoFileDownloadTarget
        )
    }
    
    private func zipArgumentsFromRepoUrl() -> GitHubClient.RepositoryZipArgs? {
        guard
            !repoUrl.isEmpty,
            let url = URL(string: repoUrl),
            url.host() == "github.com",
            url.pathComponents.count >= 3
        else {
            return nil
        }
        
        let urlRepoOwner = url.pathComponents[1]
        let urlRepoName = url.pathComponents[2]
        let urlBranch = url.pathComponents
            .dropFirst(4) // drop up to 'tree'
            .joined(separator: "/")
            .addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)
        
        let repoFileDownloadTarget = AppFiles
            .githubRepositoriesRoot
            .appendingPathComponent(urlRepoName, isDirectory: true)
        
        // LOOK AT `string.withUTF8`!!
        return .init(
            owner: urlRepoOwner,
            repo: urlRepoName,
            branchRef: urlBranch ?? "",
            unzippedResultTargetUrl: repoFileDownloadTarget
        )
    }
}

extension GitHubClientViewState: URLSessionDownloadDelegate {
    public func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        DispatchQueue.main.async {
            self.progressTask = downloadTask
            self.progress = downloadTask.progress
        }
    }
    
    public func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        print("Finished download and wrote to: \(location)")
        guard let downloadArgs else {
            print("Missing download args")
            return
        }
        
        do {
            try AppFiles.unzip(
                fileUrl: location,
                to: downloadArgs.unzippedResultTargetUrl
            )
            DispatchQueue.main.async {
                self.onRepositoryDownloaded(
                    .success(downloadArgs.unzippedResultTargetUrl)
                )
            }
        } catch {
            print("Failed during file io: \(error)")
            DispatchQueue.main.async {
                self.onRepositoryDownloaded(
                    .failure(error)
                )
            }
        }
    }
    
    public func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: Error?
    ) {
        print("- download complete callback, error: \(error?.localizedDescription ?? "<no error>")")
    }
}
