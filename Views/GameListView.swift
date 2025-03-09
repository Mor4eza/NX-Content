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
    
    init() {
        let context = ModelContext(Persistence.shared.container)
        _viewModel = StateObject(wrappedValue: ViewModel(modelContext: context))
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.games.isEmpty && !viewModel.isLoading {
                    ContentUnavailableView("No Games Found", systemImage: "gamecontroller")
                } else {
                    List {
                        ForEach(viewModel.games) { game in
                            NavigationLink(destination: GameDetailView(game: game)) {
                                GameRowView(game: game)
                            }
                        }
                        
                        // Load more games when reaching the bottom
                        if viewModel.hasMoreGames {
                            ProgressView()
                                .frame(maxWidth: .infinity, alignment: .center)
                                .onAppear {
                                    Task {
                                        await viewModel.fetchGames()
                                    }
                                }
                        }
                    }
                }
            }
            .navigationTitle("NX Games")
            .searchable(text: $viewModel.searchText)
            .onChange(of: viewModel.searchText) { _, newValue in
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    Task {
                        viewModel.resetPagination()
                        await viewModel.fetchGames(searchText: newValue)
                    }
                }
                
            }
            .task {
                await viewModel.fetchGames() // Fetch the first page on app launch
            }
            
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu("Sort", systemImage: "arrow.up.arrow.down") {
                        ForEach(ViewModel.SortOption.allCases, id: \.self) { option in
                            Button(action: {
                                Task {
                                    viewModel.resetPagination()
                                    viewModel.selectedSortOption = option
                                    await viewModel.fetchGames()
                                }
                            }) {
                                Text(option.rawValue)
                                if viewModel.selectedSortOption == option {
                                    Image(systemName: "checkmark")
                                }
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
}

struct GameRowView: View {
    let game: Game
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
    
    var body: some View {
        HStack(spacing: 12) {
            WebImage(url: game.iconURL) { image in
                image.resizable()
                
            } placeholder: {
                Image(systemName: "photo.badge.exclamationmark.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .cornerRadius(8)
            }
                .indicator(.activity(style: .circular))
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
                        Text(dateFormatter.string(from: date))
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
    }
}
