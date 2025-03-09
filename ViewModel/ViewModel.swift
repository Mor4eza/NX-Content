//
//  ViewModel.swift
//  NX-Content
//
//  Created by Morteza on 3/8/25.
//
import Combine
import Foundation

enum APIError: LocalizedError {
    case invalidRequestError(String)
    case transportError(Error)
    case decodeError(String)
}

class ViewModel: ObservableObject {
    @Published var games: [Game] = [] // Store the parsed games
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showDownloadButton = false // Controls visibility of the download button
    @Published var searchText = "" // Search query
    @Published var gameDetail: GameDetail? // Store the fetched game details
    @Published var isFetchingDetails = false // Loading state for game details
    @Published var isFetchingScreenshots = false // Loading state for screenshots
    @Published var selectedSortOption: SortOption = .releaseDate
    
    var totalTitles: Int {
        return filteredGames.count
    }
    
    private let fileName = "titles_db.json"
    
    private var fileURL: URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(fileName)
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    // Computed property to filter games based on search text
    var filteredGames: [Game] {
        if searchText.isEmpty {
            return games // Return all games if search text is empty
        } else {
            let filtered = searchText.isEmpty ? games : games.filter { $0.gameName.localizedCaseInsensitiveContains(searchText) }
            return sortGames(filtered)
        }
    }
    
    // Sorting state
    enum SortOption: String, CaseIterable {
        case name = "Name"
        case releaseDate = "Release Date"
        case size = "Size"
    }
    
    
    private func sortGames(_ games: [Game]) -> [Game] {
        switch selectedSortOption {
        case .name:
            return filteredGames.sorted { $0.gameName < $1.gameName }
        case .releaseDate:
            return filteredGames.sorted { $0.gameName < $1.gameName } //fixme: fix to sort with release date
        case .size:
            return filteredGames.sorted { $0.size < $1.size }
        }
    }
    
    // Check if the file exists locally
    func checkLocalFile() {
        
        guard games.isEmpty else {
            return
        }
        guard let fileURL = fileURL else {
            showDownloadButton = true
            return
        }
        
        if FileManager.default.fileExists(atPath: fileURL.path) {
            // File exists, load data from the file
            loadLocalFile()
        } else {
            // File does not exist, show download button
            showDownloadButton = true
        }
    }
    
    // Load data from the local file
    private func loadLocalFile() {
        guard let fileURL = fileURL else {
            errorMessage = "Invalid file path"
            return
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            parseJSON(data: data)
        } catch {
            errorMessage = "Failed to load local file: \(error.localizedDescription)"
        }
    }
    
    // Download and parse JSON
    func downloadAndParseJSON() {
        let fileURL = "https://raw.githubusercontent.com/ghost-land/NX-Missing/refs/heads/main/data/working.json"
        
        
        isLoading = true
        errorMessage = nil
        
        FileDownloader.shared.downloadFile(from: fileURL, to: .documentDirectory, with: fileName)
            .tryMap { fileURL -> Data in
                // Read the downloaded file
                return try Data(contentsOf: fileURL)
            }
            .decode(type: [String: Game].self, decoder: JSONDecoder()) // Decode into a dictionary
            .map { gameDictionary -> [Game] in
                // Convert the dictionary into an array of `Game` objects
                return gameDictionary.map { key, value in
                    var game = value
                    game.id = key // Set the ID from the dictionary key
                    return game
                }
            }
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                switch completion {
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                case .finished:
                    self?.showDownloadButton = false // Hide download button after successful download
                }
            }, receiveValue: { [weak self] games in
                self?.games = games
            })
            .store(in: &cancellables)
    }
    
    // Parse JSON data
    private func parseJSON(data: Data) {
        do {
            let gameDictionary = try JSONDecoder().decode([String: Game].self, from: data)
            self.games = gameDictionary.map { key, value in
                var game = value
                game.id = key
                return game
            }
        } catch {
            errorMessage = "Failed to parse JSON: \(error.localizedDescription)"
        }
    }
    
    // Fetch game details from the API
    func fetchGameDetails(gameID: String) {
        guard let url = URL(string: "https://api.nlib.cc/nx/\(gameID)") else {
            errorMessage = "Invalid URL"
            return
        }
        
        isFetchingDetails = true
        errorMessage = nil
        
        URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .tryMap { data -> GameDetail in
                let decoder = JSONDecoder()
                do {
                    return try decoder.decode(GameDetail.self,
                                              from: data)
                }
                catch {
                    throw APIError.decodeError(error.localizedDescription)
                }
            }
        
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isFetchingDetails = false
                switch completion {
                case .failure(let error):
                    self?.errorMessage = "Failed to fetch game details: \(error.localizedDescription)"
                case .finished:
                    break
                }
            }, receiveValue: { [weak self] gameDetail in
                self?.gameDetail = gameDetail
                if let screenshots = gameDetail.screens?.screenshots {
                    self?.fetchScreenshots(screenshots: screenshots) // Fetch screenshots
                }
            })
            .store(in: &cancellables)
    }
    
    // Fetch screenshots
    private func fetchScreenshots(screenshots: [String]) {
        isFetchingScreenshots = true
        
        // Simulate a delay for loading screenshots (optional)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.isFetchingScreenshots = false
        }
    }
}
