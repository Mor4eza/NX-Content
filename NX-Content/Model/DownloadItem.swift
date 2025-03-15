//
//  DownloadItem.swift
//  NX-Content
//
import Foundation
import SwiftData

@Model
class DownloadItem: Identifiable {
    let id: String
    var gameId: String
    var localFileURL: URL?
    var progress: Double
    var status: DownloadStatus
    var resumeData: Data? // Store resume data instead of the task
    
    init(gameId: String) {
        self.id = UUID().uuidString
        self.gameId = gameId
        self.progress = 0.0
        self.status = .queued
    }
    
    enum DownloadStatus: String, Codable {
        case queued, downloading, paused, completed, failed
    }
}
