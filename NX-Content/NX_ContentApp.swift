//
//  NX_ContentApp.swift
//  NX-Content
//
//  Created by Morteza on 3/8/25.
//

import SwiftUI

@main
struct NX_ContentApp: App {
    var body: some Scene {
        WindowGroup {
            GameListView()
        }
        .modelContainer(for: Game.self)
    }
}
