//
//  GameDetail.swift
//  NX-Content
//
//  Created by Morteza on 3/8/25.
//


import Foundation

struct GameDetail: Codable {
    let description: String?
    let id: String?
    let name: String?
    let publisher: String?
    let releaseDate: String?
    let version: Int?
    let category: [String]?
    let developer: String?
    let intro: String?
    let isDemo: Bool?
    let languages: [String]?
    let numberOfPlayers: Int?
    let ratingContent: [String]?
    let region: String?
    let rightsId: String?
    let console: String?
    let type: String?
    let screens: Screens?
    
    struct Screens: Codable {
        let count: Int
        let screenshots: [String]
    }
}
