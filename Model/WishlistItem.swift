//
//  WishlistItem.swift
//  NX-Content
//
//  Created by Morteza on 3/9/25.
//


import Foundation
import SwiftData

@Model
final class WishlistItem {
    var game: Game
    var addedDate: Date
    
    init(game: Game, addedDate: Date = Date()) {
        self.game = game
        self.addedDate = addedDate
    }
}