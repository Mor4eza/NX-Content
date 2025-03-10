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
    var releaseDate: Date?
    
    enum CodingKeys: String, CodingKey {
        case gameName = "Game Name"
        case version = "Version"
        case size = "Size"
    }
    
    init(id: String, gameName: String, version: String, size: Int, releaseDate: Date? = nil) {
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
    
    // MARK: - Base Title ID Logic
    
    var isBaseGame: Bool {
        return id.hasSuffix("000")
    }
    
    var baseTitleId: String {
        // For base titles (ending in 000), return as is
        if id.hasSuffix("000") {
            return id
        }
        
        // For updates (ending in 800), use the base title ID
        if id.hasSuffix("800") {
            return String(id.dropLast(3)) + "000"
        }
        
        // For DLCs, change the fourth-to-last digit and set last 3 digits to 000
        let fourthFromEnd = id[id.index(id.endIndex, offsetBy: -4)]
        let prevChar: String
        if fourthFromEnd >= "1" && fourthFromEnd <= "9" {
            prevChar = String(Int(String(fourthFromEnd))! - 1)
        } else if fourthFromEnd >= "b" && fourthFromEnd <= "z" {
            prevChar = String(UnicodeScalar(fourthFromEnd.unicodeScalars.first!.value - 1)!)
        } else if fourthFromEnd >= "B" && fourthFromEnd <= "Z" {
            prevChar = String(UnicodeScalar(fourthFromEnd.unicodeScalars.first!.value - 1)!)
        } else {
            prevChar = String(fourthFromEnd)
        }
        return String(id.dropLast(4)) + prevChar + "000"
    }
    
    // MARK: - Visual Assets
    
    var iconURL: URL? {
        URL(string: "https://api.nlib.cc/nx/\(baseTitleId)/icon/128/128")
    }
    
    var bannerURL: URL? {
        URL(string: "https://api.nlib.cc/nx/\(baseTitleId)/banner/1280/720")
    }
    
    var screenshotURLs: [URL] {
        (1...6).compactMap { index in
            URL(string: "https://api.nlib.cc/nx/\(baseTitleId)/screen/\(index)")
        }
    }
}
