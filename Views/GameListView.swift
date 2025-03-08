//
//  GameListView.swift
//  NX-Content
//
//  Created by Morteza on 3/8/25.
//

import SwiftUI
import SDWebImageSwiftUI
import SDWebImage

struct GameListView: View {
    @StateObject private var viewModel = ViewModel()
    
    var body: some View {
        NavigationView {
            VStack {
                if viewModel.isLoading {
                    ProgressView("Downloading Game List...")
                } else if let errorMessage = viewModel.errorMessage {
                    Text("Error: \(errorMessage)")
                        .foregroundColor(.red)
                } else if !viewModel.games.isEmpty {
                    List {
                        Section(header: Text("Total Titles: \(viewModel.totalTitles)")
                            .font(.subheadline)) {
                                ForEach(viewModel.filteredGames) { game in
                                    NavigationLink(destination: GameDetailView(game: game)) {
                                        
                                        // Game Icon
                                        if let iconURL = game.iconURL {
                                            WebImage(url: iconURL)
                                                .resizable()
                                                
                                                .scaledToFit()
                                                .frame(width: 50, height: 50)
                                                .cornerRadius(8)
                                        
                                        } else {
                                            Image(systemName: "questionmark.square.fill")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 50, height: 50)
                                                .foregroundColor(.gray)
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text(game.gameName)
                                                .font(.headline)
                                            Text("Version: \(game.version)")
                                                .font(.subheadline)
                                            Text("Size: \(game.formattedSize)")
                                                .font(.subheadline)
                                        }
                                    }
                                }
                            }
                    }
                    #if os(iOS)
                    .searchable(text: $viewModel.searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search games")
                    #elseif os(macOS)
                    .searchable(text: $viewModel.searchText, prompt: "Search games")
                    #endif
                } else if viewModel.showDownloadButton {
                    Button(action: {
                        viewModel.downloadAndParseJSON()
                    }) {
                        Text("Download Game Titles")
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
            .navigationTitle("Game Library")
            .onAppear {
                viewModel.checkLocalFile() // Check for local file when the view appears
            }
        }
    }
}

#Preview {
    GameListView()
}
