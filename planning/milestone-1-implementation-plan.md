# Milestone 1 Implementation Plan
## Build Your Repertoire

### Overview
This implementation plan breaks down the Milestone 1 PRD into actionable development tasks with clear dependencies and time estimates. The goal is to deliver a working repertoire management system within one week.

### Timeline
- **Start Date**: June 1, 2025
- **Target Completion**: June 7, 2025
- **Total Duration**: 7 days

### Development Phases

## Phase 1: Project Setup & Data Model (Day 1)
**Goal**: Establish foundation with working data persistence

### Tasks:
1. **Configure Project Settings** (30 min)
   - Set minimum iOS version to 17.0
   - Enable landscape orientation
   - Configure dark mode support
   - Set up app icons and launch screen

2. **Implement SwiftData Model** (1 hour)
   ```swift
   @Model
   class Piece {
       var id: UUID
       var title: String
       var category: PieceCategory
       var lyrics: String
       var language: String // ISO 639
       var author: String?
       var sourceUrl: String?
       var notes: String?
       var createdAt: Date
       var updatedAt: Date
       var isFavorite: Bool = false
   }
   ```

3. **Create Repository Layer** (1 hour)
   - PieceRepository protocol
   - SwiftData implementation
   - CRUD operations
   - Search functionality

4. **Set Up View Models** (1 hour)
   - RepertoireListViewModel
   - PieceDetailViewModel
   - AddEditPieceViewModel

### Verification:
- [x] Can create and persist Piece objects
- [x] Data survives app restart
- [x] Basic CRUD operations work

---

## Phase 2: Splash Screen (Day 1-2)
**Goal**: Implement branded launch experience

### Tasks:
1. **Design Splash Screen View** (1 hour)
   - Import fonts from design/ folder
   - Create logo layout
   - Implement 3-second timer
   - Add transition animation

2. **Implement Navigation Flow** (30 min)
   - SplashView → RepertoireListView
   - Handle orientation changes
   - Support dark mode

### Verification:
- [x] Splash displays for exactly 3 seconds
- [x] Smooth transition to main screen
- [x] Works in both orientations
- [x] Respects dark mode

---

## Phase 3: Repertoire List Screen (Day 2-3)
**Goal**: Core list functionality with empty state

### Tasks:
1. **Create RepertoireListView** (2 hours)
   - Navigation bar with "Haumana" title
   - List with custom row design
   - Empty state with lehua illustration
   - Floating add button

2. **Implement List Row** (1 hour)
   - Title with wrapping
   - Category badge (Oli/Mele)
   - 2-3 line lyrics preview
   - Swipe to delete

3. **Add Search Functionality** (1 hour)
   - Search bar UI
   - Search button activation
   - Filter logic in view model
   - Results display

4. **Empty State Design** (1 hour)
   - Lehua flower image
   - "Start building your repertoire" text
   - "Add your first oli or mele" button

### Verification:
- [x] List displays all pieces
- [x] Search filters correctly
- [x] Swipe to delete works
- [x] Empty state shows when no pieces
- [x] Add button navigates properly

---

## Phase 4: Add/Edit Piece Screen (Day 3-4)
**Goal**: Complete form with validation

### Tasks:
1. **Create Form Layout** (2 hours)
   - Title field (required, 4096 char limit)
   - Category segmented control
   - Lyrics text editor (multiline)
   - Language picker with proper display
   - Optional fields (author, URL, notes)

2. **Implement Language Picker** (1 hour)
   - Display: "ʻŌlelo Hawaiʻi", "English"
   - Store: "haw", "eng"
   - Default to Hawaiian

3. **Add Form Validation** (1 hour)
   - Required field checking
   - URL format validation
   - Save button enable/disable
   - Inline error messages

4. **Handle Save/Cancel** (1 hour)
   - Save to repository
   - Cancel with confirmation
   - Navigation back to list

### Verification:
- [x] All fields save correctly
- [x] Validation prevents invalid saves
- [x] Hawaiian diacriticals display properly
- [x] Cancel confirmation works
- [x] Keyboard management smooth

---

## Phase 5: Piece Detail Screen (Day 4-5)
**Goal**: Read-only view with edit navigation

### Tasks:
1. **Create Detail Layout** (1.5 hours)
   - Title and category display
   - Full lyrics (scrollable)
   - Language indicator
   - Optional fields display
   - Tappable source URL

2. **Implement Navigation** (30 min)
   - Edit button in nav bar
   - Back to list navigation
   - Pass data to edit screen

3. **Handle URL Taps** (30 min)
   - Validate URL
   - Open in Safari
   - Error handling

### Verification:
- [x] All data displays correctly
- [x] Scrolling works for long lyrics
- [x] Edit navigation works
- [x] URLs open properly
- [x] Landscape layout optimal

---

## Phase 6: Polish & Edge Cases (Day 5-6)
**Goal**: Production-ready quality

### Tasks:
1. **Accessibility** (2 hours)
   - VoiceOver labels
   - Dynamic Type support
   - Minimum tap targets
   - Focus management

2. **Error Handling** (1 hour)
   - Storage failures
   - Invalid data
   - Corrupt entries
   - User-friendly messages

3. **Performance Testing** (1 hour)
   - Test with 100+ pieces
   - Memory profiling
   - Launch time optimization
   - Search performance

4. **UI Polish** (2 hours)
   - Animations and transitions
   - Loading states
   - Haptic feedback
   - Keyboard avoidance

### Verification:
- [x] VoiceOver fully functional
- [x] No memory leaks
- [x] Smooth animations
- [x] All error states handled

---

## Phase 7: Testing & Beta Prep (Day 6-7)
**Goal**: Ready for beta testing

### Tasks:
1. **Comprehensive Testing** (3 hours)
   - Test checklist from PRD
   - Edge case testing
   - Orientation changes
   - Data persistence

2. **Bug Fixes** (3 hours)
   - Fix issues found in testing
   - Polish rough edges
   - Performance improvements

3. **Beta Preparation** (1 hour)
   - Create development build for testers
   - Write release notes
   - Prepare feedback form

### Verification:
- [x] All PRD requirements met
- [x] No critical bugs
- [x] Development build ready
- [x] Ready for beta testers

---

## Daily Schedule

### Day 1 (Sunday)
- Morning: Project setup, data model
- Afternoon: Repository layer, view models
- Evening: Start splash screen

### Day 2 (Monday)
- Morning: Complete splash screen
- Afternoon: Start repertoire list
- Evening: List row implementation

### Day 3 (Tuesday)
- Morning: Search functionality
- Afternoon: Start add/edit form
- Evening: Form validation

### Day 4 (Wednesday)
- Morning: Complete add/edit form
- Afternoon: Piece detail screen
- Evening: Navigation polish

### Day 5 (Thursday)
- Morning: Accessibility
- Afternoon: Error handling
- Evening: Performance testing

### Day 6 (Friday)
- Morning: UI polish
- Afternoon: Comprehensive testing
- Evening: Bug fixes

### Day 7 (Saturday)
- Morning: Final testing
- Afternoon: Beta build preparation
- Evening: Distribution to beta testers

---

## Risk Mitigation

### Technical Risks
1. **SwiftData Issues**
   - Mitigation: Have Core Data fallback ready
   - Time buffer: 2 hours

2. **Dark Mode Complexity**
   - Mitigation: Use system colors primarily
   - Time buffer: 1 hour

3. **Landscape Layout**
   - Mitigation: Simple responsive design
   - Time buffer: 2 hours

### Schedule Risks
1. **Scope Creep**
   - Mitigation: Strict adherence to PRD
   - Defer nice-to-haves

2. **Testing Discoveries**
   - Mitigation: Test continuously
   - Reserve Day 7 for fixes

---

## Dependencies

### Design Assets Needed
- [x] App icon (all sizes)
- [x] Lehua flower illustration for empty state
- [x] Hawaiian fonts properly licensed

### External Dependencies
- None (all local for M1)

---

## Definition of Done

### Code Complete
- [x] All PRD features implemented
- [x] No compiler warnings
- [x] Code commented where needed
- [x] Git repository organized

### Quality Assurance
- [ ] All test cases pass
- [x] No critical bugs
- [x] Performance targets met
- [x] Accessibility audit complete

### Release Ready
- [x] Development build created
- [ ] Release notes written

---

## Next Steps (Post-M1)
1. Gather beta feedback
2. Plan M2 practice mode
3. Research AWS setup
4. Consider iPad optimizations