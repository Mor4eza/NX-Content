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
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchText = ""
    @Published var selectedSortOption: SortOption = .releaseDate
    @Published var gameDetail: GameDetail?
    private var modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // Sorting options
       enum SortOption: String, CaseIterable {
           case name = "Name"
           case releaseDate = "Release Date"
           case size = "Size"
           
           // Returns the appropriate SortDescriptor for the selected option
           var sortDescriptor: SortDescriptor<Game> {
               switch self {
               case .name:
                   return SortDescriptor(\Game.gameName, order: .forward)
               case .releaseDate:
                   return SortDescriptor(\Game.releaseDate, order: .forward)
               case .size:
                   return SortDescriptor(\Game.size, order: .forward)
               }
           }
       }

    func fetchGames(searchText: String) -> [Game] {
            let descriptor = FetchDescriptor<Game>(
                predicate: searchText.isEmpty ? nil : #Predicate { game in
                    game.gameName.localizedStandardContains(searchText)
                },
                sortBy: [selectedSortOption.sortDescriptor]
            )
            
            do {
                return try modelContext.fetch(descriptor)
            } catch {
                errorMessage = "Failed to fetch games: \(error.localizedDescription)"
                return []
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
        
        let dateMap = text.components(separatedBy: .newlines).reduce(into: [String: String]()) { result, line in
            let components = line.components(separatedBy: "|")
            if components.count >= 2 {
                result[components[0]] = components[1]
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
}
