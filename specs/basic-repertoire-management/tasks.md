# Implementation Tasks - Basic Repertoire Management

### Overview
This implementation plan breaks down the Basic Repertoire Management PRD into actionable development tasks with clear dependencies and time estimates. The goal is to deliver a working repertoire management system within one week.

### Timeline
- **Start Date**: June 1, 2025
- **Target Completion**: June 7, 2025
- **Total Duration**: 7 days

### Development Phases

## Phase 1: Project Setup & Data Model (Day 1)
**Goal**: Establish foundation with working data persistence

### Tasks:
- [x] **Configure Project Settings** (30 min)
   - [x] Set minimum iOS version to 17.0
   - [x] Enable landscape orientation
   - [x] Configure dark mode support
   - [x] Set up app icons and launch screen
- [x] **Implement SwiftData Model** (1 hour)
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
- [x] **Create Repository Layer** (1 hour)
   - [x] PieceRepository protocol
   - [x] SwiftData implementation
   - [x] CRUD operations
   - [x] Search functionality
- [x] **Set Up View Models** (1 hour)
   - [x] RepertoireListViewModel
   - [x] PieceDetailViewModel
   - [x] AddEditPieceViewModel

### Verification:
- [x] Can create and persist Piece objects
- [x] Data survives app restart
- [x] Basic CRUD operations work

---

## Phase 2: Splash Screen (Day 1-2)
**Goal**: Implement branded launch experience

### Tasks:
- [x] **Design Splash Screen View** (1 hour)
   - [x] Import fonts from design/ folder
   - [x] Create logo layout
   - [x] Implement 3-second timer
   - [x] Add transition animation
- [x] **Implement Navigation Flow** (30 min)
   - [x] SplashView → RepertoireListView
   - [x] Handle orientation changes
   - [x] Support dark mode

### Verification:
- [x] Splash displays for exactly 3 seconds
- [x] Smooth transition to main screen
- [x] Works in both orientations
- [x] Respects dark mode

---

## Phase 3: Repertoire List Screen (Day 2-3)
**Goal**: Core list functionality with empty state

### Tasks:
- [x] **Create RepertoireListView** (2 hours)
   - [x] Navigation bar with "Haumana" title
   - [x] List with custom row design
   - [x] Empty state with lehua illustration
   - [x] Floating add button
- [x] **Implement List Row** (1 hour)
   - [x] Title with wrapping
   - [x] Category badge (Oli/Mele)
   - [x] 2-3 line lyrics preview
   - [x] Swipe to delete
- [x] **Add Search Functionality** (1 hour)
   - [x] Search bar UI
   - [x] Search button activation
   - [x] Filter logic in view model
   - [x] Results display
- [x] **Empty State Design** (1 hour)
   - [x] Lehua flower image
   - [x] "Start building your repertoire" text
   - [x] "Add your first oli or mele" button

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
- [x] **Create Form Layout** (2 hours)
   - [x] Title field (required, 4096 char limit)
   - [x] Category segmented control
   - [x] Lyrics text editor (multiline)
   - [x] Language picker with proper display
   - [x] Optional fields (author, URL, notes)
- [x] **Implement Language Picker** (1 hour)
   - [x] Display: "ʻŌlelo Hawaiʻi", "English"
   - [x] Store: "haw", "eng"
   - [x] Default to Hawaiian
- [x] **Add Form Validation** (1 hour)
   - [x] Required field checking
   - [x] URL format validation
   - [x] Save button enable/disable
   - [x] Inline error messages
- [x] **Handle Save/Cancel** (1 hour)
   - [x] Save to repository
   - [x] Cancel with confirmation
   - [x] Navigation back to list

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
- [x] **Create Detail Layout** (1.5 hours)
   - [x] Title and category display
   - [x] Full lyrics (scrollable)
   - [x] Language indicator
   - [x] Optional fields display
   - [x] Tappable source URL
- [x] **Implement Navigation** (30 min)
   - [x] Edit button in nav bar
   - [x] Back to list navigation
   - [x] Pass data to edit screen
- [x] **Handle URL Taps** (30 min)
   - [x] Validate URL
   - [x] Open in Safari
   - [x] Error handling

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
- [x] **Accessibility** (2 hours)
   - [x] VoiceOver labels
   - [x] Dynamic Type support
   - [x] Minimum tap targets
   - [x] Focus management
- [x] **Error Handling** (1 hour)
   - [x] Storage failures
   - [x] Invalid data
   - [x] Corrupt entries
   - [x] User-friendly messages
- [x] **Performance Testing** (1 hour)
   - [x] Test with 100+ pieces
   - [x] Memory profiling
   - [x] Launch time optimization
   - [x] Search performance
- [x] **UI Polish** (2 hours)
   - [x] Animations and transitions
   - [x] Loading states
   - [x] Haptic feedback
   - [x] Keyboard avoidance

### Verification:
- [x] VoiceOver fully functional
- [x] No memory leaks
- [x] Smooth animations
- [x] All error states handled

---

## Phase 7: Testing & Beta Prep (Day 6-7)
**Goal**: Ready for beta testing

### Tasks:
- [x] **Comprehensive Testing** (3 hours)
   - [x] Test checklist from PRD
   - [x] Edge case testing
   - [x] Orientation changes
   - [x] Data persistence
- [x] **Bug Fixes** (3 hours)
   - [x] Fix issues found in testing
   - [x] Polish rough edges
   - [x] Performance improvements
- [x] **Beta Preparation** (1 hour)
   - [x] Create development build for testers
   - [x] Write release notes
   - [x] Prepare feedback form

### Verification:
- [x] All PRD requirements met
- [x] No critical bugs
- [x] Development build ready
- [x] Ready for beta testers

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
- [x] All test cases pass
- [x] No critical bugs
- [x] Performance targets met
- [x] Accessibility audit complete

### Release Ready
- [x] Development build created
- [x] Release notes written
