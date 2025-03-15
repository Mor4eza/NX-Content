//
//  WishlistView.swift
//  NX-Content
//
//  Created by Morteza on 3/9/25.
//


import SwiftUI

struct WishlistView: View {
    @EnvironmentObject private var viewModel: ViewModel
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.wishList, id: \.game.id) { item in
                    GameRowView(game: item.game)
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        let item = viewModel.wishList[index]
                        viewModel.removeFromWishlist(game: item.game)
                        viewModel.fetchWishlist()
                    }
                }
            }
            
            .navigationTitle("Wishlist")
            .overlay {
                if viewModel.wishList.isEmpty {
                    ContentUnavailableView("Your Wishlist is Empty", systemImage: "heart.slash")
                }
            }
            .onAppear {
                viewModel.fetchWishlist()
            }
        }
    }
}
