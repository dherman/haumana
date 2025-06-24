# Product Requirements Document - Milestone 3
## Haumana: Practice Carousel

### Document Information
- **Version**: 1.0
- **Date**: June 2025
- **Milestone**: 3 - Practice Carousel
- **Timeline**: 1 week
- **Theme**: "Preview Before Practice"

### Executive Summary
Milestone 3 refines the practice experience by separating piece selection from the practice session itself. The new carousel interface on the Practice tab allows users to preview and browse suggested pieces before committing to practice, improving user control and metric accuracy. The practice screen is simplified to focus on single-piece sessions with intuitive gesture controls.

### Goals & Success Metrics

#### Primary Goals
1. Decouple piece selection from practice sessions
2. Give users more control over what they practice
3. Improve practice metric accuracy
4. Simplify the practice screen interface
5. Create a more intuitive gesture experience

#### Success Metrics
- Users browse 2-3 pieces before selecting on average
- Practice completion rate increases by 20%
- Session duration metrics become more accurate
- Reduced confusion about navigation gestures

### Functional Requirements

#### 1. Practice Tab Carousel
**Description**: Replace "Start Practice" button with interactive carousel

**Requirements**:
- Large, prominent carousel card displaying:
  - Piece title (large, readable)
  - Category badge (Oli/Mele)
  - First 3-4 lines of lyrics (preview)
  - Visual swipe indicators (dots or arrows)
- Carousel behavior:
  - Pre-loads 5-7 suggested pieces using existing algorithm
  - Smooth horizontal scrolling with snap-to-card
  - Swipe/drag left → Next suggested piece
  - Swipe/drag right → Previous suggested piece
  - Circular navigation (wraps around)
- Tap interaction:
  - Tapping the card starts practice with that piece
  - Visual feedback on tap (scale/opacity change)
- Keep existing quick stats below carousel

**Technical Notes**:
- Lazy loading for performance
- Preload adjacent cards for smooth swiping
- Maintain suggestion history for session

#### 2. Updated Practice Screen
**Description**: Simplified single-piece practice interface

**Requirements**:
- Remove all piece navigation gestures (no left/right swipe)
- Display only the selected piece
- Keep existing UI elements:
  - Piece title and category
  - Full lyrics (scrollable)
  - Language indicator
  - Translation toggle (if applicable)
  - Favorite button
  - "Details" link
- Single gesture control:
  - Swipe right → End practice and return to Practice tab
  - Visual hint for swipe gesture (subtle arrow or text)
- Remove "Done" button (gesture replaces it)

**Behavior**:
- Session starts when screen appears
- Session ends on swipe right or app background
- No piece switching within practice screen

#### 3. Session Tracking Updates
**Description**: More accurate practice metrics

**Changes**:
- Session starts only when Practice Screen opens
- Browsing carousel does NOT count as practice
- Track carousel interactions separately:
  - Number of pieces browsed
  - Time spent browsing
  - Selection patterns
- Update "last practiced" only for actual practice

#### 4. Migration from Current Design

**User Communication**:
- One-time tooltip on first launch: "Swipe to browse pieces"
- Gesture hint on practice screen: "Swipe right to finish"

**Data Migration**:
- No data model changes required
- Existing practice history remains valid

### Non-Functional Requirements

#### Performance
- Carousel swipe response: <16ms (60fps)
- Card content load: <100ms
- Smooth animations even with 1000+ pieces

#### Usability
- Clear visual affordances for swiping
- Consistent with iOS carousel patterns
- Accessible via VoiceOver with proper hints

### User Flows

#### Browse and Practice Flow
1. Open Practice tab → See suggested piece in carousel
2. Swipe left/right → Browse other suggestions
3. Find interesting piece → Tap card
4. Practice screen opens → Session begins
5. Read/practice piece → Swipe right when done
6. Return to Practice tab → See next suggestion

#### Quick Practice Flow
1. Open Practice tab → See suggested piece
2. Immediately tap → Start practicing
3. Swipe right → Return to browse more

### Out of Scope
- Customizing suggestion algorithm
- Saving/bookmarking suggestions
- Practice goals or timers
- Multiple pieces per session
- Landscape carousel layout

### Edge Cases

#### No Eligible Pieces
- Show empty state message in carousel area
- Direct user to Repertoire tab

#### Single Eligible Piece
- Carousel shows only one card
- No swipe indicators
- Tapping still works normally

#### Rapid Swiping
- Queue swipes but maintain smooth animation
- Prevent accidental practice start

### Visual Design Guidelines

#### Carousel Card
- 80% of screen width
- 3:2 aspect ratio
- Elevated shadow for depth
- Rounded corners (16pt radius)
- Clear typography hierarchy

#### Swipe Indicators
- Subtle dots below carousel
- Highlight current position
- Fade in/out at edges

#### Practice Screen Updates
- Add subtle right-edge visual hint
- Fade hint after first successful swipe

### Testing Requirements

- [ ] Carousel loads with suggestions
- [ ] Smooth swiping between cards
- [ ] Tap to start practice works
- [ ] Practice screen shows single piece
- [ ] Swipe right ends session
- [ ] Metrics track correctly
- [ ] Works with 0, 1, and many pieces
- [ ] VoiceOver navigation works
- [ ] Performance remains smooth

### Release Notes Preview

**What's New:**
- Preview pieces before you practice
- Swipe through personalized suggestions
- Simplified practice screen
- More accurate practice tracking

**Changes:**
- Practice tab now shows piece carousel
- Swipe right to end practice (replaces Done button)
- Browsing doesn't count as practice time