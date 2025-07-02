# Implementation Tasks - App Store Ready (Milestone 6)

## Overview

This implementation plan details the technical steps to prepare Haumana for App Store submission, including COPPA compliance, legal documentation, and App Store assets.

## Phase 1: COPPA Compliance Implementation (Days 1-2)

- [ ] Age Verification UI
  - [ ] Create AgeVerificationView.swift with date picker
  - [ ] Add age verification step to onboarding flow after Google sign-in
  - [ ] Calculate age and store birthdate encrypted in Keychain
  - [ ] Add clear explanation text about why birthdate is needed
  - [ ] Prevent navigation backward once age is entered
- [ ] Family Sharing Detection
  - [ ] Import FamilyControls framework
  - [ ] Create FamilyAuthorizationService.swift
  - [ ] Detect if current user is a child in Family Sharing
  - [ ] Create method to request parental authorization
  - [ ] Handle authorization success/failure callbacks
- [ ] Parental Consent Flow
  - [ ] Create ParentalConsentView.swift for children without Family Sharing
  - [ ] Display clear message that Family Sharing is required
  - [ ] Add button to open Family Sharing settings
  - [ ] Provide parent contact information for support
- [ ] Child Account Restrictions
  - [ ] Update User model to include isMinor flag
  - [ ] Ensure no analytics or tracking for minors
  - [ ] Test all features work normally for child accounts

## Phase 2: Legal Documentation (Days 3-4)

- [ ] Privacy Policy Creation
  - [ ] Write privacy policy content in markdown
  - [ ] Include COPPA compliance section
  - [ ] Document data collection practices
  - [ ] Add third-party services disclosure (Google, AWS)
  - [ ] Include data deletion and export procedures
- [ ] Terms of Service Creation
  - [ ] Write terms of service content in markdown
  - [ ] Include usage restrictions and age requirements
  - [ ] Add content ownership clarification
  - [ ] Include limitation of liability
  - [ ] Set governing law to Hawaii
- [ ] Web Infrastructure Setup
  - [ ] Register haumana.app domain
  - [ ] Set up AWS S3 bucket for static hosting
  - [ ] Configure CloudFront distribution
  - [ ] Set up SSL certificate via ACM
  - [ ] Configure www redirect to main domain
- [ ] Deploy Legal Pages
  - [ ] Convert markdown to responsive HTML
  - [ ] Create simple CSS for mobile-friendly display
  - [ ] Deploy to S3 via fixed deployment script
  - [ ] Test pages load correctly on mobile devices
  - [ ] Add version tracking to pages

## Phase 3: Credits and Acknowledgments (Day 5)

- [ ] Photo Credits Implementation
  - [ ] Add photographer credit to SplashScreenView.swift
  - [ ] Include photo license information
  - [ ] Add link to original source if available
- [ ] Open Source Acknowledgments
  - [ ] Create script to extract dependencies from Package.swift
  - [ ] Generate acknowledgments list with licenses
  - [ ] Create AcknowledgmentsView.swift
  - [ ] Add navigation from Profile tab to acknowledgments
- [ ] Cultural Acknowledgments
  - [ ] Write respectful acknowledgment of Hawaiian culture
  - [ ] Add educational purpose statement
  - [ ] Include in acknowledgments screen

## Phase 4: Profile Screen Updates (Day 6)

- [ ] Privacy Section
  - [ ] Add "Request Data Deletion" button
  - [ ] Implement data export functionality
  - [ ] Create DataExportService.swift
  - [ ] Generate JSON export of user's data
  - [ ] Share exported file via iOS share sheet
- [ ] Legal Section
  - [ ] Add Privacy Policy link opening in SafariView
  - [ ] Add Terms of Service link opening in SafariView
  - [ ] Add Acknowledgments navigation link
  - [ ] Display app version and build number
- [ ] Minor Account UI
  - [ ] Show parental consent status for minors
  - [ ] Add parent support contact link
  - [ ] Hide adult-only features

## Phase 5: App Store Assets (Day 7)

- [ ] App Store Screenshots
  - [ ] Take screenshots on iPhone 15 Pro Max (6.7")
  - [ ] Take screenshots on iPhone 15 (6.1")
  - [ ] Take screenshots on iPhone SE (5.5")
  - [ ] Capture: Welcome, Practice Carousel, Repertoire, Practice Session, Add Piece, Profile
  - [ ] Edit screenshots for consistency
  - [ ] Add device frames if desired
- [ ] App Store Metadata
  - [ ] Write short description (max 170 chars)
  - [ ] Write full description with feature highlights
  - [ ] Create keyword list for ASO
  - [ ] Write initial "What's New" text
  - [ ] Verify app name and subtitle
- [ ] App Icon Verification
  - [ ] Confirm all required icon sizes present
  - [ ] Verify icon renders well at all sizes
  - [ ] Check App Store Connect preview

## Phase 6: App Store Connect Setup (Day 8)

- [ ] Create App Record
  - [ ] Log into App Store Connect
  - [ ] Create new app with bundle ID
  - [ ] Set primary language to English
  - [ ] Configure app information
- [ ] Configure App Details
  - [ ] Set categories: Primary - Education, Secondary - Music
  - [ ] Set age rating to 9+
  - [ ] Answer content rating questions
  - [ ] Set pricing to Free
  - [ ] Select US territory initially
- [ ] Upload Assets
  - [ ] Upload all screenshots
  - [ ] Add app description and keywords
  - [ ] Verify app icon appears correctly
  - [ ] Save all changes

## Phase 7: Build and Testing (Days 9-10)

- [ ] Build Configuration
  - [ ] Increment build number
  - [ ] Set version to 1.0.0
  - [ ] Archive release build
  - [ ] Validate archive locally
- [ ] TestFlight Setup
  - [ ] Upload build to App Store Connect
  - [ ] Wait for processing to complete
  - [ ] Add internal testers
  - [ ] Submit for TestFlight review
- [ ] Compliance Testing
  - [ ] Test age verification flow
  - [ ] Test Family Sharing authorization
  - [ ] Test child account restrictions
  - [ ] Verify legal links work
  - [ ] Test data export functionality
- [ ] Final Testing
  - [ ] Fresh install testing
  - [ ] Upgrade testing from current version
  - [ ] Test on multiple iOS versions (17+)
  - [ ] Verify all screenshots match current UI

## Phase 8: Submission (Day 11)

- [ ] Final Checks
  - [ ] Verify privacy policy is live
  - [ ] Verify terms of service is live
  - [ ] Confirm all test issues resolved
  - [ ] Review App Store listing one more time
- [ ] Submit for Review
  - [ ] Add reviewer notes about COPPA compliance
  - [ ] Submit app for review
  - [ ] Monitor review status
  - [ ] Respond to any reviewer questions quickly
- [ ] Post-Submission
  - [ ] Document submission date and details
  - [ ] Prepare for potential rejection reasons
  - [ ] Plan quick fixes if needed