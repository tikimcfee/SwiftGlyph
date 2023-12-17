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
    
    @Published var repoName: String = "" { didSet { evalInput() }}
    @Published var owner: String = "" { didSet { evalInput() }}
    @Published var branch: String = "" { didSet { evalInput() }}
    
    @Published var progressTask: URLSessionDownloadTask?
    @Published var progress: Progress?
    @Published var downloadArgs: GitHubClient.RepositoryZipArgs?
    
    @Published var error: Error?
    private lazy var session: URLSession = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
    
    override public init() {
        super.init()
        self.repoUrls = AppFiles.allDownloadedRepositories
        self.evalInput()
    }
    
    private func evalInput() {
        enabled = !(
            repoName.isEmpty
            || owner.isEmpty
        )
    }
    
    func doRepositoryDownload() {
        guard enabled else { return }
        enabled = false
        
        let repoFileDownloadTarget = AppFiles
            .githubRepositoriesRoot
            .appendingPathComponent(repoName, isDirectory: true)
        
        let args = GitHubClient.RepositoryZipArgs(
            owner: owner,
            repo: repoName,
            branchRef: branch,
            unzippedResultTargetUrl: repoFileDownloadTarget
        )
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
    
    private func onRepositoryDownloaded(_ downloadResult: Result<URL, Error>) {
        switch downloadResult {
        case .success(let url):
            print("Retrieved URL: \(url)")
            self.repoUrls.append(url)
            
        case .failure(let error):
            self.error = error
        }
        
        self.enabled = true
        self.downloadArgs = nil
        self.progress = nil
        self.progressTask = nil
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
            self.onRepositoryDownloaded(
                .failure(error)
            )
        }
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        print("xxxx")
    }
}
