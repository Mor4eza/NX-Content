//
//  MainTabView.swift
//  NX-Content
//
//  Created by Morteza on 3/10/25.
//


import SwiftUI

struct MainTabView: View {
    @StateObject private var viewModel = ViewModel(modelContext: Persistence.shared.container.mainContext)
    
    var body: some View {
        TabView {
            GameListView()
                .environmentObject(viewModel)
                .tabItem {
                    Label("Games", systemImage: "gamecontroller")
                }
            
            WishlistView()
                .environmentObject(viewModel)
                .tabItem {
                    Label("Wishlist", systemImage: "heart.fill")
                }
        }
    }
}
