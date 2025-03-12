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
    var publisher: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case size
        case releaseDate = "release_date"
        case publisher
    }
    
    init(id: String, gameName: String, version: String, size: Int, releaseDate: Date? = nil, publisher: String? = nil) {
        self.id = id
        self.gameName = gameName
        self.version = version
        self.size = size
        self.releaseDate = releaseDate
        self.publisher = publisher
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        
        let nameHTML = try container.decode(String.self, forKey: .name)
        self.gameName = Game.extractGameName(from: nameHTML)
        
        let sizeString = try container.decode(String.self, forKey: .size)
        self.size = Game.parseSize(from: sizeString)
        
        let releaseDateString = try container.decode(String.self, forKey: .releaseDate)
        self.releaseDate = Game.dateFormatter.date(from: releaseDateString)
        
        self.version = ""
        self.publisher = try container.decodeIfPresent(String.self, forKey: .publisher)
    }
    
    private static func extractGameName(from htmlString: String) -> String {
        let regex = try! NSRegularExpression(pattern: "<a[^>]*>(.*?)</a>", options: [])
        if let match = regex.firstMatch(in: htmlString, range: NSRange(location: 0, length: htmlString.utf16.count)) {
            let nsRange = match.range(at: 1)
            if let range = Range(nsRange, in: htmlString) {
                return String(htmlString[range])
            }
        }
        return htmlString
    }
    
    private static func parseSize(from sizeString: String) -> Int {
        let components = sizeString.components(separatedBy: " ")
        guard components.count == 2 else {
            return 0
        }
        let value = Double(components[0]) ?? 0
        let unit = components[1]
        
        switch unit {
        case "GB": return Int(value * 1024 * 1024 * 1024)
        case "MB": return Int(value * 1024 * 1024)
        case "KB": return Int(value * 1024)
        default: return 0
        }
    }
    
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
//    var iconURL: URL? {
//        URL(string: "https://tinfoil.media/ti/\(id)/128/128/")
//    }
    
    var formattedSize: String {
        let sizeInGB = Double(size) / (1024 * 1024 * 1024)
        return sizeInGB >= 1 ? String(format: "%.2f GB", sizeInGB) : String(format: "%.2f MB", Double(size) / (1024 * 1024))
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
        (1 ... 6).compactMap { index in
            URL(string: "https://api.nlib.cc/nx/\(baseTitleId)/screen/\(index)")
        }
    }
}
