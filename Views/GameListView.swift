//
//  GameListView.swift
//  NX-Content
//
//  Created by Morteza on 3/8/25.
//
import SwiftUI
import SwiftData
import SDWebImage
import SDWebImageSwiftUI

struct GameListView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel: ViewModel
    @Query private var games: [Game]
    
    init() {
        let context = ModelContext(Persistence.shared.container)
        _viewModel = StateObject(wrappedValue: ViewModel(modelContext: context))
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if games.isEmpty {
                    ContentUnavailableView("No Games Found", systemImage: "gamecontroller")
                } else {
                    List {
                        ForEach(filteredGames) { game in
                            NavigationLink(destination: GameDetailView(game: game)) {
                                GameRowView(game: game)
                            }
                        }
                    }
                }
            }
            .navigationTitle("NX Games")
            .searchable(text: $viewModel.searchText)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu("Sort", systemImage: "arrow.up.arrow.down") {
                        ForEach(ViewModel.SortOption.allCases, id: \.self) { option in
                            Button(option.rawValue) {
                                viewModel.selectedSortOption = option
                            }
                        }
                    }
                }
                
                ToolbarItem(placement: .bottomBar) {
                    Button("Refresh Data") {
                        Task { await viewModel.downloadGameData() }
                    }
                    .disabled(viewModel.isLoading)
                }
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(2)
                }
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }
    
    // Filtered games based on search text
    private var filteredGames: [Game] {
        viewModel.fetchGames(searchText: viewModel.searchText)
    }
}

struct GameRowView: View {
    let game: Game
    
    var body: some View {
        HStack(spacing: 12) {
            WebImage(url: game.iconURL)
                .resizable()
                .scaledToFit()
                .frame(width: 50, height: 50)
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(game.gameName)
                    .font(.headline)
                
                HStack(spacing: 8) {
                    Text("v\(game.version)")
                    Text(game.formattedSize)
                    if let date = game.releaseDate {
                        Text(date)
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
    }
}
