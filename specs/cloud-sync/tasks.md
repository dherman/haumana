# Implementation Tasks - Cloud Sync and Data Backup (Milestone 5)

## Overview

This implementation plan details the technical steps to add cloud synchronization via AWS services to Haumana, enabling multi-device access and automatic data backup.

## Phase 1: AWS Infrastructure Setup (Days 1-2)

- [x] Cognito and DynamoDB Setup
  - [x] Configure AWS Cognito
  - [x] Create Cognito User Pool:
```bash
aws cognito-idp create-user-pool \
  --pool-name haumana-users \
  --schema Name=email,AttributeDataType=String,Required=true,Mutable=false
```
  - [x] Create Cognito Identity Pool:
```bash
aws cognito-identity create-identity-pool \
  --identity-pool-name haumana-identity \
  --allow-unauthenticated-identities false \
  --supported-login-providers accounts.google.com=YOUR_GOOGLE_CLIENT_ID
```
  - [x] Create DynamoDB Tables using AWS CDK
- [x] Lambda Functions Setup
  - [x] Create TypeScript project in aws/lambdas
  - [x] auth-sync-lambda.ts to validate Google tokens and return Cognito user info
  - [x] sync-pieces-lambda.ts to sync pieces table
  - [x] sync-sessions-lambda.ts to sync sessions table
- [x] API Gateway Configuration (infrastructure/api-gateway.ts)

## Phase 2: Authentication Migration (Days 3-4)

- [x] Integrate AWS Amplify
  - [x] Add Amplify SDK with Xcode Package Manager
  - [x] Configure Amplify (Config/amplifyconfiguration.json)
- [x] Update Authentication Service (Services/AuthenticationService.swift) to use Amplify
- [x] Update Sign-In View (Views/SignInView.swift)

## Phase 3: Sync Service Implementation (Days 5-7)

- [x] Create Sync Service (Services/SyncService.swift)
  - [x] `func syncNow() async`
  - [x] `func syncSessions() async`
  - [x] `func syncPieces() async`
- [x] Offline Queue (Services/OfflineQueue.swift)
  - [x] `class SyncQueueItem`
  - [x] `class OfflineQueueManager`
    - [x] `func enqueue(entityType: String, entityId: String, operation: String)`
    - [x] `func processQueue() async`
    - [x] `private func processItem(_ item: SyncQueueItem) async`

## Phase 4: UI Integration (Days 8-9)

- [x] Sync Status View (Views/SyncStatusView.swift) to show sync status
- [x] Add sync status to top of Repertoire tab
- [x] Add sync status to Profile tab

## Phase 5: Practice Session Sync (Day 10)

- [x] Update Practice Session Repository (Repositories/PracticeSessionRepository.swift)
  - [x] `func fetchUnsyncedSessions() throws -> [PracticeSession]`
  - [x] `func save(_ session: PracticeSession) throws` (already posts sync notification)

## Phase 6: Testing and Polish (Days 11-14)

- [x] Unit Tests (DataTests/SyncServiceTests.swift - already exists)
  - [x] Initial sync status
  - [x] Marking pending changes  
  - [x] Authentication requirements
  - [x] Error handling
  - [x] Concurrent sync prevention
- [x] Integration Tests (DataTests/SyncIntegrationTests.swift - already exists)
  - [x] Piece local modification tracking
  - [x] Piece sync data format
  - [x] Session sync tracking
  - [x] Multiple session sync
  - [x] Last-write-wins conflict resolution
  - [x] Large dataset performance test
- [x] Missing Tests to Implement
  - [x] Add to SyncServiceTests:
    - [x] `func testOfflineQueue() async throws` - test offline queue functionality
    - [x] `func testRetryLogic() async throws` - test retry with exponential backoff
  - [x] Add to SyncIntegrationTests:
    - [x] `func testOfflineToOnlineTransition() async throws` - test network state changes

## Phase 7: Fix Authentication and Configuration (Days 15-16)

- [x] Fix API Gateway Authorization
  - [x] Implement Custom Authorizer (Option 1 from sync-authentication-todo.md)
    - [x] Create Lambda authorizer function to validate Google ID tokens
    - [x] Update API Gateway to use custom authorizer instead of Cognito User Pools
    - [x] Extract user ID from Google token and pass to backend Lambda functions
    - [x] Remove dependency on Cognito JWT tokens for API calls
  - [x] Update iOS SyncService
    - [x] Modify SyncService to include Google ID token in Authorization header
    - [x] Update makeAuthenticatedRequest method to use Google tokens
    - [x] Test API calls with new authorization mechanism
    - [x] Ensure proper error handling for auth failures
  - [x] Create Amplify Configuration
    - [x] Create amplifyconfiguration.json
    - [x] Generate proper configuration file from template
    - [x] Include correct Cognito pool IDs and API endpoint
    - [x] Configure auth and API plugins properly
    - [x] Ensure configuration matches AWS resources
  - [x] Remove Amplify
    - [x] Realize Amplify is no longer providing any value
    - [x] Clean up legacy CDK configuration
    - [x] Remove legacy Amplify usages from code
- [x] Manual End-to-End Testing (requires real devices/API)
  - [x] Verify authentication flow works
  - [x] Test piece sync (upload and download)
  - [x] Test practice session sync
  - [x] Ensure sync status updates correctly in UI

## Phase 8: Fix Sync Issues (Days 17-18)

- [x] Fix LocallyModified Filter Issue
  - [x] Remove `.filter { $0.locallyModified }` from line 189 in SyncService.swift
  - [x] Keep locallyModified property for server-side filtering in Lambda
  - [x] Ensure PieceRepository continues to set locallyModified = true on changes
  - [x] Verify all pieces are included in sync request payload
- [x] Implement Pull Sync
  - [x] Process serverPieces array from sync response in SyncService.syncPieces()
  - [x] Check if server piece exists locally by matching pieceId
  - [x] Compare modifiedAt timestamps for existing pieces
  - [x] Create new local pieces for server pieces not found locally
  - [x] Update existing local pieces when server version is newer
  - [x] Set lastSyncedAt on all processed pieces
- [x] Fix Initial Sync for New Devices
  - [x] On first sync, send empty lastSyncedAt to get all server pieces
  - [x] Process all returned server pieces to populate local database
  - [x] Mark all received pieces with lastSyncedAt timestamp
  - [x] Test sign-in on fresh device pulls all existing pieces
- [x] Update Sync State Management
  - [x] Only mark pieces as locallyModified = false after successful upload
  - [x] Track sync conflicts in a separate property if needed
  - [x] Ensure version numbers increment correctly
  - [x] Handle sync errors without losing local changes
- [x] Fix Missing Repository Methods
  - [x] Implement PracticeSessionRepository.fetchUnsyncedSessions()
  - [x] Add query to fetch sessions where syncedAt is nil
  - [x] Return array of unsynced PracticeSession objects
- [x] Test Bidirectional Sync
  - [x] Create test with two devices signed into same account
  - [x] Add piece on device A, verify it appears on device B
  - [x] Edit piece on device B, verify changes appear on device A
  - [x] Test concurrent edits on both devices
  - [x] Verify no data loss in any scenario
- [x] Additional Fixes Implemented
  - [x] Fixed AddEditPieceView not setting locallyModified flag
  - [x] Fixed date parsing for ISO8601 dates with/without fractional seconds
  - [x] Fixed version number synchronization after upload
  - [x] Fixed pull-to-refresh spinner getting stuck
  - [x] Added proper error handling and logging throughout sync process

## Phase 9: Set up an AWS budget

- [x] Update CDK stack to tag all resources with:
   - [x] `Project: Haumana`
   - [x] `Environment: Production`
   - [x] `CostCenter: Haumana`
- [x] Redeploy CDK stack
- [x] Wait 24h
- [x] Activate cost allocation tags in AWS Console
- [x] Wait 24h
- [x] Go to [AWS Billing Console](https://console.aws.amazon.com/billing/)
- [x] Click **"Cost allocation tags"** in the left menu
- [x] Verify these tags appear in the **"Active"** section:
   - [x] `Project`
   - [x] `Environment`
   - [x] `CostCenter`
- [x] Create budget
  - [x] Go to [AWS Billing Console](https://console.aws.amazon.com/billing/)
  - [x] Click **"Budgets"** in the left menu
  - [x] Click **"Create budget"**
  - [x] Choose **"Customize (advanced)"**
  - [x] Select **"Cost budget"** and click **Next**
- [x] Configure Budget Details
  - [x] **Budget name**: `Haumana-Monthly-Budget`
  - [x] **Period**: Monthly
  - [x] **Budget renewal type**: Recurring budget
  - [x] **Start month**: Current month
  - [x] **Budgeted amount**: $10.00
- [x] Add Tag Filter (Critical Step)
  - [x] Under **"Filters"**, click **"Add filter"**
  - [x] **Filter type**: Select "Tag"
  - [x] **Tag key**: Select `Project` from dropdown
  - [x] **Tag value**: Select `Haumana` from dropdown
  - [x] The budget scope should now show "Filtered costs"
- [x] Add three alerts:
  - [x] **Alert 1 - 80% Warning**
    - [x] **Threshold**: 80% of budgeted amount
    - [x] **Threshold type**: Percentage
    - [x] **Notification type**: Actual
    - [x] **Email recipients**: david.herman@gmail.com
  - [x] **Alert 2 - 100% Exceeded**
    - [x] **Threshold**: 100% of budgeted amount
    - [x] **Threshold type**: Percentage
    - [x] **Notification type**: Actual
    - [x] **Email recipients**: david.herman@gmail.com
  - [x] **Alert 3 - Forecast Warning**
    - [x] **Threshold**: 100% of budgeted amount
    - [x] **Threshold type**: Percentage
    - [x] **Notification type**: Forecasted
    - [x] **Email recipients**: david.herman@gmail.com
- [x] Review and Create
  - [x] Review all settings
  - [x] Verify the filter shows `Tag: Project = Haumana`
  - [x] Click **"Create budget"**
- [x] Verify the Budget
  - [x] Go to AWS Cost Explorer
  - [x] Filter by `Tag: Project = Haumana`
  - [x] Verify only Haumana resources appear in the cost breakdown

