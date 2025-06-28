# Product Requirements Document - Practice Mode (Milestone 2)

### Document Information
- **Version**: 1.0
- **Date**: June 2025
- **Milestone**: 2 - Practice Mode
- **Timeline**: 1 week
- **Theme**: "Start Practicing"

### Executive Summary
Milestone 2 introduces the core practice functionality to Haumana. Users can engage in randomized practice sessions with their repertoire, track their practice history, and organize pieces with favorites and practice preferences. This milestone transforms the app from a simple repertoire manager into an active practice companion.

### Goals & Success Metrics

#### Primary Goals
1. Enable randomized practice sessions with smart selection
2. Track practice session history
3. Provide intuitive practice flow with gesture controls
4. Support bilingual practice with optional translations
5. Introduce tab-based navigation

#### Success Metrics
- Users complete 5+ practice sessions
- Random selection feels fair and appropriate
- Quick access to practice (< 2 taps from launch)
- Smooth gesture-based navigation during practice

### Functional Requirements

#### 1. Tab Navigation Structure
**Description**: Replace single-screen navigation with tab bar

**Requirements**:
- 3 tabs at bottom of screen:
  - **Practice** (default/home tab)
  - **Repertoire** 
  - **Profile**
- Icons and labels for each tab
- Maintain state when switching between tabs
- Visual indicator for active tab

#### 2. Practice Tab (Home)
**Description**: Quick access point for starting practice sessions

**Requirements**:
- Large, prominent "Start Practice" button
- Display last practiced piece (if any) with:
  - Title
  - Time since last practice
  - Thumbnail (if available)
- Quick stats section:
  - Current practice streak (days)
  - Total pieces in repertoire
  - Pieces available for practice
- Empty state if no pieces marked for practice:
  - Message: "No pieces available for practice"
  - "Go to Repertoire" button

**Interactions**:
- Tap "Start Practice" → Random selection → Practice Screen
- Tap last practiced piece → Practice that specific piece

#### 3. Practice Screen
**Description**: Full-screen practice session interface

**Requirements**:
- Display elements:
  - Piece title (prominent)
  - Category badge (Oli/Mele)
  - Original language lyrics (scrollable)
  - Language indicator
  - Favorite button (star icon)
  - "Show Translation" button (if translation exists)
  - "Done" button (top right or bottom)
- Translation display:
  - Hidden by default
  - One-tap to show/hide
  - Portrait: Translation appears below original
  - Landscape: Side-by-side with line-by-line alignment
  - Each line aligns vertically between languages
  - Lines can wrap independently as needed
- Gesture controls:
  - Swipe left → Next random piece
  - Swipe right → Previous piece (from session history)
  - Swipe up → End practice session
- Additional controls:
  - "Details" button → Navigate to Piece Detail screen
  - Favorite toggle → Update favorite status immediately

**Technical Notes**:
- Maintain practice session history during session
- Original language always visible (cannot be hidden)
- Support smooth transitions between pieces

#### 4. Updated Repertoire Tab
**Description**: Enhanced list view with filtering

**Filter Options**:
- All pieces
- Oli only
- Mele only
- Favorites only

**Requirements**:
- Filter chips below search bar
- Active filter highlighted
- Piece count for active filter
- List items show:
  - Favorite star (filled/unfilled)
  - New indicator for practice availability
- Maintain existing functionality from M1

#### 5. Profile Tab
**Description**: User account info and minimal practice history

**Requirements**:
- User section:
  - Google account avatar
  - Display name
  - Email address
- Practice stats:
  - Current streak (days)
  - Total practice sessions
  - Most practiced piece
- Recent practice history:
  - Last 10 sessions
  - Each showing: piece title, date/time
  - Tap session → View piece details
- App info:
  - Version number
  - About link

#### 6. Random Selection Algorithm
**Description**: Weighted random selection for fair practice distribution

**Algorithm**:
1. Filter to only pieces where `includeInPractice = true`
2. If no pieces available, show empty state
3. Weight pieces by priority:
   - Priority 1: Favorites not practiced in 7+ days
   - Priority 2: Non-favorites not practiced in 7+ days  
   - Priority 3: All other eligible pieces
4. Within each priority tier, select randomly
5. Avoid repeating the same piece consecutively (unless only 1 piece available)

#### 7. Practice Session Tracking
**Description**: Minimal session data for history and algorithm

**Data Model**:
```swift
@Model
class PracticeSession {
    var id: UUID
    var pieceId: UUID
    var startTime: Date
    var endTime: Date?
}
```

**Requirements**:
- Create session when piece displayed in practice mode
- Update endTime when:
  - User taps "Done"
  - User swipes up
  - User swipes to different piece
  - App goes to background
- Store locally with SwiftData
- Design for future cloud sync

#### 8. Updated Piece Model
**Description**: Add fields for M2 features

**New Fields**:
```swift
extension Piece {
    var isFavorite: Bool = false
    var includeInPractice: Bool = true
    var lastPracticed: Date?
    var englishTranslation: String?
}
```

#### 9. Updated Add/Edit Screen
**Description**: Add new controls for M2 features

**New Form Fields**:
- **Include in Practice** toggle (default: ON)
  - Label: "Include in practice sessions"
  - Below category selection
- **English Translation** (optional)
  - Multiline text field
  - Below original lyrics
  - Placeholder: "English translation (optional)"
  - Minimum 5 lines visible
- **Favorite** toggle
  - In navigation bar as star button
  - Or inline in form

### Non-Functional Requirements

#### Performance
- Random selection: < 100ms
- Practice screen transition: < 300ms
- Session tracking: Asynchronous, no UI blocking
- Support 50+ practice sessions without degradation

#### Usability
- Gesture recognizers must not conflict
- Clear visual feedback for all gestures
- Smooth animations for piece transitions
- Maintain readability with translation visible

#### Data Migration
- Existing pieces get default values:
  - `isFavorite = false`
  - `includeInPractice = true`
  - `lastPracticed = nil`
  - `englishTranslation = nil`

### User Flows

#### Quick Practice Flow
1. Launch app → Practice tab (default)
2. Tap "Start Practice"
3. Random piece selected and displayed
4. User practices (can swipe left/right for different pieces)
5. Swipe up or tap "Done"
6. Return to Practice tab

#### Practice Specific Piece Flow
1. Repertoire tab → Filter/search
2. Tap piece → Piece details
3. Tap "Practice Now"
4. Practice screen with that piece
5. Normal practice flow continues

#### Translation Toggle Flow
1. During practice → See piece with original lyrics
2. Tap "Show Translation"
3. Translation appears (below or side-by-side)
4. Tap "Hide Translation"
5. Returns to original only

### Out of Scope for M2
- Audio recording
- Practice reminders/notifications
- Detailed analytics
- Practice goals
- Social sharing
- Multiple practice modes
- Pronunciation guides
- History tab (full version)
- Settings screen
- Cloud sync

### Edge Cases & Error Handling

#### No Pieces Available
- No pieces in repertoire → Empty state in Practice tab
- All pieces excluded from practice → Specific message
- Suggest adding pieces or enabling practice

#### Single Piece Scenarios
- Only 1 piece available → No swipe gestures
- Previous piece history empty → Swipe right does nothing

#### Translation Display
- Very long translations → Scrollable independently
- Missing translation → "Show Translation" button hidden
- Landscape rotation during practice → Smooth reflow

### Accessibility Requirements
- Gesture alternatives for all swipe actions
- VoiceOver announces practice state changes
- Focus management during piece transitions
- Clear labels for all interactive elements

### Testing Checklist
- [ ] Practice 20+ different pieces
- [ ] Test weighted random selection
- [ ] Verify favorites affect selection
- [ ] Test all gesture controls
- [ ] Rotate device during practice
- [ ] Toggle translations on/off
- [ ] Exclude all pieces from practice
- [ ] Practice with only 1 piece
- [ ] Background app during practice
- [ ] Check session history accuracy
- [ ] Filter repertoire by all options
- [ ] Verify data migration

### Release Criteria
1. All M1 functionality preserved
2. Tab navigation implemented
3. Practice mode fully functional
4. Session tracking working
5. Random selection algorithm verified
6. No critical bugs
7. Performance targets met

### Future Considerations (Post-M2)
- Rich practice history with calendar view
- Practice streaks and achievements
- Audio recording capability
- Practice timer and goals
- Export practice data
- Social features
- Advanced practice modes