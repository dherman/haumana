# Milestone 3 Implementation Plan
## Practice Carousel - Preview Before Practice

### Overview
This implementation plan breaks down the Milestone 3 PRD into actionable development tasks. The goal is to refine the practice experience by separating piece selection from the practice session itself through an interactive carousel interface. This will improve user control and metric accuracy while simplifying the practice screen.

### Timeline
- **Start Date**: June 10, 2025
- **Target Completion**: June 16, 2025
- **Total Duration**: 7 days

### Key Changes from Milestone 2
1. Replace "Start Practice" button with carousel interface
2. Remove all navigation gestures from Practice Screen
3. Separate browsing from actual practice sessions
4. Simplify practice completion to single swipe gesture

### Development Phases

## Phase 1: Update Practice Tab with Carousel (Day 1-2)
**Goal**: Replace the current Practice tab UI with carousel-based selection

### Tasks:
1. **Remove Existing Practice Tab UI** (1 hour)
   - Archive current "Start Practice" button implementation
   - Remove last practiced preview card
   - Keep quick stats display (streak, total pieces)
   - Prepare layout for carousel integration

2. **Design Carousel Container** (2 hours)
   - Create carousel area taking 60% of vertical space
   - Position below app header, above stats
   - Add visual swipe indicators (dots)
   - Implement empty state for no eligible pieces

3. **Create Suggestion Queue Service** (2 hours)
   - Extend PracticeSelectionService for queue management
   - Pre-generate 5-7 suggested pieces
   - Implement circular queue logic
   - Maintain suggestion history for session
   - Handle edge cases (0, 1, or few pieces)

4. **Update PracticeViewModel** (1 hour)
   - Remove direct practice starting logic
   - Add carousel state management
   - Track current carousel position
   - Separate browsing from practice state

### Verification:
- [ ] Carousel container displays correctly
- [ ] Stats remain visible below carousel
- [ ] Empty state shows when no pieces available
- [ ] View model properly manages carousel state

---

## Phase 2: Implement Carousel Component (Day 2-3)
**Goal**: Build the interactive carousel with smooth animations

### Tasks:
1. **Create Carousel Card View** (3 hours)
   - Design card layout (80% screen width, 3:2 ratio)
   - Display elements:
     - Piece title (large, prominent)
     - Category badge (Oli/Mele)
     - First 3-4 lines of lyrics preview
   - Add elevated shadow for depth
   - 16pt rounded corners
   - Scale animation on tap

2. **Implement Carousel Scrolling** (3 hours)
   - Use ScrollView with paging enabled
   - Implement snap-to-card behavior
   - Add smooth swipe animations
   - Configure gesture recognizers:
     - Horizontal swipe/drag for navigation
     - Tap for selection
   - Lazy loading for performance

3. **Add Visual Indicators** (1 hour)
   - Page dots below carousel
   - Highlight current position
   - Fade dots at edges for circular indication
   - Update dots on scroll

4. **Connect to Suggestion Queue** (2 hours)
   - Load initial suggestions on appear
   - Update queue on navigation
   - Preload adjacent cards
   - Handle circular navigation

### Verification:
- [ ] Smooth 60fps scrolling performance
- [ ] Cards snap correctly
- [ ] Visual indicators update properly
- [ ] Tap to select works reliably
- [ ] Works with 1, few, and many pieces

---

## Phase 3: Simplify Practice Screen (Day 3-4)
**Goal**: Remove navigation gestures and simplify the practice interface

### Tasks:
1. **Remove Navigation Gestures** (2 hours)
   - Remove left/right swipe recognizers
   - Remove piece switching logic
   - Remove session history navigation
   - Clean up gesture-related code

2. **Simplify Practice Screen UI** (2 hours)
   - Remove "Done" button
   - Keep existing elements:
     - Title and category
     - Full lyrics (scrollable)
     - Language indicator
     - Translation toggle
     - Favorite button
     - "Details" link
   - Focus on single-piece display

3. **Implement Single Exit Gesture** (2 hours)
   - Add right swipe recognizer only
   - Configure for "go back" feeling
   - Add visual hint (subtle arrow or text)
   - Fade hint after first successful swipe
   - Smooth animation on swipe

4. **Update Practice Flow** (1 hour)
   - Start session when screen appears
   - End session on swipe right
   - Handle app backgrounding
   - Return to Practice tab on exit

### Verification:
- [ ] Only right swipe works
- [ ] No piece navigation possible
- [ ] Clean, focused interface
- [ ] Smooth exit animation
- [ ] Session tracking accurate

---

## Phase 4: Update Session Tracking (Day 4-5)
**Goal**: Separate browsing metrics from practice metrics

### Tasks:
1. **Update Session Start Logic** (2 hours)
   - Session starts only on PracticeScreen appear
   - Remove session start from carousel browsing
   - Ensure accurate timestamp capture
   - Update PracticeViewModel accordingly

2. **Add Carousel Analytics** (2 hours)
   - Track carousel interactions separately:
     ```swift
     struct CarouselMetrics {
         var piecesBrowsed: Int
         var browsingDuration: TimeInterval
         var selectionIndex: Int
     }
     ```
   - Log browsing patterns
   - Store for future analysis

3. **Update Practice Metrics** (1 hour)
   - Update "lastPracticed" only on actual practice
   - Ensure session duration accuracy
   - Fix any metric calculation issues
   - Update ProfileViewModel statistics

4. **Migration Logic** (1 hour)
   - Ensure existing practice history remains valid
   - No data model changes needed
   - Test with existing user data

### Verification:
- [ ] Browsing doesn't affect practice metrics
- [ ] Session duration accurate
- [ ] Last practiced updates correctly
- [ ] Historical data preserved

---

## Phase 5: Migration and User Education (Day 5)
**Goal**: Help users adapt to the new interaction pattern

### Tasks:
1. **Create Onboarding Tooltips** (2 hours)
   - First launch tooltip: "Swipe to browse pieces"
   - Position above carousel
   - Auto-dismiss after 5 seconds or interaction
   - Store shown state in UserDefaults

2. **Add Practice Screen Hint** (1 hour)
   - Gesture hint: "Swipe right to finish"
   - Subtle animation on right edge
   - Fade after first successful swipe
   - Don't show again in session

3. **Update Help/Tutorial Content** (1 hour)
   - Update any help text
   - Create migration notes
   - Document new interaction patterns

### Verification:
- [ ] Tooltips show once only
- [ ] Hints are helpful but not intrusive
- [ ] Users understand new patterns

---

## Phase 6: Testing and Polish (Day 6-7)
**Goal**: Ensure smooth user experience and meet all requirements

### Tasks:
1. **Performance Testing** (2 hours)
   - Test with 1000+ pieces
   - Measure carousel scroll performance
   - Check memory usage
   - Optimize if needed

2. **Edge Case Testing** (2 hours)
   - No eligible pieces
   - Single piece only
   - Rapid carousel swiping
   - Interruption scenarios
   - Device rotation

3. **Accessibility** (2 hours)
   - VoiceOver navigation
   - Proper accessibility hints
   - Focus management
   - Gesture alternatives

4. **UI Polish** (3 hours)
   - Smooth animations everywhere
   - Haptic feedback on interactions
   - Loading states
   - Error handling
   - Visual consistency

5. **Integration Testing** (2 hours)
   - Full user flow testing
   - Cross-feature integration
   - Data consistency
   - Tab switching behavior

### Verification:
- [ ] All PRD requirements met
- [ ] Performance targets achieved
- [ ] Accessibility compliant
- [ ] No critical bugs
- [ ] Ready for release

---

## Daily Schedule

### Day 1 (Tuesday, June 10)
- Morning: Remove existing Practice tab UI
- Afternoon: Design carousel container
- Evening: Begin suggestion queue service

### Day 2 (Wednesday, June 11)
- Morning: Complete suggestion queue
- Afternoon: Create carousel card view
- Evening: Begin carousel scrolling

### Day 3 (Thursday, June 12)
- Morning: Complete carousel implementation
- Afternoon: Add visual indicators
- Evening: Remove practice screen gestures

### Day 4 (Friday, June 13)
- Morning: Simplify practice screen UI
- Afternoon: Implement exit gesture
- Evening: Update session tracking logic

### Day 5 (Saturday, June 14)
- Morning: Add carousel analytics
- Afternoon: Create onboarding tooltips
- Evening: Update help content

### Day 6 (Sunday, June 15)
- Morning: Performance testing
- Afternoon: Edge case testing
- Evening: Accessibility updates

### Day 7 (Monday, June 16)
- Morning: UI polish
- Afternoon: Integration testing
- Evening: Final fixes and release prep

---

## Technical Implementation Details

### Carousel Component Structure
```swift
struct PracticeCarousel: View {
    @State private var currentIndex = 0
    let suggestions: [Piece]
    let onSelect: (Piece) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                ForEach(suggestions.indices, id: \.self) { index in
                    CarouselCard(piece: suggestions[index])
                        .onTapGesture {
                            onSelect(suggestions[index])
                        }
                }
            }
            .padding(.horizontal)
        }
        .onAppear {
            // Preload adjacent cards
        }
    }
}
```

### Simplified Practice Screen
```swift
struct PracticeScreenView: View {
    let piece: Piece
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        // Single piece display
        // No navigation controls
        // Right swipe to exit only
    }
}
```

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

## Success Metrics

### Performance
- [ ] Carousel scrolls at 60fps
- [ ] Card content loads in <100ms
- [ ] No memory leaks
- [ ] App remains responsive

### User Experience
- [ ] Users browse 2-3 pieces on average
- [ ] Practice completion rate improves
- [ ] Reduced confusion about navigation
- [ ] Positive user feedback

### Code Quality
- [ ] Clean separation of concerns
- [ ] No regression from M2
- [ ] Well-documented changes
- [ ] Maintainable architecture

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
- [ ] All PRD features implemented
- [ ] Previous functionality preserved
- [ ] New UI components polished
- [ ] Gestures work as specified

### Quality Assurance
- [ ] All test cases pass
- [ ] Performance benchmarks met
- [ ] Accessibility audit complete
- [ ] No critical bugs

### Release Ready
- [ ] User onboarding in place
- [ ] Release notes prepared
- [ ] Beta feedback incorporated
- [ ] Ready for v0.3.0 tag

---

## Next Steps (Post-M3)
1. Monitor user adaptation to new flow
2. Gather feedback on carousel experience
3. Plan Milestone 4 (Google Authentication)
4. Consider carousel enhancements based on usage data