# Implementation Tasks - Practice Carousel

### Overview
This implementation plan breaks down the Practice Carousel PRD into actionable development tasks. The goal is to refine the practice experience by separating piece selection from the practice session itself through an interactive carousel interface. This will improve user control and metric accuracy while simplifying the practice screen.

### Timeline
- **Start Date**: June 10, 2025
- **Target Completion**: June 16, 2025
- **Total Duration**: 7 days

### Key Changes
1. Replace "Start Practice" button with carousel interface
2. Remove all navigation gestures from Practice Screen
3. Separate browsing from actual practice sessions
4. Simplify practice completion to single swipe gesture

### Development Phases

## Phase 1: Update Practice Tab with Carousel (Day 1-2)
**Goal**: Replace the current Practice tab UI with carousel-based selection

### Tasks:
- [x] **Remove Existing Practice Tab UI** (1 hour)
   - [x] Archive current "Start Practice" button implementation
   - [x] Remove last practiced preview card
   - [x] Keep quick stats display (streak, total pieces)
   - [x] Prepare layout for carousel integration
- [x] **Design Carousel Container** (2 hours)
   - [x] Create carousel area taking 60% of vertical space
   - [x] Position below app header, above stats
   - [x] Add visual swipe indicators (dots)
   - [x] Implement empty state for no eligible pieces
- [x] **Create Suggestion Queue Service** (2 hours)
   - [x] Extend PracticeSelectionService for queue management
   - [x] Pre-generate 5-7 suggested pieces
   - [x] Implement circular queue logic
   - [x] Maintain suggestion history for session
   - [x] Handle edge cases (0, 1, or few pieces)
- [x] **Update PracticeViewModel** (1 hour)
   - [x] Remove direct practice starting logic
   - [x] Add carousel state management
   - [x] Track current carousel position
   - [x] Separate browsing from practice state

### Verification:
- [x] Carousel container displays correctly
- [x] Stats remain visible below carousel
- [x] Empty state shows when no pieces available
- [x] View model properly manages carousel state

---

## Phase 2: Implement Carousel Component (Day 2-3)
**Goal**: Build the interactive carousel with smooth animations

### Tasks:
- [x] **Create Carousel Card View** (3 hours)
   - [x] Design card layout (80% screen width, 3:2 ratio)
   - [x] Display elements:
     - [x] Piece title (large, prominent)
     - [x] Category badge (Oli/Mele)
     - [x] First 3-4 lines of lyrics preview
   - [x] Add elevated shadow for depth
   - [x] 16pt rounded corners
   - [x] Scale animation on tap
- [x] **Implement Carousel Scrolling** (3 hours)
   - [x] Use ScrollView with paging enabled
   - [x] Implement snap-to-card behavior
   - [x] Add smooth swipe animations
   - [x] Configure gesture recognizers:
     - [x] Horizontal swipe/drag for navigation
     - [x] Tap for selection
   - [x] Lazy loading for performance
- [x] **Add Visual Indicators** (1 hour)
   - [x] Page dots below carousel
   - [x] Highlight current position
   - [x] Fade dots at edges for circular indication
   - [x] Update dots on scroll
- [x] **Connect to Suggestion Queue** (2 hours)
   - [x] Load initial suggestions on appear
   - [x] Update queue on navigation
   - [x] Preload adjacent cards
   - [x] Handle circular navigation

### Verification:
- [x] Smooth 60fps scrolling performance
- [x] Cards snap correctly
- [x] Visual indicators update properly
- [x] Tap to select works reliably
- [x] Works with 1, few, and many pieces

---

## Phase 3: Simplify Practice Screen (Day 3-4)
**Goal**: Remove navigation gestures and simplify the practice interface

### Tasks:
- [x] **Remove Navigation Gestures** (2 hours)
   - [x] Remove left/right swipe recognizers
   - [x] Remove piece switching logic
   - [x] Remove session history navigation
   - [x] Clean up gesture-related code
- [x] **Simplify Practice Screen UI** (2 hours)
   - [x] Remove "Done" button
   - [x] Keep existing elements:
     - [x] Title and category
     - [x] Full lyrics (scrollable)
     - [x] Language indicator
     - [x] Translation toggle
     - [x] Favorite button
     - [x] "Details" link
   - [x] Focus on single-piece display
- [x] **Implement Single Exit Gesture** (2 hours)
   - [x] Add right swipe recognizer only
   - [x] Configure for "go back" feeling
   - [x] Add visual hint (subtle arrow or text)
   - [x] Fade hint after first successful swipe
   - [x] Smooth animation on swipe

- [x] **Update Practice Flow** (1 hour)
   - [x] Start session when screen appears
   - [x] End session on swipe right
   - [x] Handle app backgrounding
   - [x] Return to Practice tab on exit

### Verification:
- [x] Only right swipe works
- [x] No piece navigation possible
- [x] Clean, focused interface
- [x] Smooth exit animation
- [x] Session tracking accurate

---

## Phase 4: Update Session Tracking (Day 4-5)
**Goal**: Separate browsing metrics from practice metrics

### Tasks:
- [x] **Update Session Start Logic** (2 hours)
   - [x] Session starts only on PracticeScreen appear
   - [x] Remove session start from carousel browsing
   - [x] Ensure accurate timestamp capture
   - [x] Update PracticeViewModel accordingly
- [x] **Add Carousel Analytics** (2 hours)
   - [x] Track carousel interactions separately in `CarouselMetrics` struct:
     - [x] `piecesBrowsed: Int`
     - [x] `browsingDuration: TimeInterval`
     - [x] `selectionIndex: Int`
   - [x] Log browsing patterns
   - [x] Store for future analysis
- [x] **Update Practice Metrics** (1 hour)
   - [x] Update "lastPracticed" only on actual practice
   - [x] Ensure session duration accuracy
   - [x] Fix any metric calculation issues
   - [x] Update ProfileViewModel statistics
- [x] **Migration Logic** (1 hour)
   - [x] Ensure existing practice history remains valid
   - [x] No data model changes needed
   - [x] Test with existing user data

### Verification:
- [x] Browsing doesn't affect practice metrics
- [x] Session duration accurate
- [x] Last practiced updates correctly
- [x] Historical data preserved

---

## Phase 5: Migration and User Education (Day 5)
**Goal**: Help users adapt to the new interaction pattern

### Tasks:
- [x] **Create Onboarding Tooltips** (2 hours)
   - [x] First launch tooltip: "Swipe to browse pieces"
   - [x] Position above carousel
   - [x] Auto-dismiss after 5 seconds or interaction
   - [x] Store shown state in UserDefaults
- [x] **Add Practice Screen Hint** (1 hour)
   - [x] Gesture hint: "Swipe right to finish"
   - [x] Subtle animation on right edge
   - [x] Fade after first successful swipe
   - [x] Don't show again in session
- [x] **Update Help/Tutorial Content** (1 hour)
   - [x] Update any help text
   - [x] Create migration notes
   - [x] Document new interaction patterns

### Verification:
- [x] Tooltips show once only
- [x] Hints are helpful but not intrusive
- [x] Users understand new patterns

---

## Phase 6: Testing and Polish (Day 6-7)
**Goal**: Ensure smooth user experience and meet all requirements

### Tasks:
- [x] **Performance Testing** (2 hours)
   - [x] Measure carousel scroll performance
   - [x] Check memory usage
   - [x] Optimize if needed
- [x] **Edge Case Testing** (2 hours)
   - [x] No eligible pieces
   - [x] Single piece only
   - [x] Rapid carousel swiping
   - [x] Interruption scenarios
   - [x] Device rotation
- [x] **Accessibility** (2 hours)
   - [x] VoiceOver navigation
   - [x] Proper accessibility hints
   - [x] Focus management
   - [x] Gesture alternatives
- [x] **UI Polish** (3 hours)
   - [x] Smooth animations everywhere
   - [x] Haptic feedback on interactions
   - [x] Loading states
   - [x] Error handling
   - [x] Visual consistency
- [x] **Integration Testing** (2 hours)
   - [x] Full user flow testing
   - [x] Cross-feature integration
   - [x] Data consistency
   - [x] Tab switching behavior

### Verification:
- [x] All PRD requirements met
- [x] Performance targets achieved
- [x] Accessibility compliant
- [x] No critical bugs
- [x] Ready for release

---

## Risk Mitigation

### Technical Risks
1. **Carousel Performance**
   - Mitigation: Lazy loading, view recycling
   - Time buffer: 2 hours
   
2. **Gesture Recognition Changes**
   - Mitigation: Thorough testing of all scenarios
   - Time buffer: 1 hour

3. **User Adaptation**
   - Mitigation: Clear onboarding, visual hints
   - Time buffer: 2 hours

### Design Risks
1. **Carousel Not Intuitive**
   - Mitigation: Follow iOS patterns, test with users
   - Have fallback to list selection

2. **Loss of Features**
   - Mitigation: Ensure all M2 value preserved
   - Quick practice still one tap away

---

## Dependencies

### From Previous Milestones
- Working practice selection algorithm (M2)
- Session tracking infrastructure (M2)
- Tab navigation system (M2)

### New Components
- Carousel component implementation
- Updated gesture handling
- Onboarding tooltip system

---

## Definition of Done

### Implementation Complete
- [x] All PRD features implemented
- [x] Previous functionality preserved
- [x] New UI components polished
- [x] Gestures work as specified

### Quality Assurance
- [x] All test cases pass
- [x] Performance benchmarks met
- [x] Accessibility audit complete
- [x] No critical bugs

### Release Ready
- [x] Release notes prepared
- [x] Ready for v0.3.0 tag
