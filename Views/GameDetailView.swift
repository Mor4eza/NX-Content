//
//  GameDetailView.swift
//  NX-Content
//
//  Created by Morteza on 3/8/25.
//


import SwiftUI
import SDWebImageSwiftUI // For loading images from URLs
struct GameDetailView: View {
    let game: Game
    @StateObject private var viewModel = ViewModel()
    
    var body: some View {
        
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                
                HStack {
                    WebImage(url: game.iconURL)
                        .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .cornerRadius(8)
                    
                    Text(game.gameName)
                        .font(.largeTitle)
                        .bold()
                }
                
                
                // Metadata
                HStack {
                    Text(game.version == "0" ? "Full Game" : "Demo")
                        .font(.subheadline)
                        .padding(6)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(4)
                    
                    Text("Version \(game.version)")
                        .font(.subheadline)
                    
                    Spacer()
                    
                    Text(game.formattedSize)
                        .font(.subheadline)
                }
                
                // Screenshots Gallery
                if viewModel.isFetchingScreenshots {
                    ProgressView("Loading Screenshots...")
                        .frame(height: 200)
                } else if let screenshots = viewModel.gameDetail?.screens?.screenshots {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(screenshots, id: \.self) { screenshot in
                                WebImage(url: URL(string: screenshot))
                                    .resizable()
                                    .indicator(.activity) // Activity Indicator
                                    .scaledToFit()
                                    .frame(height: 200)
                                    .cornerRadius(10)
                            }
                        }
                    }
                }
                
                // Description
                if let description = viewModel.gameDetail?.description {
                    Text(description)
                        .font(.body)
                        .lineLimit(nil)
                }
                
                // Additional Info
                if let gameDetail = viewModel.gameDetail {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Publisher: \(gameDetail.publisher ?? "N/A")")
                        Text("Release Date: \(gameDetail.releaseDate ?? "N/A")")
                        if let category = gameDetail.category {
                            Text("Category: \(category.joined(separator: ", "))")
                        }
                        
                        Text("Languages: \(gameDetail.languages?.joined(separator: ", ") ?? "N/A")")
                        Text("Number of Players: \(gameDetail.numberOfPlayers ?? 1)")
                    }
                    .font(.subheadline)
                }
                
                // Download Button
                Button(action: {
                    // Simulate download action
                    print("Downloading \(game.gameName)...")
                }) {
                    Text("Download")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .padding()
        }
//        .navigationTitle(game.gameName)
        .onAppear {
            viewModel.fetchGameDetails(gameID: game.id) // Fetch details when the view appears
        }
        .overlay {
            if viewModel.isFetchingDetails {
                ProgressView("Loading Game Details...")
                    .padding()
//                    .background(Color(.systemBackground))
                    .cornerRadius(10)
                    .shadow(radius: 10)
            }
        }
    }
    
}
