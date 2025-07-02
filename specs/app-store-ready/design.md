# Product Requirements Document - App Store Ready (Milestone 6)

### Document Information
- **Version**: 1.0
- **Date**: July 2025
- **Milestone**: 6 - App Store Ready
- **Timeline**: 1 week
- **Theme**: "Ready for App Store"

### Executive Summary
Milestone 6 prepares Haumana for public release on the Apple App Store. This milestone focuses on compliance requirements and creating all necessary assets for App Store submission. The goal is to ensure the app meets all Apple guidelines while maintaining our commitment to privacy and child safety.

### Goals & Success Metrics

#### Primary Goals
1. Implement full COPPA compliance for users under 13
2. Create privacy policy and terms of service
3. Prepare App Store listing with screenshots and descriptions
4. Add required acknowledgments and credits
5. Pass App Store review on first submission

#### Success Metrics
- Zero privacy compliance violations
- App Store approval without rejections
- All legal requirements satisfied

### Functional Requirements

#### 1. COPPA Compliance System
**Description**: Implement age verification and streamlined parental consent for users under 13

**Requirements**:
- **Age Gate**:
  - Present during onboarding after Google sign-in
  - Native iOS date picker for birthdate entry
  - Calculate age and determine if under 13
  - Store birthdate securely (Keychain encrypted)
  - Cannot be changed without support contact
  - Clear explanation of why birthdate is needed

- **Parental Consent Options** (if under 13):
  - **Apple ID Verification** (Only option for now):
    - Detect if child is part of Family Sharing
    - Use parent's Apple ID from Family Sharing
    - Send push notification to parent's device
    - Parent approves in-app with Face ID/Touch ID
    - Instant activation upon approval

- **Child Account Restrictions**:
  - Full repertoire and practice features
  - No future social features
  - Parent dashboard access via web
  - Data export available to parent
```

#### 2. Privacy Policy & Terms of Service
**Description**: Create required legal documents as simple webpages

**Requirements**:
- **Privacy Policy Page**:
  - Plain language explanation
  - Data collected and usage
  - COPPA compliance section
  - Third-party services (Google, Firebase)
  - Data retention and deletion
  - Contact information
  - Last updated date

- **Terms of Service Page**:
  - Usage terms and restrictions
  - Content ownership (user owns their oli/mele)
  - Disclaimer of warranties
  - Limitation of liability
  - Governing law (Hawaii)
  - Age requirements

- **Implementation**:
  - Static HTML pages
  - Hosted on haumana.app domain
  - Mobile-responsive design
  - Link from app settings
  - Version tracking

#### 3. Credits and Acknowledgments
**Description**: Properly credit all contributors and open source software

**Requirements**:
- **Photo Credits**:
  - Splash screen lehua photo credit
  - Photographer name and license
  - Link to original source if applicable

- **Open Source Acknowledgments**:
  - List all dependencies and licenses
  - Automated generation from Package.swift
  - Formatted acknowledgments screen
  - Accessible from Profile tab

- **Cultural Acknowledgments**:
  - Respect for Hawaiian culture
  - Educational purpose statement
  - No cultural appropriation disclaimer

#### 4. App Store Listing Assets
**Description**: Create all required assets for App Store submission

**Requirements**:
- **App Information**:
  - App name: "Haumana"
  - Subtitle: "Hawaiian Cultural Practice"
  - Primary category: Education
  - Secondary category: Music
  - Age rating: 9+

- **Description Text**:
  - Short description (up to 170 chars)
  - Full description highlighting features
  - What's New text for updates
  - Keywords for search optimization

- **Screenshots** (iPhone 6.7", 6.1", 5.5"):
  - Onboarding/welcome screen
  - Practice carousel view
  - Repertoire list with pieces
  - Practice session in progress
  - Add/edit piece form
  - Profile and settings

- **App Icon**:
  - Already implemented
  - Verify all required sizes

- **Preview Video** (optional for v1.0):
  - Skip for initial release
  - Add in future update

#### 5. Profile Screen Additions
**Description**: Add required components for compliance and user control

**New Profile Sections**:
- **Privacy**:
  - Data deletion request
  - Export my data option

- **Legal**:
  - Privacy Policy link
  - Terms of Service link
  - Licenses/Acknowledgments
  - Version and build info

- **Parent/Guardian** (if minor):
  - Parental controls info
  - Contact support link
  - Consent status

### Technical Requirements

#### Web Infrastructure
- Set up haumana.app domain
- Configure HTTPS certificate
- Deploy static site for legal pages
- Fix existing deployment script
- Set up redirect for www subdomain

#### App Store Connect Setup
- Create app record
- Configure app information
- Upload screenshots and metadata
- Set up TestFlight
- Configure phased release

### Non-Functional Requirements

#### Security
- Birthdate stored in iOS Keychain
- Parental consent codes expire after 24 hours
- Credit card info never stored
- Secure communication with Firebase

#### Accessibility
- All new screens fully accessible
- VoiceOver support for age entry
- Clear labels for all settings
- High contrast for legal text

### User Flows

#### First-Time User (Adult)
1. Download app from App Store
2. Tap "Get Started"
3. Sign in with Google
4. Enter birthdate → Verify ≥13
5. Grant permissions
6. Begin using app

#### First-Time User (Child with Family Sharing)
1. Download app from App Store
2. Tap "Get Started"
3. Sign in with Google
4. Enter birthdate → Detect <13
5. App detects Family Sharing
6. Push notification to parent
7. Parent approves with Face ID
8. Child gets full access

#### First-Time User (Child without Family Sharing)
1. Display a clear error message

#### Accessing Legal Information
1. Profile tab → Settings
2. Scroll to Legal section
3. Tap Privacy Policy or Terms
4. Opens in-app browser
5. Can share or print

### Testing Strategy

#### Compliance Testing
- [ ] Test age gate with various birthdates
- [ ] Verify Family Sharing detection
- [ ] Test push notification to parent
- [ ] Test web consent flow
- [ ] Test data export functionality

#### App Store Testing
- [ ] Screenshots on all required devices
- [ ] Description within character limits
- [ ] All links functional
- [ ] Age rating appropriate
- [ ] No placeholder content

#### Integration Testing
- [ ] Settings toggles work properly
- [ ] Web pages load correctly
- [ ] Payment processing works
- [ ] Email delivery confirmed

#### Manual Testing
- [ ] Fresh install experience
- [ ] Upgrade from existing version
- [ ] Offline functionality
- [ ] Various iOS versions (17+)
- [ ] Family Sharing scenarios
- [ ] Non-Family Sharing scenarios

### Edge Cases & Error Handling

#### Age Verification
- Invalid birthdate → Show error
- Future date → Show error  
- Exactly 13 years → Allow full access
- Change birthdate → Require support

#### Parental Consent
- Family Sharing not setup → Fall back to email
- Parent rejects consent → Show support info
- Invalid email → Validation error
- Payment fails → Retry options
- Refund fails → Manual refund + support
- Consent code expires → Generate new

#### Network Issues
- Can't reach legal pages → Cache locally

### Release Criteria
1. All compliance features implemented
2. Legal pages deployed and accessible
3. App Store assets prepared
4. TestFlight build approved
5. No critical bugs
6. Age verification tested thoroughly
7. Payment processing verified

### App Store Submission Checklist
- [ ] App Store Connect record created
- [ ] All screenshots uploaded
- [ ] Description and metadata complete
- [ ] Build uploaded and processed
- [ ] Export compliance answered
- [ ] Pricing set (free)
- [ ] Territories selected (US initially)
- [ ] COPPA compliance documented
- [ ] Submit for review

### Definition of Done
- [ ] All functional requirements implemented
- [ ] Compliance testing passed
- [ ] Legal documents published
- [ ] App Store listing complete
- [ ] TestFlight testing successful
- [ ] Privacy audit passed
- [ ] Ready for submission
- [ ] Documentation updated