# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Haumana is an iOS app designed to help students of Hawaiian art and culture manage practice routines. The app allows users to upload oli (chants) or mele (songs) lyrics and randomly select which to practice during daily routines.

## Project Structure

The iOS app code is located in the `ios/` directory:
- `ios/haumana/`: Main app source code
- `ios/haumana.xcodeproj/`: Xcode project file
- `ios/haumanaTests/`: Unit tests
- `ios/haumanaUITests/`: UI tests

## Development Commands

### Building
```bash
# Build for simulator
xcodebuild -scheme haumana -destination 'platform=iOS Simulator,name=iPhone 15' -project ios/haumana.xcodeproj

# Build for device
xcodebuild -scheme haumana -destination 'generic/platform=iOS' -project ios/haumana.xcodeproj
```

### Testing
```bash
# Run unit tests
xcodebuild test -scheme haumana -destination 'platform=iOS Simulator,name=iPhone 15' -project ios/haumana.xcodeproj -only-testing:haumanaTests

# Run UI tests
xcodebuild test -scheme haumana -destination 'platform=iOS Simulator,name=iPhone 15' -project ios/haumana.xcodeproj -only-testing:haumanaUITests

# Run all tests
xcodebuild test -scheme haumana -destination 'platform=iOS Simulator,name=iPhone 15' -project ios/haumana.xcodeproj
```

### Running in Xcode
```bash
# Open project in Xcode
open ios/haumana.xcodeproj
```

## Architecture

The app uses SwiftUI and SwiftData frameworks with MVVM architecture:

### Models
- **Piece.swift**: Core data model representing oli/mele with fields for title, category, lyrics, language, author, source URL, and notes

### Views
- **haumanaApp.swift**: Main app entry point, sets up SwiftData ModelContainer and navigation
- **SplashScreenView.swift**: Branded splash screen with custom fonts and lehua flower image
- **RepertoireListView.swift**: Main list view showing all pieces with search, empty state, and swipe-to-delete

### ViewModels
- **RepertoireListViewModel.swift**: Manages repertoire list state, search, and CRUD operations
- **PieceDetailViewModel.swift**: Handles piece detail display logic
- **AddEditPieceViewModel.swift**: Manages add/edit form state and validation

### Repositories
- **PieceRepository.swift**: Data access layer providing CRUD operations and search functionality for Piece entities

### Assets
- Custom Hawaiian fonts: Adelia and Pearl Hirenha
- Lehua flower image for branding

The app targets iOS 17+ and supports both portrait and landscape orientations with dark mode compatibility.

## Development Memories
- Always build for iPhone 16