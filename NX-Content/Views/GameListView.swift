//
//  GameListView.swift
//  NX-Content
//
//  Created by Morteza on 3/8/25.
//
import SDWebImage
import SDWebImageSwiftUI
import SwiftData
import SwiftUI

struct GameListView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel: ViewModel
    
    init() {
        let context = Persistence.shared.container.mainContext
        _viewModel = StateObject(wrappedValue: ViewModel(modelContext: context))
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.games.isEmpty && !viewModel.isLoading {
                    VStack {
                        
                        ContentUnavailableView {
                            Label("No Games Found", systemImage: "gamecontroller")
                        } description: {
                            Button("Get Games") {
                                Task {
                                    await viewModel.downloadGameData()
                                    await viewModel.fetchGames()
                                }
                            }.buttonStyle(.bordered)
                                .disabled(viewModel.isLoading)
                        }
                        
                    }
                } else {
                    List {
                        ForEach(viewModel.games.filter{$0.isBaseGame}) { game in
                            
                            GameRowView(game: game)
                                .environmentObject(viewModel)
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
                viewModel.fetchWishlist()
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
                
                ToolbarItem(placement: .confirmationAction) {
                    
                    Button("Refresh Data", systemImage: "arrow.trianglehead.2.counterclockwise.rotate.90" ) {
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
    @EnvironmentObject private var viewModel: ViewModel
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
    
    var body: some View {
        NavigationLink(destination: GameDetailView(game: game)) {
            HStack(spacing: 12) {
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
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(game.gameName)
                        .font(.headline)
                    
                    HStack(spacing: 8) {
                        Text(game.formattedSize)
                        if let date = game.releaseDate {
                            Text(date, style: .date)
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                
                Spacer()
                
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
    }
}
