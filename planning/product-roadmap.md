# Haumana Product Roadmap

## Overview
This roadmap breaks down the Haumana app development into manageable milestones, starting with local storage and gradually adding features and cloud capabilities. Each milestone delivers usable functionality for testing and feedback.

## Development Principles
- **Ship early and often** - Weekly releases for rapid feedback
- **Start simple** - Local storage first, cloud later
- **User value first** - Each milestone must provide real utility
- **Learn as we build** - Progressive complexity as skills develop

## Milestone Timeline

### Milestone 1: Basic Repertoire (Week 1)
**Target: 1 week from start**
**Theme: "Build Your Collection"**

**Features:**
- ✅ Splash screen with app branding
- Add new pieces (title, lyrics, language, category)
- View list of pieces
- View piece details
- Edit existing pieces
- Delete pieces
- Basic search by title
- Local storage only (SwiftData)

**Screens:**
- Splash screen
- Repertoire list (simple table view)
- Add/Edit piece form
- Piece detail view

**Technical:**
- SwiftUI + SwiftData
- No authentication
- No network calls
- Simple data model

**Success Metrics:**
- Can add 10+ pieces
- Beta testers can build their repertoire
- Smooth add/edit/delete flow

---

### Milestone 2: Practice Mode (Week 2)
**Target: 1 week after M1**
**Theme: "Start Practicing"**

**Features:**
- Practice tab with random selection
- Practice screen showing full lyrics
- Basic practice session (start/end)
- Filter pieces by category (oli/mele)
- Mark pieces as favorites
- English translation support

**Screens:**
- Tab bar navigation
- Practice tab (home)
- Practice session screen
- Updated repertoire with filters

**Technical:**
- Implement tab navigation
- Random selection algorithm
- Expand data model for translations

**Success Metrics:**
- Users complete 5+ practice sessions
- Random selection feels fair
- Quick access to practice

---

### Milestone 3: Practice Carousel (Week 3)
**Target: 1 week after M2**
**Theme: "Preview Before Practice"**

**Features:**
- Carousel-based piece selection on Practice tab
- Preview pieces before starting practice
- Swipe left/right to browse suggestions
- Simplified practice screen (single piece, no gestures)
- Swipe right to end practice session
- Improved practice metrics accuracy

**Screens:**
- Updated Practice tab with carousel
- Simplified Practice screen
- Remove practice summary screen

**Technical:**
- Implement carousel component
- Refactor practice flow
- Update gesture handling
- Simplify state management

**Success Metrics:**
- Users feel more in control of selection
- Practice metrics more accurate
- Cleaner separation of selection vs practice
- Intuitive gesture navigation

---

### Milestone 4: Google Authentication (Week 4)
**Target: 1 week after M3**
**Theme: "Secure Your Data"**

**Features:**
- Google Sign-in
- User profile screen
- Secure local data per user
- Sign out functionality
- Privacy/terms links

**Screens:**
- Welcome/sign-in screen
- Profile tab
- Updated navigation flow

**Technical:**
- Google Sign-In SDK integration
- Keychain storage for auth
- User-scoped data model
- Prepare for cloud sync

**Success Metrics:**
- Smooth sign-in flow
- Data properly isolated per user
- No data loss on sign-out/in

---

### Milestone 5: Cloud Sync - Part 1 (Week 5-6)
**Target: 2 weeks after M4**
**Theme: "Access Anywhere"**

**Features:**
- AWS Cognito integration
- Basic DynamoDB sync for pieces
- Session tracking in database (no UI)
- Conflict resolution (last-write-wins)
- Offline mode with sync indicator
- Pull-to-refresh

**Technical:**
- AWS SDK setup
- Cognito user pool
- DynamoDB tables (pieces and sessions)
- Simple sync logic
- Error handling
- Set up build workflow for repo (consider Bazel or CMake)

**Success Metrics:**
- Data syncs across devices
- Works offline
- No data loss
- Clear sync status
- Sessions tracked in database

---

### Milestone 6: Enhanced Content (Week 7-8)
**Target: 2 weeks after M5**
**Theme: "Rich Experience"**

**Features:**
- Thumbnail image support
- Import from photo library
- Import from URL
- Auto-generated thumbnails
- Source URL links
- Author attribution

**Technical:**
- S3 bucket setup
- Image processing
- Pre-signed URLs
- CloudFront CDN

**Success Metrics:**
- Fast image loading
- Multiple image sources work
- Improved visual appeal

---

### Milestone 7: Search & Discovery (Week 9)
**Target: 1 week after M6**
**Theme: "Find Faster"**

**Features:**
- Full-text search
- Filter by multiple criteria
- Sort options
- Recent pieces section
- Advanced practice options

**Technical:**
- DynamoDB GSIs
- Search optimization
- Query performance

**Success Metrics:**
- Sub-second search
- Relevant results
- Smooth filtering

---

### Milestone 8: Gift Ready (Week 10)
**Target: 1 week after M7**
**Theme: "Ready to Present"**

**Features:**
- Performance optimization
- Accessibility improvements
- Error handling polish
- Onboarding flow
- App Store preparation

**Technical:**
- Code optimization
- Crash reporting
- Analytics setup
- App Store submission prep

**Success Metrics:**
- No crashes
- <2s cold start
- VoiceOver compliant
- Beautiful, polished experience

---

## Future Milestones (Post-Launch)

### Phase 2: Practice Analytics
- History tab with calendar view
- Practice streak visualization
- Session statistics
- Progress insights
- Export practice data

### Phase 3: Sharing & Collaboration
- Share pieces with others
- Import shared pieces
- Teacher/student connections
- Group repertoires

### Phase 4: Advanced Practice
- Audio recordings
- Pronunciation guides
- Practice reminders
- Progress tracking

### Phase 5: Community Features
- Public piece library
- User contributions
- Ratings and reviews
- Social features

## Risk Mitigation

### Technical Risks
- **AWS complexity**: Mitigated by starting local-only
- **Sync conflicts**: Simple last-write-wins initially
- **Performance**: Address in dedicated milestone

### User Risks
- **Data loss**: Local backup before cloud migration
- **Complexity**: Progressive feature disclosure
- **Adoption**: Beta test each milestone

## Success Criteria

### Milestone 1-3 (Local)
- Personal testing complete
- 50+ pieces created
- 90% task completion rate

### Milestone 4-5 (Cloud)
- Successful multi-device sync
- <5% sync errors
- All features working smoothly

### Milestone 6-8 (Polish)
- Beautiful, polished experience
- <1% crash rate
- Ready for gift presentation

## Notes

- Each milestone includes time for testing and fixes
- Dates are targets, not commitments
- Features may shift between milestones based on feedback
- Cloud infrastructure will be built incrementally
- Focus on iOS first, iPad optimization later