# NX-Content App

This is an iOS and MacOS app designed to display Nintendo Switch game titles. The app allows users to browse games, view detailed information, add games to a wishlist, and explore related content (updates, and DLCs). The app is built using Swift, SwiftUI, and SwiftData for local data persistence.

---

## Features

### 1. **Game List View**
   - **Browse Games**: View a list of Nintendo Switch games.
   - **Search**: Search for games by name.
   - **Sorting**: Sort games by name, release date, or size.
   - **Pagination**: Load more games as you scroll.

### 2. **Game Detail View**
   - **Game Information**: View detailed information about a game, including:
     - Description
     - Publisher
     - Release Date
     - Version
     - Size
     - Number of Players
     - Languages
     - Rating Content
   - **Screenshots**: View game screenshots with zoom-in functionality.
   - **Related Content**: Explore related content for the game:
     - Updates 
     - DLCs

### 3. **Wishlist**
   - **Add to Wishlist**: Add games to your wishlist for easy access.
   - **Remove from Wishlist**: Remove games from your wishlist.
   - **Wishlist View**: View all games in your wishlist in a dedicated tab.

### 4. **Visual Assets**
   - **Icons**: Display game icons fetched from the API.
   - **Screenshots**: Display up to 6 screenshots per game.

### 5. **Data Persistence**
   - **SwiftData**: Games and wishlist items are stored locally using SwiftData.
   - **Offline Access**: Browse games and wishlist items even without an internet connection.
---

## Screenshots

| Game List View | Game Detail View | Wishlist View |
|----------------|------------------|---------------|
| ![Game List](ScreenShots/game_list.png) | ![Game Detail](ScreenShots/game_detail.png) | ![Wishlist](ScreenShots/wishlist.png) |

---

## Setup Instructions

### Prerequisites
- Xcode 15 or later.
- Swift 5.9 or later.
- iOS 17 or later.

### Steps
1. **Clone the Repository**:
   ```bash
   git clone https://github.com/mor4eza/nx-content.git
2.  **Open the Project**:
    
    -   Open the  `NX-Content.xcodeproj`  file in Xcode.
        
3.  **Run the App**:
    
    -   Select a simulator or a physical device.
        
    -   Click the  **Run**  button (or press  `Cmd + R`) to build and run the app.
        
4.  **Explore the App**:
    
    -   Browse games, view details, and manage your wishlist.
    

## Contributing

Contributions are welcome! If you'd like to contribute, please follow these steps:

1.  Fork the repository.
    
2.  Create a new branch (`git checkout -b feature/YourFeatureName`).
    
3.  Commit your changes (`git commit -m 'Add some feature'`).
    
4.  Push to the branch (`git push origin feature/YourFeatureName`).
    
5.  Open a pull request.

## License

This project is licensed under the MIT License. See the  [LICENSE](LICENSE)  file for details.

----------

## Acknowledgments

-   Thanks to  [ghost-land content](https://nx-content.ghostland.at/)  for providing the game data.    

----------

## Contact

For questions or feedback, please contact:

-   **Morteza Ghardaghi**:  [morteza.ghrdi@gmail.com](https://mailto:morteza.ghrdi@gmail.com/)    

----------

Enjoy exploring Nintendo Switch games with this app! 🎮
