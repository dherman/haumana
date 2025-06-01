# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Haumana is an iOS app designed to help students of Hawaiian art and culture manage practice routines. The app allows users to upload oli (chants) or mele (songs) lyrics and randomly select which to practice during daily routines.

## Development Commands

### Building
```bash
# Build for simulator
xcodebuild -scheme haumana -destination 'platform=iOS Simulator,name=iPhone 15'

# Build for device
xcodebuild -scheme haumana -destination 'generic/platform=iOS'
```

### Testing
```bash
# Run unit tests
xcodebuild test -scheme haumana -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:haumanaTests

# Run UI tests
xcodebuild test -scheme haumana -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:haumanaUITests

# Run all tests
xcodebuild test -scheme haumana -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Running in Xcode
```bash
# Open project in Xcode
open haumana.xcodeproj
```

## Architecture

The app uses SwiftUI and SwiftData frameworks:

- **haumanaApp.swift**: Main app entry point, sets up the SwiftData ModelContainer
- **ContentView.swift**: Primary UI view, currently shows a list of items with timestamps (placeholder implementation)
- **Item.swift**: SwiftData model class representing stored items

The app is structured as a standard iOS project with separate targets for the main app, unit tests, and UI tests. The current implementation appears to be a template that needs to be extended with oli/mele management functionality.