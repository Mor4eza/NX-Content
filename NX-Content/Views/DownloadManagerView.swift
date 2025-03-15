//
//  DownloadManagerView.swift
//  NX-Content
//
//  Created by Morteza on 3/12/25.
//


import SwiftUI

struct DownloadManagerView: View {
    @EnvironmentObject private var downloadManager: DownloadManager
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(downloadManager.downloads) { item in
                    DownloadItemView(item: item)
                }
            }
            .navigationTitle("Downloads")
            .overlay {
                if downloadManager.downloads.isEmpty {
                    ContentUnavailableView("No Active Downloads", systemImage: "arrow.down.circle")
                }
            }
        }
    }
}

struct DownloadItemView: View {
    @Bindable var item: DownloadItem // Use @Bindable for SwiftData models
    @EnvironmentObject private var downloadManager: DownloadManager
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(item.gameId)
                    .font(.headline)
                ProgressView(value: item.progress)
                Text("\(Int(item.progress * 100))%")
                    .font(.caption)
            }
            
            Spacer()
            
            switch item.status {
            case .downloading:
                Button("Pause") { downloadManager.pauseDownload(item) }
            case .paused:
                Button("Resume") { downloadManager.resumeDownload(item) }
            case .completed:
                if let url = item.localFileURL {
                    ShareLink(item: url) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            default:
                EmptyView()
            }
        }
    }
}
