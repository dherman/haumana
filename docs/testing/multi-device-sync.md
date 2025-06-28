# Multi-Device Sync Testing Guide

This guide outlines the testing procedures for verifying that the Haumana cloud sync functionality works correctly across multiple devices.

## Prerequisites

1. Two iOS devices (or one device and one simulator)
2. Valid Google account for authentication
3. Internet connectivity on both devices
4. Latest build of Haumana app installed on both devices

## Test Scenarios

### 1. Basic Sync Test

**Objective**: Verify that pieces sync between devices

**Steps**:
1. On Device A:
   - Launch Haumana
   - Sign in with Google account
   - Add a new oli or mele piece
   - Note the sync status indicator shows "Synced"

2. On Device B:
   - Launch Haumana
   - Sign in with the same Google account
   - Navigate to Repertoire tab
   - Verify the piece added on Device A appears
   - Check sync status shows "Synced"

**Expected Result**: Piece appears on both devices with all details intact

### 2. Offline to Online Sync

**Objective**: Verify that changes made offline sync when connectivity is restored

**Steps**:
1. On Device A:
   - Enable Airplane Mode
   - Add 2-3 new pieces
   - Edit an existing piece
   - Note sync status shows "Offline" or "Pending changes"

2. On Device A:
   - Disable Airplane Mode
   - Wait for automatic sync or tap "Sync Now"
   - Verify sync status changes to "Syncing..." then "Synced"

3. On Device B:
   - Pull to refresh or wait for automatic sync
   - Verify all changes from Device A appear

**Expected Result**: All offline changes sync successfully

### 3. Concurrent Editing Test

**Objective**: Verify conflict resolution when same piece is edited on multiple devices

**Steps**:
1. Ensure both devices are synced and online
2. On both devices, navigate to the same piece
3. On Device A:
   - Edit the piece title
   - Wait for sync to complete

4. On Device B (before syncing):
   - Edit the same piece's lyrics
   - Allow sync to complete

5. Check both devices after sync

**Expected Result**: Last edit wins - Device B's changes should be on both devices

### 4. Practice Session Sync

**Objective**: Verify practice sessions sync across devices

**Steps**:
1. On Device A:
   - Start a practice session
   - Practice 2-3 pieces
   - End the session
   - Check Profile tab shows the session

2. On Device B:
   - Navigate to Profile tab
   - Verify the practice session from Device A appears
   - Check session details (time, pieces practiced)

**Expected Result**: Practice history is consistent across devices

### 5. Large Data Set Test

**Objective**: Verify sync performance with many pieces

**Steps**:
1. On Device A:
   - Add 50+ pieces (can use batch entry)
   - Note sync completion time

2. On Device B:
   - Sign in and wait for initial sync
   - Verify all pieces appear
   - Check performance is acceptable

**Expected Result**: All pieces sync within reasonable time (<30 seconds)

### 6. Sign Out/Sign In Test

**Objective**: Verify data isolation between accounts

**Steps**:
1. On Device A:
   - Sign out from Account 1
   - Sign in with Account 2
   - Add unique pieces to Account 2

2. On Device B:
   - Verify Account 1 data is not visible
   - Sign in with Account 2
   - Verify only Account 2 pieces appear

**Expected Result**: Complete data isolation between accounts

### 7. Sync Interruption Recovery

**Objective**: Verify sync recovers from interruptions

**Steps**:
1. On Device A:
   - Add 10+ pieces
   - Start sync
   - Force quit app during sync

2. Relaunch app:
   - Check sync status
   - Verify sync automatically resumes
   - Check all pieces eventually sync

**Expected Result**: Sync recovers and completes successfully

## Performance Benchmarks

- Initial sync of 100 pieces: < 5 seconds
- Incremental sync of 10 changes: < 2 seconds
- Sync status update frequency: Real-time
- Offline queue persistence: Survives app restart

## Troubleshooting

### Sync Not Working
1. Check internet connectivity
2. Verify signed in with correct account
3. Check Profile > Sync Status for errors
4. Try manual "Sync Now"
5. Sign out and sign back in

### Data Not Appearing
1. Pull to refresh in Repertoire
2. Check sync timestamp in Profile
3. Verify changes were saved (not in edit mode)
4. Check for sync errors

### Performance Issues
1. Check number of pieces (>1000 may be slow)
2. Verify good internet connection
3. Check available device storage
4. Try clearing local cache (Profile > Data & Storage)

## Success Criteria

- [ ] All test scenarios pass
- [ ] Sync completes within performance benchmarks
- [ ] No data loss in any scenario
- [ ] UI accurately reflects sync status
- [ ] Errors are clearly communicated to user
- [ ] Sync recovers from all failure modes