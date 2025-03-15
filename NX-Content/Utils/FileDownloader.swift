//
//  FileDownloader.swift
//  NX-Content
//
//  Created by Morteza on 3/8/25.
//

import Combine
import SwiftUI
import SwiftData

@MainActor
class DownloadManager: NSObject, ObservableObject {
    static let shared = DownloadManager()
    private var urlSession: URLSession!
    @Published var downloads: [DownloadItem] = []
    private var activeTasks: [String: URLSessionDownloadTask] = [:] // Store tasks separately
    
    override private init() {
        super.init()
        let config = URLSessionConfiguration.background(withIdentifier: "com.nxcontent.downloads")
        config.isDiscretionary = true
        config.sessionSendsLaunchEvents = true
        urlSession = URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }
    
    func startDownload(game: Game) {
        guard let urlString = game.downloadURL, let url = URL(string: urlString) else { return }
        
        let downloadItem = DownloadItem(gameId: game.id)
        downloads.append(downloadItem)
        
        let task = urlSession.downloadTask(with: url)
        task.resume()
        activeTasks[downloadItem.id] = task
        downloadItem.status = .downloading
    }
    
    func pauseDownload(_ item: DownloadItem) {
        guard let task = activeTasks[item.id] else { return }
        
        task.cancel(byProducingResumeData: { data in
            DispatchQueue.main.async {
                item.resumeData = data
                item.status = .paused
                self.activeTasks[item.id] = nil
            }
        })
    }
    
    func resumeDownload(_ item: DownloadItem) {
        guard let urlString = getGame(for: item)?.downloadURL else { return }
        
        if let resumeData = item.resumeData {
            let task = urlSession.downloadTask(withResumeData: resumeData)
            task.resume()
            activeTasks[item.id] = task
        } else {
            let task = urlSession.downloadTask(with: URL(string: urlString)!)
            task.resume()
            activeTasks[item.id] = task
        }
        
        item.status = .downloading
    }
    
    private func getGame(for item: DownloadItem) -> Game? {
        let gameId = item.gameId
        let context = Persistence.shared.container.mainContext
        let descriptor = FetchDescriptor<Game>(predicate: #Predicate { $0.id == gameId })
        return try? context.fetch(descriptor).first
    }
}

extension DownloadManager: URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let item = downloads.first(where: { activeTasks[$0.id] == downloadTask }) else { return }
        
        // Save file to documents directory
        let docsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let destURL = docsURL.appendingPathComponent(location.lastPathComponent)
        
        do {
            try FileManager.default.moveItem(at: location, to: destURL)
            item.localFileURL = destURL
            item.status = .completed
            activeTasks[item.id] = nil
        } catch {
            item.status = .failed
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard let item = downloads.first(where: { activeTasks[$0.id] == downloadTask }) else { return }
        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        item.progress = progress
    }
}
