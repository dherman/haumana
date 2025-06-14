# Milestone 5: Cloud Sync and Data Backup
**Product Requirements Document**

## Overview

Milestone 5 transforms Haumana from a single-device app to a multi-device experience by implementing cloud synchronization via AWS services. This milestone ensures users can access their repertoire across devices and provides data backup for peace of mind.

### Goals
- Enable access to repertoire across multiple devices
- Provide automatic data backup to prevent loss
- Maintain offline functionality with sync indicators
- Track practice sessions in the cloud (data only, no UI)
- Establish foundation for future collaboration features

### Non-Goals
- Real-time collaborative editing
- Media file synchronization (audio/video)
- Advanced conflict resolution beyond last-write-wins
- Changes to practice session UI
- iPad-specific interface

### Success Criteria
- Users can sign in on a new device and see their repertoire
- Changes sync automatically when online
- App remains fully functional offline
- Clear indicators show sync status
- No data loss during sync operations
- Practice sessions are stored in cloud database

## User Stories

### Core User Stories

1. **Multi-Device Access**
   - As a user, I want to access my repertoire on any device where I sign in
   - As a user, I want my changes to appear on all my devices automatically
   - As a user, I want to switch devices without losing any data

2. **Offline Support**
   - As a user, I want to practice even without internet connection
   - As a user, I want to see what changes are pending sync
   - As a user, I want to manually trigger sync when needed

3. **Data Safety**
   - As a user, I want confidence that my repertoire is backed up
   - As a user, I want to recover my data if I lose my device
   - As a user, I want to know when my data was last synced

### Technical Stories

4. **Session Tracking**
   - As a developer, I want practice sessions stored in DynamoDB
   - As a developer, I want sessions associated with user and piece IDs
   - As a developer, I want to query sessions for future analytics

## Technical Architecture

### AWS Services Integration

```
┌─────────────────┐         ┌──────────────┐
│                 │         │              │
│   Google        │────────▶│  AWS Cognito │
│   Sign-In       │         │  (Federated) │
│                 │         │              │
└─────────────────┘         └──────┬───────┘
                                   │
                                   ▼
┌─────────────────┐         ┌──────────────┐         ┌──────────────┐
│                 │         │              │         │              │
│   SwiftData     │◀───────▶│  Sync Layer  │────────▶│  DynamoDB    │
│   (Local)       │         │              │         │              │
│                 │         │              │         │              │
└─────────────────┘         └──────────────┘         └──────────────┘
```

### Authentication Migration
- Migrate from Google Sign-In SDK to AWS Cognito
- Use Google as federated identity provider
- Maintain same user IDs for data consistency
- Handle token refresh automatically

### Data Sync Architecture

```swift
// Sync Status
enum SyncStatus {
    case synced
    case syncing
    case pendingChanges
    case offline
    case error(String)
}

// Piece Model Updates
extension Piece {
    var syncStatus: SyncStatus
    var lastSyncedAt: Date?
    var locallyModified: Bool
}
```

### DynamoDB Schema

**Pieces Table**
```
PK: USER#{userId}
SK: PIECE#{pieceId}
Attributes:
  - title, category, lyrics, language
  - author, sourceUrl, notes
  - includeInPractice, isFavorite
  - createdAt, modifiedAt, lastSyncedAt
  - version (for optimistic locking)
```

**Sessions Table**
```
PK: USER#{userId}
SK: SESSION#{timestamp}#{sessionId}
Attributes:
  - pieceId, startTime, endTime
  - createdAt
GSI1: PIECE#{pieceId} -> sessions for analytics
```

### Sync Strategy

1. **Initial Sync**
   - On first sign-in, upload all local pieces
   - Mark all pieces as synced
   - Download any existing cloud pieces

2. **Incremental Sync**
   - Track local modifications
   - Sync on app foreground
   - Sync on pull-to-refresh
   - Sync before app background

3. **Conflict Resolution**
   - Last-write-wins based on modifiedAt
   - Version field prevents race conditions
   - Future: three-way merge for lyrics

## User Interface Updates

### Sync Indicators

1. **Navigation Bar**
   ```
   ┌─────────────────────────────┐
   │ Repertoire    [↻] ✓ Synced  │
   └─────────────────────────────┘
   
   States:
   - ✓ Synced (green)
   - ↻ Syncing (animated)
   - ⚠ Pending (yellow)
   - ✗ Error (red)
   - ⊝ Offline (gray)
   ```

2. **Pull to Refresh**
   - Standard iOS pull gesture
   - Shows sync progress
   - Updates last synced time

3. **Piece Status**
   - Small indicator on pieces with pending changes
   - Swipe action to force sync individual piece

### Settings Updates

Add to Profile tab:
- Sync Status section
  - Last synced time
  - Number of pending changes
  - Manual sync button
- Data & Storage
  - Clear local cache
  - Sync frequency (future)

## Implementation Plan

### Phase 1: AWS Setup (Days 1-2)
- [ ] Configure AWS Cognito with Google federation
- [ ] Set up DynamoDB tables and indexes
- [ ] Create IAM roles and policies
- [ ] Set up API Gateway + Lambda OR AppSync

### Phase 2: Authentication Migration (Days 3-4)
- [ ] Integrate AWS Amplify SDK
- [ ] Migrate from Google Sign-In to Cognito
- [ ] Update AuthenticationService
- [ ] Test token refresh and session management

### Phase 3: Sync Infrastructure (Days 5-7)
- [ ] Create SyncService with queue management
- [ ] Implement piece sync (upload/download)
- [ ] Add conflict resolution logic
- [ ] Handle offline queue and retry

### Phase 4: UI Integration (Days 8-9)
- [ ] Add sync status indicators
- [ ] Implement pull-to-refresh
- [ ] Update Profile tab with sync info
- [ ] Add loading states during sync

### Phase 5: Session Tracking (Day 10)
- [ ] Modify PracticeSessionRepository to save to DynamoDB
- [ ] Implement background upload queue
- [ ] Ensure offline sessions sync when online

### Phase 6: Testing & Polish (Days 11-14)
- [ ] Test multi-device scenarios
- [ ] Test offline/online transitions
- [ ] Test conflict resolution
- [ ] Performance optimization
- [ ] Error handling and recovery

## Testing Strategy

### Unit Tests
- [ ] SyncService queue management
- [ ] Conflict resolution logic
- [ ] Offline detection and recovery
- [ ] Data transformation (SwiftData ↔ DynamoDB)

### Integration Tests
- [ ] AWS Cognito authentication flow
- [ ] DynamoDB CRUD operations
- [ ] Full sync cycle (upload/download)
- [ ] Token refresh handling

### UI Tests
- [ ] Sync indicator states
- [ ] Pull-to-refresh gesture
- [ ] Error state handling
- [ ] Offline mode functionality

### Manual Testing Scenarios
- [ ] Sign in on second device
- [ ] Make changes on both devices
- [ ] Test airplane mode
- [ ] Test poor connectivity
- [ ] Test app kill during sync
- [ ] Test token expiration

## Performance Considerations

### Sync Optimization
- Batch operations (25 items per DynamoDB request)
- Compress lyrics for large pieces
- Sync only changed fields
- Progressive sync for large repertoires

### Battery & Data Usage
- Sync on WiFi preferred
- Respect low power mode
- Configurable sync frequency (future)
- Show data usage in settings (future)

## Security & Privacy

### Data Security
- All data encrypted in transit (HTTPS)
- DynamoDB encryption at rest
- Cognito handles token security
- No sensitive data in logs

### Privacy Considerations
- User data isolated by userId
- No cross-user data access
- Clear data deletion policy
- GDPR compliance ready

## Future Enhancements (Not in M5)

### Version 0.6.0 and Beyond
- Real-time sync with AppSync subscriptions
- Three-way merge for lyrics conflicts
- Sync history and revision recovery
- Shared repertoires
- Media file sync (S3)
- Advanced search (OpenSearch)

## Success Metrics

### Technical Metrics
- Sync success rate > 99%
- Average sync time < 3 seconds
- Offline queue reliability 100%
- Zero data loss incidents

### User Metrics
- Multi-device usage rate
- Sync-related support requests < 1%
- User satisfaction with sync
- Offline usage patterns

## Rollout Plan

### Beta Testing
1. Internal testing with multiple devices
2. Beta group with 5-10 users
3. Monitor sync performance and errors
4. Iterate based on feedback

### Production Release
1. Feature flag for gradual rollout
2. Monitor AWS costs and usage
3. Scale DynamoDB as needed
4. Prepare support documentation

## Risks & Mitigations

### Technical Risks
- **AWS Cost Overruns**: Monitor usage, set billing alerts
- **Sync Conflicts**: Start with simple last-write-wins
- **Performance Issues**: Implement progressive sync
- **Authentication Migration**: Careful testing, fallback plan

### User Experience Risks
- **Confusion about sync status**: Clear UI indicators
- **Data loss perception**: Show sync confirmations
- **Battery drain**: Optimize sync frequency
- **Slow sync**: Progress indicators, background sync

## Open Questions

1. Should we use API Gateway + Lambda or AppSync?
2. How often should automatic sync occur?
3. Should we show sync history to users?
4. How to handle very large repertoires (1000+ pieces)?
5. Should we implement sync-only WiFi option in M5?

## Definition of Done

- [ ] All unit tests passing
- [ ] All integration tests passing
- [ ] Multi-device sync verified
- [ ] Offline mode verified
- [ ] Performance benchmarks met
- [ ] Security review completed
- [ ] Beta feedback incorporated
- [ ] Documentation updated
- [ ] Release notes prepared