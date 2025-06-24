# Haumana Interaction Design

## Overview

This document defines the screen architecture and interaction patterns for Haumana, based on the data architecture and core user flows: authentication, repertoire management, and practice sessions.

## Screen Inventory

### 1. Authentication Screens

#### 1.1 Sign-In Screen
- **Purpose**: Authentication gateway (shown when signed out)
- **Elements**:
  - Full-screen red background (lehua flower color)
  - "Sign in with Google" button (centered)
  - No tab bar visible
- **Navigation**: 
  - Success with empty repertoire → Repertoire Tab
  - Success with existing repertoire → Practice Tab

### 2. Main App Screens

#### 2.1 Home Screen (Tab Bar)
- **Purpose**: Primary navigation hub (only visible when authenticated)
- **Tab Bar Items**:
  1. Practice (random selection)
  2. Repertoire (browse/manage)
  3. History (practice sessions)
  4. Profile (settings)
- **Note**: Tab bar is hidden on sign-in screen

#### 2.2 Practice Tab
- **Purpose**: Quick access to practice session with preview
- **Elements**:
  - Large prominent carousel card showing:
    - Preview of next randomly-selected piece
    - Piece title and category
    - Brief lyrics preview
    - Swipe indicators
  - Carousel navigation:
    - Swipe/drag left → Show next suggested piece
    - Swipe/drag right → Show previous suggested piece
  - Quick stats (streak, total pieces)
- **Actions**:
  - Tap piece preview → Start practice session → Practice Screen
  - Swipe carousel → Browse suggested pieces

#### 2.3 Practice Screen (Modal)
- **Purpose**: Active practice session for a single piece
- **Elements**:
  - Piece title and category badge
  - Thumbnail image (if available)
  - Lyrics display (scrollable)
  - Language indicator
  - Show/hide translation toggle
  - Favorite button (star icon)
  - "View Details" link
- **Gestures**:
  - Swipe right → End practice session (like "go back")
- **Navigation**:
  - Swipe right → Return to Practice Tab
  - View Details → Piece Detail Screen

#### 2.4 Practice Summary Screen
- **Purpose**: Session completion feedback
- **Elements**:
  - Session duration
  - Piece practiced
  - "Add to Favorites" option
  - "Practice Another" button
  - "Done" button
- **Navigation**:
  - Practice Another → Practice Screen (new piece)
  - Done → Home Screen

### 3. Repertoire Management Screens

#### 3.1 Repertoire Tab (List View)
- **Purpose**: Browse and manage all pieces
- **Elements**:
  - Search bar
  - Filter chips (All, Oli, Mele, Favorites)
  - Sort options (Recent, A-Z, Date Added)
  - Piece list items showing:
    - Thumbnail
    - Title
    - Category badge
    - Favorite star
  - Floating "Add Piece" button
- **Actions**:
  - Tap piece → Piece Detail Screen
  - Tap Add → Add/Edit Piece Screen
  - Pull to refresh
  - Swipe to delete

#### 3.2 Piece Detail Screen
- **Purpose**: View complete piece information
- **Elements**:
  - Thumbnail (full width)
  - Edit button (top right)
  - Title and category
  - Author (if available)
  - Lyrics (original language)
  - Translation section (collapsible)
  - Notes section
  - Source URL (tappable link)
  - Action buttons:
    - Practice Now
    - Toggle Favorite
    - Share (future)
  - Metadata (date added, last practiced)
- **Navigation**:
  - Edit → Add/Edit Piece Screen
  - Practice Now → Practice Screen

#### 3.3 Add/Edit Piece Screen
- **Purpose**: Create or modify piece
- **Form Fields**:
  - Title* (required)
  - Category* (segmented control: Oli/Mele)
  - Thumbnail options:
    - Take Photo
    - Choose from Library
    - Import from URL
    - Auto-generate
  - Lyrics* (multiline text)
  - Language (picker)
  - English Translation (multiline, optional)
  - Author (optional)
  - Source URL (optional)
  - Notes (multiline, optional)
- **Actions**:
  - Cancel → Discard changes confirmation
  - Save → Validate and save

### 4. History Screens

#### 4.1 History Tab
- **Purpose**: View practice history
- **Elements**:
  - Calendar view (month)
  - Practice streak indicator
  - List of sessions by date
  - Session items show:
    - Piece title
    - Time and duration
    - Thumbnail
- **Actions**:
  - Tap session → Piece Detail Screen
  - Tap calendar date → Filter to that day

### 5. Profile/Settings Screens

#### 5.1 Profile Tab
- **Purpose**: Account and app settings (authenticated users only)
- **Sections**:
  - Account info (name, email, profile photo)
  - Statistics:
    - Total pieces
    - Practice streak
    - Favorite category
  - Settings:
    - Notifications (future)
    - Theme (future)
    - Export data
  - About:
    - Version info
    - Privacy policy
    - Terms of service
  - Sign out button
- **Sign Out Action**:
  - Shows confirmation dialog
  - On confirmation → Navigate to Sign-In Screen

## Navigation Patterns

### Primary Navigation
- **Tab Bar**: Visible when authenticated, 4 tabs
- **Modal Presentations**: 
  - Sign-In Screen (full screen, no tab bar)
  - Practice Screen (full screen)
  - Add/Edit Piece (navigation stack)

### Secondary Navigation
- **Push Navigation**: Within tab stacks
- **Swipe Gestures**: 
  - Back navigation (standard iOS)
  - Delete pieces (repertoire list)

## Interaction Patterns

### 1. Authentication Flow
```
App Launch → Sign-In Screen → Google Auth → Empty repertoire? → Repertoire Tab
                                        → Has pieces? → Practice Tab
```

### 2. Quick Practice Flow
```
Practice Tab (piece already shown) → Swipe carousel (optional) → Tap piece → Practice Screen → Swipe right to end → Practice Tab
```

### 3. Add Piece Flow
```
Repertoire Tab → Tap Add Button → Fill Form → Add Thumbnail → Save → View New Piece
```

### 4. Browse and Practice Specific Piece
```
Repertoire Tab → Search/Filter → Tap Piece → View Details → Practice Now → Practice Screen
```

### 5. Review History Flow
```
History Tab → View Calendar → Tap Date → See Sessions → Tap Session → View Piece
```

### 6. Sign Out Flow
```
Profile Tab → Sign Out → Confirmation Dialog → Confirm → Sign-In Screen
```

## Design Principles

### 1. Simplicity First
- Large touch targets for practice controls
- Minimal steps to start practicing
- Clear visual hierarchy

### 2. Cultural Respect
- Proper display of Hawaiian diacriticals
- Respectful presentation of oli and mele
- Option to show/hide translations

### 3. Performance
- Fast piece loading
- Offline capability for repertoire
- Smooth transitions

### 4. Accessibility
- VoiceOver support
- Dynamic type support
- High contrast options

## Empty States

### No Pieces Yet
- Illustration of lehua flower
- "Start building your repertoire"
- "Add your first oli or mele" button
- Note: After sign-in with empty repertoire, user lands here

### No Practice History
- Encouraging message
- "Begin your practice journey"
- Direct link to practice

## Error States

### Network Error
- Clear error message
- Retry button
- Offline mode indication

### Authentication Error
- "Sign-in failed" message
- "Try again" button
- Remains on Sign-In Screen

### Sync Conflict
- Last synced timestamp
- Manual sync option
- Conflict resolution (last write wins)

## Future Considerations

### Sharing Features (Phase 2)
- Share piece button
- Shared pieces section
- Collaboration indicators

### Advanced Practice (Phase 3)
- Recording practice sessions
- Pitch/rhythm guides
- Progress tracking

### Social Features (Phase 4)
- Community repertoire
- Teacher assignments
- Group challenges