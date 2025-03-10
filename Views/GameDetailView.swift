//
//  GameDetailView.swift
//  NX-Content
//
//  Created by Morteza on 3/8/25.
//

import SDWebImageSwiftUI
import SwiftData
import SwiftUI

struct GameDetailView: View {
    let game: Game
    @StateObject private var viewModel = ViewModel(modelContext: ModelContext(Persistence.shared.container))
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let gameDetail = viewModel.gameDetail {
                    headerSection(gameDetail: gameDetail)
                    metadataSection(gameDetail: gameDetail, size: game.formattedSize)
                    Divider()
                    Text("Screenhots: ")
                        .font(.title2)
                    screenshotsSection(gameDetail: gameDetail)
                    Divider()
                    Text("Description: ")
                        .font(.title2)
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
        
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if viewModel.wishList.contains(where: { $0.game.id == game.id }) {
                    Button(action: {
                        viewModel.removeFromWishlist(game: game)
                    }) {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                    }
                } else {
                    Button(action: {
                        viewModel.addToWishlist(game: game)
                    }) {
                        Image(systemName: "heart")
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .navigationTitle("Game Details")
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
        .task {
            viewModel.fetchWishlist()
            await viewModel.fetchGameDetails(gameID: game.id)
        }
    }
    
    // MARK: - Header Section
    
    private func headerSection(gameDetail: GameDetail) -> some View {
        HStack(spacing: 15) {
            WebImage(url: game.iconURL) { image in
                image.resizable()
                
            } placeholder: {
                Image(systemName: "photo.badge.exclamationmark")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .cornerRadius(8)
            }
            .scaledToFit()
            .frame(width: 50, height: 50)
            .cornerRadius(8)
            
            VStack(alignment: .leading) {
                Text(game.gameName)
                    .font(.title2.bold())
                
                Text(game.version)
                    .font(.subheadline)
                    .padding(.horizontal, 8)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(4)
                
            }
            
        }
    }
    
    // MARK: - Metadata Section
    
    private func metadataSection(gameDetail: GameDetail, size: String) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 8) {
                if let publisher = gameDetail.publisher {
                    VStack(alignment: .center) {
                        Image(systemName: "building.columns")
                        Spacer()
                        Text(publisher)
                    }
                    Divider()
                }
                if let releaseDate = gameDetail.releaseDate {
                    
                    VStack(alignment: .center) {
                        Image(systemName: "calendar")
                        Spacer()
                        Text(releaseDate)
                    }
                    Divider()
                }
                if let category = gameDetail.category {
                    
                    VStack(alignment: .center) {
                        Image(systemName: "dice")
                        Spacer()
                        Text(category.joined(separator: ", "))
                    }
                    Divider()
                    
                }
                if let languages = gameDetail.languages {
                    VStack(alignment: .center) {
                        Image(systemName: "translate")
                        Spacer()
                        Text(languages.joined(separator: ", "))
                    }
                    Divider()
                }
                if let numberOfPlayers = gameDetail.numberOfPlayers {
                    VStack(alignment: .center) {
                        Image(systemName: "person.fill")
                        Spacer()
                        Text("\(numberOfPlayers)")
                    }
                    Divider()
                }
                
                VStack(alignment: .center) {
                    Image(systemName: "opticaldiscdrive")
                    Spacer()
                    Text(size)
                }
                
            }
            .font(.subheadline)
        }
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
                                .indicator(.activity)
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
