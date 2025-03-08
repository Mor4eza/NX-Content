//
//  GameListView.swift
//  NX-Content
//
//  Created by Morteza on 3/8/25.
//

import SwiftUI

struct GameListView: View {
    @StateObject private var viewModel = ViewModel()
    
    var body: some View {
        VStack {
            if viewModel.isLoading {
                ProgressView("Downloading Game List...")
            } else if let errorMessage = viewModel.errorMessage {
                Text("Error: \(errorMessage)")
                    .foregroundColor(.red)
            } else if !viewModel.games.isEmpty {
                List(viewModel.games) { game in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(game.gameName)
                            .font(.headline)
                        Text("Version: \(game.version)")
                            .font(.subheadline)
                        Text("Size: \(game.formattedSize)") // Use formattedSize
                            .font(.subheadline)
                    }
                }
            } else if viewModel.showDownloadButton {
                Button(action: {
                    viewModel.downloadAndParseJSON()
                }) {
                    Text("Download Games Title")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            } else {
                Text("No data available")
            }
        }
        .padding()
        .onAppear {
            viewModel.checkLocalFile() // Check for local file when the view appears
        }
    }
}

#Preview {
    GameListView()
}
