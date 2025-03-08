//
//  FileDownloader.swift
//  NX-Content
//
//  Created by Morteza on 3/8/25.
//

import Foundation
import Combine

class FileDownloader {
    // Singleton instance (optional, depending on your use case)
    static let shared = FileDownloader()
    
    private init() {} // Prevent external initialization
    
    /// Downloads a file from a URL and saves it to the specified directory.
    /// - Parameters:
    ///   - urlString: The URL of the file to download.
    ///   - directory: The directory where the file should be saved (e.g., .documentDirectory).
    ///   - fileName: The name of the file to save.
    /// - Returns: A publisher that emits the file URL once the download is complete, or an error if it fails.
    func downloadFile(from urlString: String, to directory: FileManager.SearchPathDirectory, with fileName: String) -> AnyPublisher<URL, Error> {
        // Create a URL from the string
        guard let url = URL(string: urlString) else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        
        // Create a URLSession data task publisher
        return URLSession.shared.dataTaskPublisher(for: url)
            .tryMap { data, response -> Data in
                // Check for valid HTTP response
                guard let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200 else {
                    throw URLError(.badServerResponse)
                }
                return data
            }
            .tryMap { data -> URL in
                // Get the specified directory URL
                guard let directoryURL = FileManager.default.urls(for: directory, in: .userDomainMask).first else {
                    throw URLError(.cannotCreateFile)
                }
                
                // Create the file URL
                let fileURL = directoryURL.appendingPathComponent(fileName)
                
                // Write the data to the file
                try data.write(to: fileURL)
                return fileURL
            }
            .eraseToAnyPublisher()
    }
}
