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
    @Published var downloadItems: [DownloadItem] = []
    
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
    
    private struct ApiResponse: Decodable {
        let data: [Game]
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
    
    func getAllContentsFromDB() -> [Game] {
        var allContent = [Game]()
        let descriptor = FetchDescriptor<Game>(predicate: nil)
        do {
            let game = try modelContext.fetch(descriptor)
            allContent.append(contentsOf: game)
        } catch {
            print("failed to load data")
        }
        return allContent
    }
    
    func downloadGameData() async {
           isLoading = true
           defer { isLoading = false }
           
           do {
               let games = try await downloadAndParseJSON()
               let tinfoilData = try await downloadTinfoilData()
               mapDownloadUrls(tinfoilData: tinfoilData, games: games)
               for game in games {
                   modelContext.insert(game)
               }
               try modelContext.save()
               errorMessage = nil
           } catch {
               errorMessage = error.localizedDescription
           }
       }
    
    private func downloadAndParseJSON() async throws -> [Game] {
        deleteAllGames()
        let url = URL(string: "https://tinfoil.media/Title/ApiJson/")!
        let (data, _) = try await URLSession.shared.data(from: url)
        
        let decoder = JSONDecoder()
        let apiResponse = try decoder.decode(ApiResponse.self, from: data)
        return apiResponse.data
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
    
    func getRelatedContent(for game: Game) -> (base: Game?, updates: [Game], dlcs: [Game]) {
            let basePrefix = String(game.id.prefix(12))
        
            // Find all related items
            let relatedItems =  getAllContentsFromDB().filter { String($0.id.prefix(12)) == basePrefix }
            
            // Get base game (should be the one matching baseTitleId)
            let base = relatedItems.first { $0.id == game.baseTitleId }
            
            // Get updates (ending with 800)
            let updates = relatedItems.filter { $0.id.hasSuffix("800") }
                .sorted { $0.version.localizedCompare($1.version) == .orderedDescending }
            
            // Get DLCs (not base and not updates)
            let dlcs = relatedItems.filter {
                !$0.id.hasSuffix("000") && !$0.id.hasSuffix("800")
            }.sorted { $0.id.localizedCompare($1.id) == .orderedAscending }
            
            return (base, updates, dlcs)
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

extension ViewModel {
    private func downloadTinfoilData() async throws -> TinfoilResponse {
        let url = URL(string: "https://tinfoil.ultranx.ru/tinfoil")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(TinfoilResponse.self, from: data)
    }

    private func mapDownloadUrls(tinfoilData: TinfoilResponse, games: [Game]) {
        for file in tinfoilData.files {
            // Extract game ID from filename (e.g., [01001E500F7FC000])
            let pattern = "\\[([A-Za-z0-9]{16})\\]"
            let regex = try? NSRegularExpression(pattern: pattern)
            if let match = regex?.firstMatch(in: file.url, range: NSRange(file.url.startIndex..., in: file.url)) {
                let gameId = String(file.url[Range(match.range(at: 1), in: file.url)!])
                
                if let game = games.first(where: { $0.id == gameId }) {
                    game.downloadURL = file.url
                    game.fileSize = file.size
                }
            }
        }
    }

    struct TinfoilResponse: Decodable {
        let files: [TinfoilFile]
        let success: String
    }

    struct TinfoilFile: Decodable {
        let size: Int
        let url: String
    }
}
