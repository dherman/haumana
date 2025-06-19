# Adding AWS Amplify SDK to Haumana iOS Project

Follow these steps to add the AWS Amplify SDK dependencies to the Xcode project:

## Steps to Add AWS Amplify SDK

1. **Open the Project in Xcode**
   ```bash
   open ios/Haumana.xcodeproj
   ```

2. **Add Swift Package Dependencies**
   - In Xcode, select the project file (Haumana) in the navigator
   - Select the "Haumana" project (not the target) in the editor
   - Click on the "Package Dependencies" tab
   - Click the "+" button to add a package

3. **Add AWS Amplify Package**
   - In the search field, enter: `https://github.com/aws-amplify/amplify-swift`
   - Click "Add Package"
   - Wait for Xcode to resolve the package
   - For "Dependency Rule", select "Up to Next Major Version" with version `2.40.0`
   - Click "Add Package"

4. **Select Required Products**
   When prompted to choose products, select:
   - ✅ Amplify
   - ✅ AWSCognitoAuthPlugin
   - ✅ AWSAPIPlugin
   
   Make sure these are added to the "haumana" target.
   
   Click "Add Package" to finish.

5. **Verify Installation**
   - In the project navigator, you should see "Package Dependencies" with amplify-swift listed
   - The Google Sign-In SDK should remain as well

## Alternative: Command Line Installation

If you prefer to add packages via command line, you can edit the project.pbxproj file directly, but this is not recommended as it's error-prone.

## Next Steps

After adding the SDK:
1. Build the project to ensure dependencies are resolved: `Cmd+B`
2. If there are any errors, try cleaning the build folder: `Cmd+Shift+K`
3. The AmplifyAuthenticationService should now compile successfully

## Switching Between Auth Providers

The app is configured to switch between Google Sign-In and AWS Amplify authentication using the `AppConfiguration.swift` file:

```swift
// To use AWS Amplify (current setting for Phase 2):
static let authProvider: AuthProvider = .awsAmplify

// To switch back to Google Sign-In:
static let authProvider: AuthProvider = .googleSignIn
```

This allows testing the new authentication flow while keeping the old one available.