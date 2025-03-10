//
//  Persistence.swift
//  NX-Content
//
//  Created by Morteza on 3/9/25.
//


import SwiftData

final class Persistence {
    static let shared = Persistence()
    
    let container: ModelContainer
    
    init() {
        do {
            
            container = try ModelContainer(for: Game.self, WishlistItem.self)
        } catch {
            fatalError("Failed to initialize ModelContainer: \(error)")
        }
    }
}
