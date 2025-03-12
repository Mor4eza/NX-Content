//
//  DownloadItem.swift
//  NX-Content
//
import Foundation
import SwiftData

@Model
final class DownloadItem {
    var gameId: String
    var url: String
    var fileName: String
    var fileSize: Int
    var downloadedBytes: Int
    var isPaused: Bool
    var isCompleted: Bool
    var createdAt: Date
    
    init(gameId: String, url: String, fileName: String, fileSize: Int, downloadedBytes: Int = 0, isPaused: Bool = false, isCompleted: Bool = false) {
        self.gameId = gameId
        self.url = url
        self.fileName = fileName
        self.fileSize = fileSize
        self.downloadedBytes = downloadedBytes
        self.isPaused = isPaused
        self.isCompleted = isCompleted
        self.createdAt = Date()
    }
}