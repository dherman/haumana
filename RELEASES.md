# Release Notes

## Haumana 🌺

Haumana is an iOS app designed to help students of Hawaiian art and culture manage their practice routines.

---

## Version 0.1.0 - Milestone 1 (Build Your Repertoire)
*Released: June 2025*

This initial release establishes the foundation for building and organizing your repertoire of oli (chants) and mele (songs).

### New Features

#### Repertoire Management
- **Create pieces**: Add oli and mele with comprehensive metadata including title, lyrics, category, language, author, source URL, and personal notes
- **View repertoire**: Browse all your pieces in a simple list with title, category badges, and lyrics previews
- **Edit pieces**: Update any piece with form validation and field requirements
- **Delete pieces**: Remove pieces with swipe-to-delete gesture and confirmation

#### Language Support
- **Hawaiian language support**: Proper display of Hawaiian diacriticals (ʻokina and kahakō)
- **Language selection**: Choose between ʻŌlelo Hawaiʻi and English for each piece

#### User Experience
- **Splash screen**: Branded 3-second introduction with smooth transitions
- **Empty state**: Lehua flower illustration with guidance for new users
- **Search functionality**: Simple search across titles and lyrics
- **Responsive design**: Support for portrait and landscape orientations
- **Dark mode**: Automatic support for system light/dark mode preferences

#### Accessibility & Polish
- **VoiceOver support**: Accessibility for screen readers
- **Dynamic Type**: Supports system text size preferences
- **Keyboard management**: Smooth form interactions with proper scrolling
- **Performance**: Should work ok for up to about 1000 pieces without degradation

### Technical Details

#### Platform Requirements
- **iOS 17.0+**: Assumes fairly recent iOS versions
- **SwiftUI + SwiftData**: For declarative UI with local data persistence
- **Universal support**: Should support both iPhone and iPad with adaptive layouts

#### Data Model
Each piece includes:
- Title (required, up to 4096 characters)
- Category (Oli or Mele)
- Lyrics (required, unlimited length)
- Language (Hawaiian or English)
- Author (optional)
- Source URL (optional, with validation)
- Personal notes (optional)
- Automatic timestamps for creation and updates

#### Performance Benchmarks
- App launch to main screen: <2 seconds
- Piece save operations: <500ms
- Search results: <100ms
- Tested with 1000+ pieces

### User Interface

#### Screens Included
1. **Splash Screen**: Branded introduction with app identity
2. **Repertoire List**: Master view of all pieces with search and add functionality
3. **Piece Detail**: Full read-only view of individual pieces
4. **Add/Edit Form**: Comprehensive form for creating and modifying pieces

#### Design Highlights
- Interface follows Apple Human Interface Guidelines
- Intent is to honor and respect Hawaiian traditions, feedback always welcome
- Consistent typography with proper Hawaiian character support
- Intuitive navigation with clear visual hierarchy

### Privacy & Storage

- **Local-only storage**: For now all data remains on-device using SwiftData
- **No network access**: Complete offline functionality
- **No user tracking**: No analytics or telemetry yet; user data will never be shared with third parties
- **No ads**: No ads or in-app purchases, ever

### Getting Started

1. **Launch the app**: 3-second animated introduction
2. **Add your first piece**: Tap "Add your first oli or mele" or use the + button
3. **Fill in details**: Enter title, select category (Oli/Mele), add lyrics and language
4. **Build your repertoire**: Continue adding pieces to create your practice collection

### What's Next

Milestone 1 establishes the foundation for your repertoire. Future releases will include:
- **Practice mode**: Random selection and practice session management
- **Favorites**: Mark and organize your most important pieces
- **Enhanced categorization**: Additional categories beyond Oli and Mele
- **Cloud sync**: Optional backup and multi-device synchronization
- **Audio integration**: Support for audio recordings and playback

### Known Limitations

This initial release focuses on core repertoire management. The following features are planned for future milestones:
- No practice mode yet (coming in Milestone 2)
- No favorites functionality
- No thumbnail images
- No audio/video support
- No sharing features
- No cloud synchronization

### Bug Fixes & Improvements

As this is the initial release, this section will be populated in future versions based on user feedback and testing.

### Acknowledgments

Special thanks to the Bay Area hula community, especially hālau [Nā Lei Hulu i ka Wēkiu](https://naleihulu.org/).

### Support

For questions, feedback, or issues, file issues on GitHub.

---

Aloha ♥️

### Version History

| Version | Release Date | Theme |
|---------|--------------|-------|
| 0.1.0 | June 2025 | Build Your Repertoire |
