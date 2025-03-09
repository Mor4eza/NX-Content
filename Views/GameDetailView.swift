//
//  GameDetailView.swift
//  NX-Content
//
//  Created by Morteza on 3/8/25.
//

import SwiftUI
import SDWebImageSwiftUI
import SwiftData

struct GameDetailView: View {
    let game: Game
    @StateObject private var viewModel = ViewModel(modelContext: ModelContext(Persistence.shared.container))
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let gameDetail = viewModel.gameDetail {
                    headerSection(gameDetail: gameDetail)
                    metadataSection(gameDetail: gameDetail)
                    screenshotsSection(gameDetail: gameDetail)
                    descriptionSection(gameDetail: gameDetail)
                } else if viewModel.isLoading {
                    ProgressView("Loading game details...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let errorMessage = viewModel.errorMessage {
                    ContentUnavailableView("Error", systemImage: "exclamationmark.triangle", description: Text(errorMessage))
                }
            }
            .padding()
        }
        .navigationTitle("Game Details")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.fetchGameDetails(gameID: game.id)
        }
    }
    
    // MARK: - Header Section
    private func headerSection(gameDetail: GameDetail) -> some View {
        HStack(spacing: 15) {
            WebImage(url: game.iconURL)
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .cornerRadius(12)
            
            VStack(alignment: .leading) {
                Text(game.gameName)
                    .font(.largeTitle.bold())
                
                HStack {
                    Text(game.version == "0" ? "Full Game" : "Demo")
                        .font(.subheadline)
                        .padding(.horizontal, 8)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(4)
                    
                    Text(game.formattedSize)
                        .font(.subheadline)
                }
            }
        }
    }
    
    // MARK: - Metadata Section
    private func metadataSection(gameDetail: GameDetail) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if let publisher = gameDetail.publisher {
                Text("Publisher: \(publisher)")
            }
            if let releaseDate = gameDetail.releaseDate {
                Text("Release Date: \(releaseDate)")
            }
            if let category = gameDetail.category {
                Text("Category: \(category.joined(separator: ", "))")
            }
            if let languages = gameDetail.languages {
                Text("Languages: \(languages.joined(separator: ", "))")
            }
            if let numberOfPlayers = gameDetail.numberOfPlayers {
                Text("Number of Players: \(numberOfPlayers)")
            }
        }
        .font(.subheadline)
    }
    
    // MARK: - Screenshots Section
    private func screenshotsSection(gameDetail: GameDetail) -> some View {
        Group {
            if let screenshots = gameDetail.screens?.screenshots, !screenshots.isEmpty {
                ScrollView(.horizontal) {
                    HStack(spacing: 10) {
                        ForEach(screenshots, id: \.self) { screenshot in
                            WebImage(url: URL(string: screenshot))
                                .resizable()
                                .scaledToFit()
                                .frame(height: 200)
                                .cornerRadius(10)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Description Section
    private func descriptionSection(gameDetail: GameDetail) -> some View {
        Group {
            if let description = gameDetail.description {
                Text(description)
                    .font(.body)
                    .lineLimit(nil)
            } else {
                EmptyView()
            }
        }
    }
   
}
