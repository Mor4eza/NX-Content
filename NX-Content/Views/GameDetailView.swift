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
    @State private var zoomScale: CGFloat = 1.0
    @State private var currentIndex: Int = 0
    @State private var relatedContent: (base: Game?, updates: [Game], dlcs: [Game]) = (nil, [], [])

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let gameDetail = viewModel.gameDetail {
                    headerSection(gameDetail: gameDetail)
                    metadataSection(gameDetail: gameDetail, size: game.formattedSize)
                    screenshotsSection(gameDetail: gameDetail)
                    descriptionSection(gameDetail: gameDetail)
                    Divider()
                    if !relatedContent.updates.isEmpty {
                        Text("Updates")
                            .font(.title2)
                        ForEach(relatedContent.updates) { update in
                            GameRowView(game: update)
                        }
                    }
                    
                    if !relatedContent.dlcs.isEmpty {
                        Text("DLCs")
                            .font(.title2)
                        ForEach(relatedContent.dlcs) { dlc in
                            GameRowView(game: dlc)
                        }
                    }
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
            
            ToolbarItem(placement: .navigation) {
                Button(action: {
                    if let url = game.downloadURL {
                        DownloadManager.shared.startDownload(game: game)
                    }
                }) {
                    Label("Download", systemImage: "arrow.down.circle")
                }
                .disabled(game.downloadURL == nil)
            }
        }
        .navigationTitle("Game Details")
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
        .task {
            viewModel.fetchWishlist()
            await viewModel.fetchGameDetails(gameID: game.id)
//            relatedContent = viewModel.getRelatedContent(for: game)
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
                
                Text("v\(gameDetail.version ?? 0)")
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
                Divider()
                Text("Screenshots")
                    .font(.title2)
                VStack(spacing: 8) {
                    TabView(selection: $currentIndex) {
                        ForEach(0..<screenshots.count, id: \.self) { index in
                            WebImage(url: URL(string: screenshots[index]))
                                .resizable()
                                .indicator(.activity)
                                .scaledToFit()
                                .frame(height: 200)
                                .cornerRadius(10)
                                .scaleEffect(zoomScale)
                                .gesture(
                                    MagnificationGesture()
                                        .onChanged { value in
                                            zoomScale = value
                                        }
                                        .onEnded { value in
                                            withAnimation {
                                                zoomScale = 1.0
                                            }
                                        }
                                )
                                .tag(index)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
                    .frame(height: 220)
                    
                    HStack {
                        ForEach(0..<screenshots.count, id: \.self) { index in
                            Circle()
                                .fill(index == currentIndex ? Color.blue : Color.gray)
                                .frame(width: 8, height: 8)
                        }
                    }
                    .padding(.top, 10)
                }
            }
        }
    }
    
    // MARK: - Description Section
    
    private func descriptionSection(gameDetail: GameDetail) -> some View {
        Group {
            if let description = gameDetail.description {
                Divider()
                Text("Description: ")
                    .font(.title2)
                Text(description)
                    .font(.body)
                    .lineLimit(nil)
            } else {
                EmptyView()
            }
        }
    }
}
