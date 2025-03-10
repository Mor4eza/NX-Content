//
//  ViewModel.swift
//  NX-Content
//
//  Created by Morteza on 3/8/25.
//

import Combine
import Foundation
import SwiftData

@MainActor
class ViewModel: ObservableObject {
    @Published var games: [Game] = []
    @Published var wishList: [WishlistItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchText = ""
    @Published var selectedSortOption: SortOption = .releaseDateDescending
    @Published var gameDetail: GameDetail?
    @Published var hasMoreGames = true
    
    private var currentPage = 0
    private let pageSize = 20 // Number of games to fetch per page
    private var modelContext: ModelContext
    
    // Sorting options
    enum SortOption: String, CaseIterable {
        case nameAscending = "Name (A-Z)"
        case nameDescending = "Name (Z-A)"
        case releaseDateAscending = "Release Date (Oldest First)"
        case releaseDateDescending = "Release Date (Newest First)"
        case sizeAscending = "Size (Smallest First)"
        case sizeDescending = "Size (Largest First)"
        
        // Returns the appropriate SortDescriptor for the selected option
        var sortDescriptor: SortDescriptor<Game> {
            switch self {
            case .nameAscending:
                return SortDescriptor(\Game.gameName, order: .forward)
            case .nameDescending:
                return SortDescriptor(\Game.gameName, order: .reverse)
            case .releaseDateAscending:
                return SortDescriptor(\Game.releaseDate, order: .forward)
            case .releaseDateDescending:
                return SortDescriptor(\Game.releaseDate, order: .reverse)
            case .sizeAscending:
                return SortDescriptor(\Game.size, order: .forward)
            case .sizeDescending:
                return SortDescriptor(\Game.size, order: .reverse)
            }
        }
    }
    
    // Date formatter for parsing release dates
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func fetchGames(searchText: String = "") async {
        isLoading = true
        defer { isLoading = false }
        
        var descriptor = FetchDescriptor<Game>(
            predicate: searchText.isEmpty ? nil : #Predicate { game in
                game.gameName.localizedStandardContains(searchText)
            },
            sortBy: [selectedSortOption.sortDescriptor]
        )
        descriptor.fetchOffset = currentPage * pageSize
        descriptor.fetchLimit = pageSize
        
        do {
            let newGames = try modelContext.fetch(descriptor)
            if newGames.isEmpty {
                hasMoreGames = false // No more games to load
            } else {
                games.append(contentsOf: newGames)
                currentPage += 1
            }
        } catch {
            errorMessage = "Failed to fetch games: \(error.localizedDescription)"
        }
    }
    
    func downloadGameData() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let games = try await downloadAndParseJSON()
            try await updateReleaseDates(for: games)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    private func downloadAndParseJSON() async throws -> [Game] {
        deleteAllGames()
        let url = URL(string: "https://raw.githubusercontent.com/ghost-land/NX-Missing/main/data/working.json")!
        let (data, _) = try await URLSession.shared.data(from: url)
        
        let decoder = JSONDecoder()
        let gameDict = try decoder.decode([String: Game].self, from: data)
        
        return gameDict.map { key, value in
            let game = value
            game.id = key
            return game
        }
    }
    
    private func updateReleaseDates(for games: [Game]) async throws {
        let url = URL(string: "https://raw.githubusercontent.com/ghost-land/NX-Missing/main/data/titles_db.txt")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let text = String(decoding: data, as: UTF8.self)
        
        let dateMap = text.components(separatedBy: .newlines).reduce(into: [String: Date]()) { result, line in
            let components = line.components(separatedBy: "|")
            if components.count >= 2, let date = dateFormatter.date(from: components[1]) {
                result[components[0]] = date
            }
        }
        
        for game in games {
            game.releaseDate = dateMap[game.id]
            modelContext.insert(game)
        }
        try modelContext.save()
    }
    
    
    // Fetch game details from the API
    func fetchGameDetails(gameID: String) async {
        isLoading = true
        defer { isLoading = false }
        
        let urlString = "https://api.nlib.cc/nx/\(gameID)"
        guard let url = URL(string: urlString) else {
            errorMessage = "Invalid URL"
            return
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoder = JSONDecoder()
            let gameDetail = try decoder.decode(GameDetail.self, from: data)
            self.gameDetail = gameDetail
        } catch {
            errorMessage = "Failed to fetch game details: \(error.localizedDescription)"
        }
    }
    
    // Reset pagination when search text changes
    func resetPagination() {
        currentPage = 0
        games.removeAll()
        hasMoreGames = true
    }
    
    //Delete all games
    func deleteAllGames() {
        do {
            let descriptor = FetchDescriptor<Game>()
            let games = try modelContext.fetch(descriptor)
            for game in games {
                modelContext.delete(game)
            }
            try modelContext.save()
            print("All games deleted from SwiftData.")
        } catch {
            errorMessage = "Failed to delete games: \(error.localizedDescription)"
            print("Error deleting games: \(error.localizedDescription)")
        }
    }
    
    //MARK: - Wish List
    
    // Add a game to the wish list
    func addToWishlist(game: Game) {
        let gameId = game.id
        let descriptor = FetchDescriptor<WishlistItem>(
            predicate: #Predicate {
                gameId == $0.game.id
            }
        )
        
        do {
            let existingItems = try modelContext.fetch(descriptor)
            if existingItems.isEmpty {
                let wishlistItem = WishlistItem(game: game)
                modelContext.insert(wishlistItem)
                try modelContext.save()
                print("Game added to wish list: \(game.gameName)")
                fetchWishlist()
            } else {
                print("Game is already in the wish list: \(game.gameName)")
            }
        } catch {
            errorMessage = "Failed to add game to wish list: \(error.localizedDescription)"
            print("Error adding to wish list: \(error.localizedDescription)")
        }
    }
    
    // Remove a game from the wish list
    func removeFromWishlist(game: Game) {
        let gameId = game.id
        let descriptor = FetchDescriptor<WishlistItem>(
            predicate: #Predicate {
                gameId == $0.game.id
            })
        
        do {
            let items = try modelContext.fetch(descriptor)
            for item in items {
                modelContext.delete(item)
            }
            try modelContext.save()
            fetchWishlist()
        } catch {
            errorMessage = "Failed to remove game from wish list: \(error.localizedDescription)"
        }
    }
    
    // Fetch all wishlist items
    func fetchWishlist() {
        let descriptor = FetchDescriptor<WishlistItem>(
            sortBy: [SortDescriptor(\WishlistItem.addedDate, order: .reverse)]
        )
        
        do {
            wishList = try modelContext.fetch(descriptor)
        } catch {
            errorMessage = "Failed to fetch wish list: \(error.localizedDescription)"
        }
    }
}
