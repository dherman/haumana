# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Haumana is an iOS app designed to help students of Hawaiian art and culture manage practice routines. The app allows users to upload oli (chants) or mele (songs) lyrics and randomly select which to practice during daily routines.

## Project Structure

### Docs: docs/

Project documentation is located in the `docs/` directory:
- `docs/product/`: Product design docs
- `docs/architecture/`: Engineering architecture design docs

### Functional specs: specs/

Functional specs for product functionality are all located in the `specs/` directory. Each spec is contained in a subdirectory and consists of three documents:
- `specs/[feature]/requirements.md`: High-level feature requirements
- `specs/[feature]/design.md`: Product Requirements Doc (PRD), aka functional specification
- `specs/[feature]/tasks.md`: Detailed implementation task checklist, listed in the expected order of implementation

### Frontend: ios/

The iOS app code is located in the `ios/` directory:
- `ios/Haumana/`: Main app source code
- `ios/Haumana.xcodeproj/`: Xcode project file
- `ios/DataTests/`: Unit tests for models and data persistence
- `ios/UITests/`: UI tests for user interface and interactions

### Backend: aws/

The AWS backend is located in the `aws/` directory:
- `aws/infrastructure/cdk/`: AWS CDK (infrastructure-as-code) automation
- `aws/lambdas/`: Main backend Lambda functions

## Development Commands

### Building
```bash
# Build for simulator
xcodebuild -scheme haumana -destination 'platform=iOS Simulator,name=iPhone 16,arch=arm64' -project ios/Haumana.xcodeproj

# Build for device
xcodebuild -scheme haumana -destination 'generic/platform=iOS' -project ios/Haumana.xcodeproj
```

### Deploying
```bash
./scripts/deploy-aws.sh
```

### Testing
```bash
# Run unit tests
xcodebuild test -scheme haumana -destination 'platform=iOS Simulator,name=iPhone 16,arch=arm64' -project ios/Haumana.xcodeproj -only-testing:DataTests

# Run UI tests
xcodebuild test -scheme haumana -destination 'platform=iOS Simulator,name=iPhone 16,arch=arm64' -project ios/Haumana.xcodeproj -only-testing:UITests

# Run all tests
xcodebuild test -scheme haumana -destination 'platform=iOS Simulator,name=iPhone 16,arch=arm64' -project ios/Haumana.xcodeproj
```

### Running in Xcode
```bash
# Open project in Xcode
open ios/Haumana.xcodeproj
```

## Architecture

The app uses SwiftUI and SwiftData frameworks with MVVM architecture:

### Models
- **Piece.swift**: Core data model representing oli/mele with fields for title, category, lyrics, language, author, source URL, and notes

### Views
- **HaumanaApp.swift**: Main app entry point, sets up SwiftData ModelContainer and navigation
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
- Whenever creating a document, always make sure to ask me any clarifying questions before finalizing.
- Whenever you need to know the current date, use the `date` command.
- Whenever we make a commit, always check with me on the commit message before finalizing