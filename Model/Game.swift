//
//  Titles.swift
//  NX-Content
//
//  Created by Morteza on 3/8/25.
//
import Foundation
import SwiftData

@Model
final class Game: Identifiable, Decodable {
    @Attribute(.unique) var id: String
    var gameName: String
    var version: String
    var size: Int
    var releaseDate: String?
    
    enum CodingKeys: String, CodingKey {
        case gameName = "Game Name"
        case version = "Version"
        case size = "Size"
    }
    
    init(id: String, gameName: String, version: String, size: Int, releaseDate: String? = nil) {
        self.id = id
        self.gameName = gameName
        self.version = version
        self.size = size
        self.releaseDate = releaseDate
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.gameName = try container.decode(String.self, forKey: .gameName)
        self.version = try container.decode(String.self, forKey: .version)
        self.size = try container.decode(Int.self, forKey: .size)
        
        let parentContainer = try decoder.container(keyedBy: JSONCodingKeys.self)
        self.id = parentContainer.allKeys.first!.stringValue
        self.releaseDate = nil
    }
    
    struct JSONCodingKeys: CodingKey {
        var stringValue: String
        init?(stringValue: String) { self.stringValue = stringValue }
        var intValue: Int? { nil }
        init?(intValue: Int) { nil }
    }
    
    var formattedSize: String {
        let sizeInGB = Double(size) / (1024 * 1024 * 1024)
        return sizeInGB >= 1 ?
            String(format: "%.2f GB", sizeInGB) :
            String(format: "%.2f MB", Double(size) / (1024 * 1024))
    }
    
    var iconURL: URL? {
        URL(string: "https://api.nlib.cc/nx/\(id)/icon/128/128")
    }
}
