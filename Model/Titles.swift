//
//  Titles.swift
//  NX-Content
//
//  Created by Morteza on 3/8/25.
//
import Foundation

struct Game: Identifiable, Codable {
    var id: String // Use the game ID as the unique identifier
    let gameName: String
    let version: String
    let size: Int // Size in bytes
    
    // CodingKeys to map JSON keys to Swift property names
    enum CodingKeys: String, CodingKey {
        case gameName = "Game Name"
        case version = "Version"
        case size = "Size"
    }
    
    // Custom initializer to include the ID
    init(id: String, gameName: String, version: String, size: Int) {
        self.id = id
        self.gameName = gameName
        self.version = version
        self.size = size
    }
    
    // Decode the nested JSON structure
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.gameName = try container.decode(String.self, forKey: .gameName)
        self.version = try container.decode(String.self, forKey: .version)
        self.size = try container.decode(Int.self, forKey: .size)
        // Extract the ID from the parent container
        let parentContainer = try decoder.container(keyedBy: JSONCodingKeys.self)
        self.id = parentContainer.allKeys.first!.stringValue
    }
    
    // Helper struct to handle dynamic keys in JSON
    struct JSONCodingKeys: CodingKey {
        var stringValue: String
        init?(stringValue: String) {
            self.stringValue = stringValue
        }
        
        var intValue: Int?
        init?(intValue: Int) {
            return nil
        }
    }
    
    // Convert size to MB
    var sizeInMB: Double {
        return Double(size) / (1024 * 1024)
    }
    
    // Convert size to GB
    var sizeInGB: Double {
        return Double(size) / (1024 * 1024 * 1024)
    }
    
    // Format size as a human-readable string (e.g., "1.23 GB" or "456.78 MB")
    var formattedSize: String {
        if sizeInGB >= 1 {
            return String(format: "%.2f GB", sizeInGB)
        } else {
            return String(format: "%.2f MB", sizeInMB)
        }
    }
    
    var iconURL: URL? {
            return URL(string: "https://api.nlib.cc/nx/\(id)/icon/128/128")
        }
}
