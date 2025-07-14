# Implementation Tasks - App Store Ready (Milestone 6)

## Overview

This implementation plan details the technical steps to prepare Haumana for App Store submission, including COPPA compliance, legal documentation, and App Store assets.

## Phase 1: COPPA Compliance Implementation (Days 1-3)

- [x] Age Verification UI
  - [x] Create AgeVerificationView.swift with date picker
  - [x] Add age verification step to onboarding flow after Google sign-in
  - [x] Calculate age and store birthdate encrypted in Keychain
  - [x] Add clear explanation text about why birthdate is needed
  - [x] Prevent navigation backward once age is entered
- [x] User Model Updates
  - [x] Update User model to include isMinor flag
  - [x] Add birthdate field with automatic minor calculation
  - [x] Implement secure Keychain storage for birthdate
- [x] KWS Integration Setup
  - [x] Create Epic Games developer account
  - [x] Register for KWS access at developer portal
  - [x] Create Haumana organization in KWS dashboard
  - [x] Obtain API credentials and store securely
  - [x] Create Lambda function for KWS webhook receiver
  - [x] Deploy webhook endpoint via API Gateway
  - [x] Configure KWS webhook URL in dashboard
  - [x] Submit KWS configuration for review
  - [x] Receive and store webhook secret after approval
- [x] AWS Webhook Infrastructure
  - [x] Create kws-webhook-lambda in aws/lambdas directory
  - [x] Implement webhook signature validation
  - [x] Parse KWS verification events
  - [x] Update DynamoDB with parent consent status
  - [x] Add CloudWatch logging for webhook events
  - [x] Create API Gateway POST endpoint /webhooks/kws
  - [x] Deploy and test webhook endpoint
  - [x] Add webhook URL to KWS dashboard
- [x] KWS API Client Implementation
  - [x] Create KWSAPIClient.swift with base URL and authentication
  - [x] Implement createUser method for KWS user registration
  - [x] Implement requestParentConsent method with parent email parameter
  - [x] Add KWS user ID field to User model
  - [x] Create ParentConsentStatus enum (pending, approved, denied)
  - [x] Implement proper error handling for all API calls
  - [x] Add method to check consent status from DynamoDB
- [x] Parent Consent UI Updates
  - [x] Replace ParentalConsentView with KWSParentConsentView
  - [x] Create parent email collection form with validation
  - [x] Add loading state while sending consent request
  - [x] Create WaitingForParentView showing consent pending status
  - [x] Check consent status from DynamoDB on app launch
  - [x] Create success view for when consent is approved
  - [x] Add error states for denied consent or API failures
- [x] Onboarding Flow Integration
  - [x] Update OnboardingCoordinator to use KWS
  - [x] Remove FamilyAuthorizationService entirely
  - [x] Add KWS user creation after age verification
  - [x] Integrate parent email collection for minors
  - [x] Check DynamoDB for existing consent status
  - [x] Store parent consent status in User model
  - [x] Prevent data collection until consent is approved
- [x] Child Account Restrictions
  - [x] Add consent checks before any AWS sync operations (N/A - blocked at onboarding)
  - [x] Disable practice session uploads for unapproved minors (N/A - blocked at onboarding)
  - [x] Show limited UI for children awaiting consent
  - [x] Add consent status indicator in profile view (N/A - minors can't access app until approved)
  - [x] Test all features work normally after consent approval

## Phase 2: Legal Documentation (Days 3-4)

- [x] Privacy Policy Updates
  - [x] Update existing privacy policy with COPPA compliance details
  - [x] Add KWS (Kids Web Services) integration explanation
  - [x] Document parental consent process for users under 13
  - [x] Update third-party services disclosure (Google, AWS, Epic Games KWS)
  - [x] Add birthdate collection and storage explanation
  - [x] Include parental rights section for minors' data
- [x] Terms of Service Updates
  - [x] Update age requirements section for COPPA compliance
  - [x] Add section about parental consent for minors
  - [x] Update account creation requirements for users under 13
  - [x] Verify governing law is set to California (already done)
  - [x] Add Epic Games KWS terms acknowledgment
- [x] Fix deploy-web.sh Script
  - [x] Update script to work within a temporary directory
  - [x] Avoid using git rm -rf . which clears the working directory
  - [x] Use git worktree or temporary clone approach instead
  - [x] Test script doesn't affect main working directory
  - [x] Replace deploy-web.sh with deploy-web-safe.sh once tested
- [x] GitHub Pages Infrastructure Setup
  - [x] Verify haumana.app domain configuration (CNAME already exists)
  - [x] Check DNS settings point to GitHub Pages
  - [x] Enable HTTPS in GitHub repository settings
  - [x] Configure www subdomain redirect
  - [x] Test GitHub Pages is accessible
- [x] Deploy Legal Pages
  - [x] Convert markdown to responsive HTML
  - [x] Create simple CSS for mobile-friendly display
  - [x] Deploy using fixed deploy-web.sh script
  - [x] Test pages load correctly on mobile devices
  - [x] Add version tracking to pages

## Phase 3: Credits and Acknowledgments (Day 5)

- [x] Photo Credits Implementation
  - [x] Add photographer credit to SplashScreenView.swift
  - [x] Include photo license information
  - [x] Add link to original source if available
- [x] Open Source Acknowledgments
  - [x] Create script to extract dependencies from Package.swift
  - [x] Generate acknowledgments list with licenses
  - [x] Create AcknowledgmentsView.swift
  - [x] Add navigation from Profile tab to acknowledgments
- [x] Cultural Acknowledgments
  - [x] Write respectful acknowledgment of Hawaiian culture
  - [x] Add educational purpose statement
  - [x] Include in acknowledgments screen

## Phase 4: Profile Screen Updates (Day 6)

- [ ] Privacy Section
  - [ ] Add "Request Data Deletion" button
  - [x] Create export-user-data Lambda function
  - [x] Implement DynamoDB queries for all user data in Lambda
  - [x] Format user data as JSON in Lambda response
  - [x] Add /users/{userId}/export API endpoint
  - [x] Create exportUserData method in APIClient.swift
  - [x] Add "Export My Data" button to Profile view
  - [x] Call export API and present share sheet with response
  - [x] Handle loading state during export request
  - [x] Show error alert if export fails
  - [x] Implement data export restrictions for minors
  - [ ] Create delete-user-data Lambda function
  - [ ] Implement data deletion across all DynamoDB tables
  - [ ] Add /users/{userId} DELETE endpoint
  - [ ] Create deleteUserData method in APIClient.swift
  - [ ] Show confirmation dialog before deletion
  - [ ] Sign out user after successful deletion
- [x] Legal Section
  - [x] Add Privacy Policy link opening in SafariView
  - [x] Add Terms of Service link opening in SafariView
  - [x] Add Acknowledgments navigation link
  - [x] Display app version and build number
- [ ] Minor Account UI
  - [ ] Add parent support contact link
  - [ ] Hide adult-only features
  - [ ] Implement parental consent revocation handling
    - [ ] Check consent status on app launch
    - [ ] Handle KWS webhook for consent revocation
    - [ ] Sign out user if consent is revoked
    - [ ] Show appropriate message to child user
    - [ ] Update privacy policy with KWS parent portal link

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