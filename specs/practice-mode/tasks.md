# Implementation Tasks - Practice Mode

### Overview
This implementation plan breaks down the Practice Mode PRD into actionable development tasks with clear dependencies and time estimates. The goal is to deliver a working practice mode with tab navigation, weighted random selection, and basic session tracking within one week.

### Timeline
- **Start Date**: June 3, 2025
- **Target Completion**: June 9, 2025
- **Total Duration**: 7 days

### Development Phases

## Phase 1: Data Model Updates & Tab Navigation (Day 1)
**Goal**: Update data model and implement tab navigation structure

### Tasks:
- [x] **Update Piece Model** (1 hour)
   - [x] Add new fields to existing Piece model:
     - [x] `isFavorite: Bool = false`
     - [x] `includedInPractice: Bool = true`
     - [x] `lastPracticed: Date?`
     - [x] `englishTranslation: String?`
   - [x] Create migration strategy for existing data
   - [x] Test data persistence with new fields
- [x] **Create PracticeSession Model** (30 min)
  - [x] `id: UUID`
  - [x] `pieceId: UUID`
  - [x] `startTime: Date`
  - [x] `endTime: Date?`
- [x] **Implement Tab Bar Navigation** (2 hours)
   - [x] Create TabView in HaumanaApp
   - [x] Configure 3 tabs: Practice, Repertoire, Profile
   - [x] Set up tab icons:
     - [x] Practice: `practice.svg` (unselected), `practice.fill.svg` (selected)
     - [x] Repertoire: `repertoire.svg` (unselected), `repertoire.fill.svg` (selected)
     - [x] Profile: `profile.svg` (unselected), `profile.fill.svg` (selected)
   - [x] Import and configure SVG assets
   - [x] Test tab switching and state preservation
- [x] **Create Repository Updates** (1 hour)
   - [x] Update PieceRepository with favorite/practice toggle methods
   - [x] Add PracticeSessionRepository
   - [x] Implement getLastPracticed methods
   - [x] Add filtering by practice availability

### Verification:
- [x] New model fields persist correctly
- [x] Existing data migrates without loss
- [x] Tab navigation works smoothly
- [x] Icons display correctly in both states

---

## Phase 2: Practice Tab & Random Selection (Day 2)
**Goal**: Implement Practice tab UI and weighted random selection algorithm

### Tasks:
- [x] **Create Practice Tab View** (2 hours)
   - [x] Design main practice tab layout
   - [x] "Start Practice" button (prominent)
   - [x] Last practiced piece preview card
   - [x] Quick stats display:
     - [x] Practice streak calculation
     - [x] Total pieces count
     - [x] Available for practice count
   - [x] Empty state for no available pieces
- [x] **Implement Random Selection Algorithm** (2 hours)
   - [x] Create PracticeSelectionService
   - [x] Implement weighted selection:
     - [x] Priority 1: Favorites not practiced in 7+ days
     - [x] Priority 2: Non-favorites not practiced in 7+ days
     - [x] Priority 3: All other eligible pieces
   - [x] Handle edge cases (no pieces, single piece)
   - [x] Unit test the algorithm thoroughly
- [x] **Create PracticeViewModel** (1 hour)
   - [x] Manage practice state
   - [x] Track current session
   - [x] Handle piece selection
   - [x] Maintain session history during practice

### Verification:
- [x] Random selection feels fair
- [x] Favorites get appropriate priority
- [x] Recently practiced pieces appear less often
- [x] Empty state displays correctly

---

## Phase 3: Practice Screen Implementation (Day 3-4)
**Goal**: Build the full practice session interface with gestures

### Tasks:
- [x] **Create Practice Screen View** (3 hours)
   - [x] Full-screen modal presentation
   - [x] Display piece information:
     - [x] Title (prominent)
     - [x] Category badge
     - [x] Lyrics (scrollable)
     - [x] Language indicator
   - [x] Favorite toggle button
   - [x] "Done" button
   - [x] "Details" link
- [x] **Implement Translation Display** (2 hours)
   - [x] "Show Translation" button (only if translation exists)
   - [x] Portrait layout: translation below original
   - [x] Landscape layout: side-by-side with line alignment
   - [x] Smooth animation for show/hide
   - [x] Line-by-line vertical alignment logic
- [x] **Add Gesture Controls** (2 hours)
   - [x] Swipe left: next random piece
   - [x] Swipe right: previous piece (session history)
   - [x] Swipe up: end practice session
   - [x] Gesture recognizer configuration
   - [x] Visual feedback for gestures
- [x] **Session Tracking Integration** (1 hour)
   - [x] Start session on piece display
   - [x] End session on done/swipe up
   - [x] Handle app backgrounding
   - [x] Update lastPracticed timestamp

### Verification:
- [x] All gestures work smoothly
- [x] Translation display aligns correctly
- [x] Session tracking is accurate
- [x] Landscape/portrait transitions are smooth

---

## Phase 4: Repertoire Tab Updates (Day 4-5)
**Goal**: Enhance repertoire with filtering and new fields

### Tasks:
- [x] **Update Repertoire List View** (2 hours)
   - [x] Add filter chips below search:
     - [x] All pieces
     - [x] Oli only
     - [x] Mele only
     - [x] Favorites only
   - [x] Update list items to show:
     - [x] Favorite star icon
     - [x] Practice availability indicator
   - [x] Implement filter logic in view model
- [x] **Update Add/Edit Form** (2 hours)
   - [x] Add "Include in Practice" toggle
     - [x] Below category selection
     - [x] Default: ON
   - [x] Add "English Translation" field
     - [x] Multiline text field
     - [x] Below original lyrics
     - [x] Minimum 5 lines visible
   - [x] Add favorite toggle in navigation bar
- [x] **Update Piece Detail View** (1 hour)
   - [x] Display new fields
   - [x] Add "Practice Now" button
   - [x] Show practice availability status
   - [x] Update favorite toggle

### Verification:
- [x] Filters work correctly
- [x] New form fields save properly
- [x] Practice availability updates immediately
- [x] Favorite status persists

---

## Phase 5: Profile Tab Implementation (Day 5-6)
**Goal**: Create profile tab with account info and practice history

### Tasks:
- [x] **Create Profile Tab View** (2 hours)
   - [x] User section:
     - [x] Google account avatar (placeholder for now)
     - [x] Display name
     - [x] Email address
   - [x] Practice statistics:
     - [x] Current streak calculation
     - [x] Total practice sessions
     - [x] Most practiced piece
   - [x] App version info
- [x] **Implement Practice History** (2 hours)
   - [x] Recent sessions list (last 10)
   - [x] Session items show:
     - [x] Piece title
     - [x] Date/time
     - [x] Duration (calculated)
   - [x] Tap to view piece details
   - [x] Pull to refresh
- [x] **Create ProfileViewModel** (1 hour)
   - [x] Calculate practice statistics
   - [x] Fetch recent sessions
   - [x] Format display data
   - [x] Handle data updates

### Verification:
- [x] Statistics calculate correctly
- [x] History displays accurately
- [x] Navigation to pieces works
- [x] Data updates in real-time

---

## Phase 6: Integration & Polish (Day 6-7)
**Goal**: Complete integration and polish for release

### Tasks:
- [x] **Cross-Feature Integration** (2 hours)
   - [x] Test all navigation paths
   - [x] Verify data consistency
   - [x] Ensure favorites sync across views
   - [x] Test practice flow end-to-end

- [x] **Performance Optimization** (2 hours)
   - [x] Profile random selection algorithm
   - [x] Optimize translation display
   - [x] Memory usage in practice screen
   - [x] Tab switching performance

- [x] **Edge Case Handling** (2 hours)
   - [x] No pieces available for practice
   - [x] Single piece scenarios
   - [x] Very long translations
   - [x] Rapid gesture inputs
   - [x] App interruption during practice
- [x] **UI Polish** (2 hours)
   - [x] Gesture feedback animations
   - [x] Translation show/hide animations
   - [x] Loading states
   - [x] Error messages
   - [x] Haptic feedback
- [x] **Comprehensive Testing** (3 hours)
   - [x] Full test checklist from PRD
   - [x] Device rotation during practice
   - [x] Memory leak testing
   - [x] Data migration verification
   - [x] Accessibility testing

### Verification:
- [x] All PRD requirements met
- [x] No critical bugs
- [x] Performance targets achieved
- [x] Polish items completed

---

## Risk Mitigation

### Technical Risks
1. **Gesture Conflicts**
   - Mitigation: Careful gesture recognizer priority
   - Time buffer: 2 hours

2. **Translation Alignment Complexity**
   - Mitigation: Start with simple layout, iterate
   - Time buffer: 3 hours

3. **Performance with Many Sessions**
   - Mitigation: Limit history display, implement pagination later
   - Time buffer: 1 hour

### Schedule Risks
1. **Algorithm Complexity**
   - Mitigation: Start simple, enhance if time permits
   - Have basic random selection as fallback

2. **Cross-Feature Dependencies**
   - Mitigation: Develop in parallel where possible
   - Clear interface definitions early

---

## Dependencies

### Asset Requirements
- [x] Tab bar icons (all created):
  - [x] practice.svg / practice.fill.svg
  - [x] repertoire.svg / repertoire.fill.svg  
  - [x] profile.svg / profile.fill.svg

### Data Migration
- Ensure backward compatibility
- Test with production data copies
- Have rollback strategy

---

## Definition of Done

### Feature Complete
- [x] All PRD features implemented
- [x] M1 functionality preserved
- [x] New models integrated
- [x] Tab navigation smooth

### Quality Metrics
- [x] All gestures work reliably
- [x] <300ms practice screen load time

### Testing Complete
- [x] Unit tests for algorithm
- [x] UI tests for critical paths
- [x] Manual test checklist complete

---

## Next Steps (Post-M2)
1. Gather practice mode feedback
2. Plan authentication (M3)
3. Design cloud sync architecture
4. Consider audio recording features