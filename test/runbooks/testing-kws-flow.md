# Testing KWS Parental Consent Flow

## Overview

Since the KWS API requires approval from Epic Games, we've implemented a test mode to simulate the full parental consent flow locally.

## How to Test

### 1. Enable Test Mode

Run the app with the `-testKWS` launch argument in Xcode:

1. Select the app target in Xcode
2. Edit Scheme → Run → Arguments
3. Add `-testKWS` to "Arguments Passed On Launch"

Or set it programmatically:
```swift
UserDefaults.standard.set(true, forKey: "testKWSMode")
```

### 2. Test the Flow

1. **Sign in** with a Google account
2. **Enter a birthdate** that makes you under 13 (e.g., a date from 2015)
3. **Enter parent email** when prompted
4. You'll see the **"Waiting for Parent Approval"** screen

### 3. Simulate Parent Actions

While on the waiting screen:

1. Navigate to the **Profile tab**
2. If in test mode and signed in as a minor, you'll see a **"🧪 Test Mode - Parental Consent"** section
3. Use the buttons to:
   - **"Simulate Parent Approval"** - Approves consent and allows access
   - **"Simulate Parent Denial"** - Denies consent and blocks access

### 4. What Happens

- **Approval**: The waiting screen shows success and continues to the main app
- **Denial**: The waiting screen shows the denial message and requires sign out

### 5. Reset Testing

To test again with a different scenario:

1. Sign out from the app
2. Clear app data if needed (Delete app from simulator)
3. Start over with a new test

## What Works in Test Mode

✅ Age verification flow  
✅ Parent email collection  
✅ Waiting for parent screen  
✅ Simulated approval/denial  
✅ Success/denial screens  
✅ Consent status persistence  

## What Requires Epic Approval

❌ Real KWS API calls  
❌ Actual parent emails being sent  
❌ Real webhook notifications  
❌ Production consent flow  

## Notes

- Test mode is only available in DEBUG builds
- The test mode indicator appears in the Profile tab
- All test data is stored locally in UserDefaults
- The consent status is saved to the local database just like production