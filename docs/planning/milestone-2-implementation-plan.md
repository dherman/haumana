# Milestone 2 Implementation Plan
## Start Practicing

### Overview
This implementation plan breaks down the Milestone 2 PRD into actionable development tasks with clear dependencies and time estimates. The goal is to deliver a working practice mode with tab navigation, weighted random selection, and basic session tracking within one week.

### Timeline
- **Start Date**: June 3, 2025
- **Target Completion**: June 9, 2025
- **Total Duration**: 7 days

### Development Phases

## Phase 1: Data Model Updates & Tab Navigation (Day 1)
**Goal**: Update data model and implement tab navigation structure

### Tasks:
1. **Update Piece Model** (1 hour)
   - Add new fields to existing Piece model:
   ```swift
   extension Piece {
       var isFavorite: Bool = false
       var includeInPractice: Bool = true
       var lastPracticed: Date?
       var englishTranslation: String?
   }
   ```
   - Create migration strategy for existing data
   - Test data persistence with new fields

2. **Create PracticeSession Model** (30 min)
   ```swift
   @Model
   class PracticeSession {
       var id: UUID
       var pieceId: UUID
       var startTime: Date
       var endTime: Date?
   }
   ```

3. **Implement Tab Bar Navigation** (2 hours)
   - Create TabView in HaumanaApp
   - Configure 3 tabs: Practice, Repertoire, Profile
   - Set up tab icons:
     - Practice: `practice.svg` (unselected), `practice.fill.svg` (selected)
     - Repertoire: `repertoire.svg` (unselected), `repertoire.fill.svg` (selected)
     - Profile: `profile.svg` (unselected), `profile.fill.svg` (selected)
   - Import and configure SVG assets
   - Test tab switching and state preservation

4. **Create Repository Updates** (1 hour)
   - Update PieceRepository with favorite/practice toggle methods
   - Add PracticeSessionRepository
   - Implement getLastPracticed methods
   - Add filtering by practice availability

### Verification:
- [x] New model fields persist correctly
- [x] Existing data migrates without loss
- [x] Tab navigation works smoothly
- [x] Icons display correctly in both states

---

## Phase 2: Practice Tab & Random Selection (Day 2)
**Goal**: Implement Practice tab UI and weighted random selection algorithm

### Tasks:
1. **Create Practice Tab View** (2 hours)
   - Design main practice tab layout
   - "Start Practice" button (prominent)
   - Last practiced piece preview card
   - Quick stats display:
     - Practice streak calculation
     - Total pieces count
     - Available for practice count
   - Empty state for no available pieces

2. **Implement Random Selection Algorithm** (2 hours)
   - Create PracticeSelectionService
   - Implement weighted selection:
     ```swift
     // Priority 1: Favorites not practiced in 7+ days
     // Priority 2: Non-favorites not practiced in 7+ days
     // Priority 3: All other eligible pieces
     ```
   - Handle edge cases (no pieces, single piece)
   - Unit test the algorithm thoroughly

3. **Create PracticeViewModel** (1 hour)
   - Manage practice state
   - Track current session
   - Handle piece selection
   - Maintain session history during practice

### Verification:
- [x] Random selection feels fair
- [x] Favorites get appropriate priority
- [x] Recently practiced pieces appear less often
- [x] Empty state displays correctly

---

## Phase 3: Practice Screen Implementation (Day 3-4)
**Goal**: Build the full practice session interface with gestures

### Tasks:
1. **Create Practice Screen View** (3 hours)
   - Full-screen modal presentation
   - Display piece information:
     - Title (prominent)
     - Category badge
     - Lyrics (scrollable)
     - Language indicator
   - Favorite toggle button
   - "Done" button
   - "Details" link

2. **Implement Translation Display** (2 hours)
   - "Show Translation" button (only if translation exists)
   - Portrait layout: translation below original
   - Landscape layout: side-by-side with line alignment
   - Smooth animation for show/hide
   - Line-by-line vertical alignment logic

3. **Add Gesture Controls** (2 hours)
   - Swipe left: next random piece
   - Swipe right: previous piece (session history)
   - Swipe up: end practice session
   - Gesture recognizer configuration
   - Visual feedback for gestures

4. **Session Tracking Integration** (1 hour)
   - Start session on piece display
   - End session on done/swipe up
   - Handle app backgrounding
   - Update lastPracticed timestamp

### Verification:
- [x] All gestures work smoothly
- [x] Translation display aligns correctly
- [x] Session tracking is accurate
- [x] Landscape/portrait transitions are smooth

---

## Phase 4: Repertoire Tab Updates (Day 4-5)
**Goal**: Enhance repertoire with filtering and new fields

### Tasks:
1. **Update Repertoire List View** (2 hours)
   - Add filter chips below search:
     - All pieces
     - Oli only
     - Mele only
     - Favorites only
   - Update list items to show:
     - Favorite star icon
     - Practice availability indicator
   - Implement filter logic in view model

2. **Update Add/Edit Form** (2 hours)
   - Add "Include in Practice" toggle
     - Below category selection
     - Default: ON
   - Add "English Translation" field
     - Multiline text field
     - Below original lyrics
     - Minimum 5 lines visible
   - Add favorite toggle in navigation bar

3. **Update Piece Detail View** (1 hour)
   - Display new fields
   - Add "Practice Now" button
   - Show practice availability status
   - Update favorite toggle

### Verification:
- [x] Filters work correctly
- [x] New form fields save properly
- [x] Practice availability updates immediately
- [x] Favorite status persists

---

## Phase 5: Profile Tab Implementation (Day 5-6)
**Goal**: Create profile tab with account info and practice history

### Tasks:
1. **Create Profile Tab View** (2 hours)
   - User section:
     - Google account avatar (placeholder for now)
     - Display name
     - Email address
   - Practice statistics:
     - Current streak calculation
     - Total practice sessions
     - Most practiced piece
   - App version info

2. **Implement Practice History** (2 hours)
   - Recent sessions list (last 10)
   - Session items show:
     - Piece title
     - Date/time
     - Duration (calculated)
   - Tap to view piece details
   - Pull to refresh

3. **Create ProfileViewModel** (1 hour)
   - Calculate practice statistics
   - Fetch recent sessions
   - Format display data
   - Handle data updates

### Verification:
- [x] Statistics calculate correctly
- [x] History displays accurately
- [x] Navigation to pieces works
- [x] Data updates in real-time

---

## Phase 6: Integration & Polish (Day 6-7)
**Goal**: Complete integration and polish for release

### Tasks:
1. **Cross-Feature Integration** (2 hours)
   - Test all navigation paths
   - Verify data consistency
   - Ensure favorites sync across views
   - Test practice flow end-to-end

2. **Performance Optimization** (2 hours)
   - Profile random selection algorithm
   - Optimize translation display
   - Memory usage in practice screen
   - Tab switching performance

3. **Edge Case Handling** (2 hours)
   - No pieces available for practice
   - Single piece scenarios
   - Very long translations
   - Rapid gesture inputs
   - App interruption during practice

4. **UI Polish** (2 hours)
   - Gesture feedback animations
   - Translation show/hide animations
   - Loading states
   - Error messages
   - Haptic feedback

5. **Comprehensive Testing** (3 hours)
   - Full test checklist from PRD
   - Device rotation during practice
   - Memory leak testing
   - Data migration verification
   - Accessibility testing

### Verification:
- [x] All PRD requirements met
- [x] No critical bugs
- [x] Performance targets achieved
- [x] Polish items completed

---

## Daily Schedule

### Day 1 (Tuesday, June 3)
- Morning: Data model updates, migrations
- Afternoon: Tab navigation implementation
- Evening: Repository updates, icon integration

### Day 2 (Wednesday, June 4)
- Morning: Practice tab UI
- Afternoon: Random selection algorithm
- Evening: Algorithm testing and refinement

### Day 3 (Thursday, June 5)
- Morning: Practice screen layout
- Afternoon: Translation display logic
- Evening: Begin gesture implementation

### Day 4 (Friday, June 6)
- Morning: Complete gesture controls
- Afternoon: Repertoire tab updates
- Evening: Add/Edit form enhancements

### Day 5 (Saturday, June 7)
- Morning: Profile tab implementation
- Afternoon: Practice history and stats
- Evening: Begin integration testing

### Day 6 (Sunday, June 8)
- Morning: Performance optimization
- Afternoon: Edge case handling
- Evening: UI polish

### Day 7 (Monday, June 9)
- Morning: Final testing
- Afternoon: Bug fixes
- Evening: Prepare for release

---

## Technical Considerations

### Tab Bar Implementation
```swift
TabView {
    PracticeTabView()
        .tabItem {
            Label("Practice", image: "practice")
        }
    
    RepertoireListView()
        .tabItem {
            Label("Repertoire", image: "repertoire")
        }
    
    ProfileView()
        .tabItem {
            Label("Profile", image: "profile")
        }
}
```

### Practice Screen Presentation
```swift
.fullScreenCover(isPresented: $showingPractice) {
    PracticeScreenView(piece: selectedPiece)
}
```

### Translation Layout Strategy
- Use GeometryReader for responsive layouts
- Calculate line heights for alignment
- Consider using matched geometry effect for animations

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
  - practice.svg / practice.fill.svg
  - repertoire.svg / repertoire.fill.svg  
  - profile.svg / profile.fill.svg

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