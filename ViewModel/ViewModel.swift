//
//  ViewModel.swift
//  NX-Content
//
//  Created by Morteza on 3/8/25.
//
import Combine
import Foundation

class ViewModel: ObservableObject {
    @Published var games: [Game] = [] // Store the parsed games
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showDownloadButton = false // Controls visibility of the download button
    
    private let fileName = "titles_db.json"

    private var fileURL: URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(fileName)
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    // Check if the file exists locally
    func checkLocalFile() {
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
}
