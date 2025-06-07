# Release Notes

## Haumana 🌺

Haumana is an iOS app designed to help students of Hawaiian art and culture manage their practice routines.

---

## Version 0.3.0 - Milestone 3 (Practice Carousel)
*Released: June 2025*

This release introduces a carousel interface that allows browsing through piece suggestions before starting practice, providing better control and more accurate practice metrics.

### New Features

#### Practice Carousel
- **Browse before practice**: Swipe through suggested pieces in the carousel
- **Visual preview**: See piece title, category, and first few lines
- **Piece suggestions**: Algorithm selects 5-7 pieces based on practice history
- **Page indicators**: Dots show current position and total pieces
- **Tap to select**: Choose any piece from the carousel to practice

#### Simplified Practice Screen
- **Single exit gesture**: Swipe right to finish practice
- **Focused interface**: Removed multi-directional navigation during practice
- **Clear workflow**: Browse pieces first, then practice without distractions

#### User Guidance
- **First-use tooltip**: "Swipe to browse pieces" appears for new users
- **Swipe hint**: Visual indicator shows how to exit practice
- **Practice guide**: Instructions available in Profile tab under "How to Use"

#### Improved Metrics
- **Accurate timing**: Practice duration excludes browsing time
- **Better tracking**: Carousel browsing tracked separately from practice

### Improvements

#### Dynamic Updates
- **Live refresh**: Carousel updates when repertoire changes
- **Smart detection**: Tracks changes to eligible pieces
- **Tab synchronization**: Updates when returning to Practice tab

#### Visual Updates
- **Loading indicator**: Shows progress when starting practice
- **Empty state**: Enhanced with animation and helpful button
- **Proper centering**: Fixed alignment issues in carousel

#### Accessibility
- **VoiceOver support**: Navigation works with screen reader
- **Descriptive labels**: Clear text for all interactive elements
- **Alternative gestures**: Escape gesture exits practice for VoiceOver users

### Bug Fixes

- Fixed carousel not updating when pieces added/removed from practice
- Fixed cards appearing off-center with multiple pieces
- Fixed single card not centered in carousel
- Fixed practice metrics including browsing time

### Performance

- Carousel handles large repertoires smoothly
- Efficient memory usage with limited queue size
- Stable behavior with rapid swiping

### Technical Details

#### New Components
- `PracticeCarousel`: Horizontal scrolling card view
- `PracticeCarouselCard`: Individual piece preview cards
- `CarouselMetrics`: Separate tracking for browsing behavior

#### Architecture Updates
- State management for carousel position
- Change detection for repertoire updates
- Separation of browsing and practice states

### Using the Carousel

1. **Browse**: Swipe left/right through suggested pieces
2. **Preview**: View title, category, and lyrics preview
3. **Select**: Tap any card to begin practice
4. **Exit**: Swipe right during practice to return

### For Existing Users

- Practice data and history preserved
- Favorites and settings unchanged
- Tooltips guide through new interface

### Known Limitations

Features planned for future releases:
- No authentication yet
- No cloud synchronization
- No audio recording
- No practice goals or timers
- No sharing features

---

## Version 0.2.0 - Milestone 2 (Start Practicing)
*Released: June 2025*

This release transforms Haumana from a repertoire manager into an active practice companion with smart random selection, session tracking, and intuitive gesture controls.

### New Features

#### Practice Mode
- **Smart random selection**: Weighted algorithm prioritizes pieces based on favorites and time since last practice
- **Gesture controls**: Swipe left for next piece, right for previous, up to end session
- **Full-screen interface**: Distraction-free practice environment with essential controls
- **Session tracking**: Automatic recording of practice time and history
- **Haptic feedback**: Tactile responses enhance gesture interactions

#### Tab Navigation
- **Practice tab** (default): Quick access to start sessions with at-a-glance statistics
- **Repertoire tab**: Enhanced with filtering and visual indicators
- **Profile tab**: View practice history, statistics, and achievements

#### Enhanced Repertoire Features
- **Favorites**: Star your most important pieces for priority in practice
- **Practice availability**: Toggle pieces on/off for practice sessions
- **Filter options**: View all, Oli only, Mele only, or favorites with item counts
- **Visual indicators**: See favorites and practice status at a glance

#### Bilingual Support
- **English translations**: Add optional translations to any piece
- **Show/hide toggle**: Control translation visibility during practice
- **Smart layouts**: Portrait shows translation below, landscape shows side-by-side
- **Line alignment**: Translations align line-by-line for easy comparison

#### Practice Statistics
- **Current streak**: Track consecutive days of practice
- **Total sessions**: See your overall practice count
- **Most practiced**: Identify your most frequently practiced piece
- **Recent history**: View last 10 sessions with duration and quick access

### User Experience Improvements

#### Quick Start
- Launch to practice in just 2 taps
- Last practiced piece shown on home screen
- Clear empty states guide new users

#### Smooth Interactions
- Animated transitions between pieces
- Spring animations for favorite toggles
- Filter chips show counts for quick overview
- Real-time updates across all tabs

#### Performance
- Random selection algorithm: <100ms
- Practice screen transitions: <300ms
- Session tracking runs asynchronously
- Supports 50+ practice sessions without degradation

### Technical Updates

#### Updated Data Model
Each piece now includes:
- `isFavorite`: Mark important pieces
- `includeInPractice`: Control practice availability
- `lastPracticed`: Track recency for smart selection
- `englishTranslation`: Optional bilingual support

#### New Practice Session Model
- Tracks start and end times
- Links to practiced pieces
- Calculates duration automatically
- Designed for future cloud sync

#### Architecture Improvements
- ViewModels for Practice and Profile tabs
- Repository pattern extended with async/await
- Real-time SwiftData queries for automatic updates
- Background session saving on app interruption

### Getting Started with Practice

1. **Mark pieces for practice**: New pieces are included by default
2. **Start practicing**: Tap the prominent button on the Practice tab
3. **Use gestures**: Swipe to navigate, tap star to favorite
4. **Track progress**: Check your stats in the Profile tab

### Gesture Reference
- **Swipe Left** → Next random piece
- **Swipe Right** → Previous piece (session history)
- **Swipe Up** → End practice session
- **Tap Star** → Toggle favorite status

### Practice Algorithm

The weighted selection ensures variety while prioritizing:
1. **Priority 1**: Favorites not practiced in 7+ days (3x weight)
2. **Priority 2**: Non-favorites not practiced in 7+ days (2x weight)
3. **Priority 3**: All other eligible pieces (1x weight)

### What's New for Existing Users

Your existing repertoire is ready for practice:
- All pieces are included in practice by default
- No pieces are favorited initially
- English translations can be added through Edit
- Practice history starts fresh

### Bug Fixes & Improvements

- Fixed: Profile tab updates immediately after practice sessions
- Improved: Filter performance with large repertoires
- Enhanced: Form validation provides clearer feedback
- Added: Haptic feedback for better interaction feel

### Known Limitations

Features planned for future milestones:
- No authentication yet (coming in Milestone 3)
- No cloud synchronization
- No audio recording
- No practice goals or timers
- No data export
- Portrait-only during practice

### Privacy & Performance

- **Still local-only**: All data remains on your device
- **No network required**: Complete offline functionality
- **Performance tested**: Smooth with 1000+ pieces and hundreds of sessions

### Acknowledgments

Mahalo to early testers for valuable feedback on practice workflows and gesture preferences.

### Support

For questions, feedback, or issues, please file issues on GitHub.

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

---

### Bug Fixes & Improvements

(This section will be populated in future versions based on user feedback and testing.)

### Acknowledgments

Special thanks to the Bay Area hula community, especially hālau [Nā Lei Hulu i ka Wēkiu](https://naleihulu.org/).

### Support

For questions, feedback, or issues, file issues on GitHub.

Aloha ♥️

### Version History

| Version | Release Date | Theme |
|---------|--------------|-------|
| 0.3.0 | June 2025 | Practice Carousel |
| 0.2.0 | June 2025 | Start Practicing |
| 0.1.0 | June 2025 | Build Your Repertoire |
