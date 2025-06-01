# Product Requirements Document - Milestone 1
## Haumana: Basic Repertoire Management

### Document Information
- **Version**: 1.0
- **Date**: June 2025
- **Milestone**: 1 - Basic Repertoire
- **Timeline**: 1 week
- **Theme**: "Build Your Repertoire"

### Executive Summary
Milestone 1 delivers the foundational repertoire management functionality for Haumana. Users can create, view, edit, and delete pieces (oli and mele) with local storage. This milestone focuses on core CRUD operations with a simple, intuitive interface that respects Hawaiian language and culture.

### Goals & Success Metrics

#### Primary Goals
1. Enable users to build their practice repertoire
2. Provide smooth CRUD operations for pieces
3. Establish the app's visual identity and cultural tone
4. Create a foundation for future features

#### Success Metrics
- Users can add 10+ pieces without performance issues
- Beta testers successfully build their repertoire
- 90% task completion rate for add/edit/delete operations
- Zero data loss during normal operations

### Functional Requirements

#### 1. Splash Screen
**Description**: Brief branded introduction shown on app launch

**Requirements**:
- Display app logo/branding from `design/splash-screen-spec.md`
- Show for exactly 3 seconds
- No version information displayed
- Smooth transition to repertoire list
- Support both portrait and landscape orientations
- Respect system dark mode setting

#### 2. Repertoire List Screen
**Description**: Main screen showing all user's pieces

**Requirements**:
- Navigation bar with "Haumana" title
- List view showing all pieces with:
  - Title (full text, wrapped if needed)
  - Category badge (Oli or Mele)
  - First 2-3 lines of lyrics as preview
- Search bar at top (requires search button tap)
- Floating "+" button for adding new pieces
- Swipe-to-delete gesture on list items
- Pull-to-refresh gesture (prepares for future sync)
- Empty state: 
  - Lehua flower illustration
  - "Start building your repertoire" message
  - "Add your first oli or mele" button

**Interactions**:
- Tap piece → Navigate to Piece Detail Screen
- Tap "+" → Navigate to Add Piece Screen
- Swipe left on piece → Show delete option
- Pull down → Refresh animation (local only for now)

#### 3. Piece Detail Screen
**Description**: Full view of a single piece

**Requirements**:
- Navigation bar with back button and "Edit" button
- Display all piece information:
  - Title (large, prominent)
  - Category badge
  - Full lyrics text (scrollable)
  - Language indicator
  - Author (if provided)
  - Notes section (if provided)
  - Source URL (if provided, tappable)
- No English translation field in M1 (deferred)
- Support landscape orientation for better reading

**Interactions**:
- Tap Edit → Navigate to Edit Piece Screen
- Tap Source URL → Open in Safari
- Back button → Return to repertoire list

#### 4. Add/Edit Piece Screen
**Description**: Form for creating or modifying pieces

**Form Fields**:
1. **Title** (Required)
   - Text field
   - Maximum 4096 characters
   - Placeholder: "Title"
   
2. **Category** (Required)
   - Segmented control: Oli | Mele
   - Default: Oli
   
3. **Lyrics** (Required)
   - Multiline text field
   - No character limit
   - Placeholder: "Enter lyrics here..."
   - Minimum 5 lines visible
   
4. **Language** (Required)
   - Dropdown picker
   - Display options: "ʻŌlelo Hawaiʻi" (default), "English"
   - Stored as ISO 639 codes: "haw" (default), "eng"
   - Note: Proper Hawaiian diacriticals must be displayed in UI
   
5. **Author** (Optional)
   - Text field
   - Placeholder: "Author (optional)"
   
6. **Source URL** (Optional)
   - Text field
   - Placeholder: "Source URL (optional)"
   - Basic URL validation
   
7. **Notes** (Optional)
   - Multiline text field
   - Placeholder: "Notes (optional)"
   - Minimum 3 lines visible

**Requirements**:
- Cancel button with confirmation if changes made
- Save button (disabled until required fields filled)
- Keyboard management (proper scrolling)
- Form validation with inline errors

### Non-Functional Requirements

#### Technical Requirements
- **Platform**: iOS only
- **Minimum iOS Version**: iOS 17.0
- **Orientation**: Portrait and landscape
- **Theme**: Support system light/dark mode
- **Storage**: SwiftData (local only)
- **Architecture**: SwiftUI + MVVM
- **No network calls** in this milestone
- **No authentication** in this milestone

#### Performance Requirements
- App launch to repertoire list: <2 seconds
- Add/Edit save operation: <500ms
- Search results: <100ms
- Support 1000+ pieces without degradation

#### Design Requirements
- Follow Apple Human Interface Guidelines
- Consistent use of Hawaiian cultural elements
- Proper display of Hawaiian diacriticals (ʻokina and kahakō)
- Accessible color contrast ratios
- Support Dynamic Type

### Data Model (Simplified for M1)

```swift
@Model
class Piece {
    var id: UUID
    var title: String
    var category: PieceCategory // enum: .oli, .mele
    var lyrics: String
    var language: String // ISO 639: "haw" or "eng"
    var author: String?
    var sourceUrl: String?
    var notes: String?
    var createdAt: Date
    var updatedAt: Date
    var isFavorite: Bool = false // For future use
}
```

### User Flows

#### Add First Piece Flow
1. Launch app → Splash (3s) → Empty repertoire
2. Tap "Add your first oli or mele"
3. Fill required fields (title, category, lyrics, language)
4. Tap Save
5. Return to repertoire list showing new piece

#### Edit Piece Flow
1. From repertoire list, tap piece
2. View piece details
3. Tap Edit
4. Modify fields
5. Tap Save
6. Return to updated piece detail view

#### Delete Piece Flow
1. From repertoire list, swipe left on piece
2. Tap Delete button
3. Confirm deletion
4. Piece removed from list

### Out of Scope for M1
- Tab bar navigation
- Practice mode
- Favorites functionality
- English translations
- Thumbnail images
- Authentication
- Cloud sync
- Practice history
- Sharing features
- Audio/video
- Categories beyond Oli/Mele

### Edge Cases & Error Handling

#### Data Validation
- Empty required fields → Inline error message
- Invalid URL format → Warning but allow save
- Extremely long text → Proper text wrapping
- Special characters → Full Unicode support

#### Error States
- Storage full → Alert with message
- Save failure → Retry option
- Corrupt data → Skip corrupted items, log error

### Accessibility Requirements
- Full VoiceOver support
- Proper accessibility labels
- Accessibility hints for actions
- Support Dynamic Type
- Minimum tap target: 44x44 points

### Testing Checklist
- [ ] Add 10+ pieces of varying lengths
- [ ] Edit each field type
- [ ] Delete pieces (single and multiple)
- [ ] Search functionality
- [ ] Orientation changes don't lose data
- [ ] Dark mode appearance
- [ ] VoiceOver navigation
- [ ] Memory usage with 100+ pieces
- [ ] Data persistence across app launches

### Release Criteria
1. All functional requirements implemented
2. No critical bugs
3. Performance metrics met
4. Accessibility audit passed
5. Beta tester feedback incorporated
6. Code review completed

### Future Considerations (Post-M1)
- Migration path for local data to cloud
- Data model extensibility for translations
- Preparation for authentication scope
- Thumbnail storage architecture
- Practice mode integration points