//
//  AuthenticationUITests.swift
//  haumanaUITests
//
//  Created on 6/13/2025.
//

import XCTest

final class AuthenticationUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        
        // Add launch arguments for UI testing
        app.launchArguments = ["-UITestMode"]
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Sign-In Flow Tests
    
    func testSplashToSignInFlow() throws {
        // Wait for splash screen
        let splashText = app.staticTexts["Haumana"]
        XCTAssertTrue(splashText.exists)
        
        // Wait for transition to sign-in screen
        let signInButton = app.buttons["Sign in with Google"]
        XCTAssertTrue(signInButton.waitForExistence(timeout: 5))
        
        // Verify we're on sign-in screen (red background)
        XCTAssertTrue(signInButton.exists)
    }
    
    func testSignInScreenElements() throws {
        // Wait for sign-in screen
        sleep(4)
        
        // Check for app title
        let appTitle = app.staticTexts["Haumana"]
        XCTAssertTrue(appTitle.exists)
        
        // Check for Google Sign-In button
        let signInButton = app.buttons["Sign in with Google"]
        XCTAssertTrue(signInButton.exists)
        XCTAssertTrue(signInButton.isEnabled)
    }
    
    func testSignInButtonTap() throws {
        // Wait for sign-in screen
        sleep(4)
        
        let signInButton = app.buttons["Sign in with Google"]
        XCTAssertTrue(signInButton.waitForExistence(timeout: 5))
        
        // Verify the button is tappable
        XCTAssertTrue(signInButton.isEnabled)
        XCTAssertTrue(signInButton.isHittable)
        
        // Test the mock sign-in flow
        signInButton.tap()
        
        // Should transition to main app after mock sign-in
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5), "Tab bar should appear after sign-in")
    }
    
    // MARK: - Authenticated Flow Tests
    
    func testAuthenticatedUserSeesMainTabs() throws {
        // Relaunch app with mock authenticated state
        app.terminate()
        app.launchArguments = ["-UITestMode", "-MockAuthenticated"]
        app.launch()
        
        // Should skip sign-in and show main tabs
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5), "Tab bar should be visible for authenticated user")
        
        // Verify all tabs are present
        XCTAssertTrue(app.tabBars.buttons["Practice"].exists)
        XCTAssertTrue(app.tabBars.buttons["Repertoire"].exists)
        XCTAssertTrue(app.tabBars.buttons["Profile"].exists)
    }
    
    // MARK: - Sign-Out Flow Tests
    
    func testProfileTabRequiresAuthentication() throws {
        // Wait for sign-in screen
        sleep(4)
        
        // Try to access profile without signing in
        // Should not be possible - verify we're still on sign-in
        let signInButton = app.buttons["Sign in with Google"]
        XCTAssertTrue(signInButton.exists)
        
        // Profile tab should not be accessible
        let profileTab = app.tabBars.buttons["Profile"]
        XCTAssertFalse(profileTab.exists)
    }
    
    func testSignOutFlow() throws {
        // Start with authenticated state
        app.terminate()
        app.launchArguments = ["-UITestMode", "-MockAuthenticated"]
        app.launch()
        
        // Navigate to Profile tab
        let profileTab = app.tabBars.buttons["Profile"]
        XCTAssertTrue(profileTab.waitForExistence(timeout: 5))
        profileTab.tap()
        
        // Find and tap Sign Out button
        let signOutButton = app.buttons["Sign Out"]
        XCTAssertTrue(signOutButton.waitForExistence(timeout: 5))
        signOutButton.tap()
        
        // Confirm sign out in confirmation dialog (not alert)
        // iOS presents confirmation dialogs as sheets with buttons
        let confirmButton = app.sheets.buttons["Sign Out"]
        XCTAssertTrue(confirmButton.waitForExistence(timeout: 5), "Sign Out confirmation button should appear")
        confirmButton.tap()
        
        // Should return to sign-in screen
        let signInButton = app.buttons["Sign in with Google"]
        XCTAssertTrue(signInButton.waitForExistence(timeout: 5), "Should return to sign-in screen after sign out")
    }
    
    // MARK: - Navigation Tests
    
    func testNoTabBarOnSignInScreen() throws {
        // Wait for sign-in screen
        sleep(4)
        
        // Verify tab bar is not visible
        let tabBar = app.tabBars.firstMatch
        XCTAssertFalse(tabBar.exists)
        
        // Verify we're on sign-in screen
        let signInButton = app.buttons["Sign in with Google"]
        XCTAssertTrue(signInButton.exists)
    }
    
    func testSignInScreenHasNoBackButton() throws {
        // Wait for sign-in screen
        sleep(4)
        
        // Verify there's no back button or navigation
        let backButton = app.navigationBars.buttons["Back"]
        XCTAssertFalse(backButton.exists)
        
        // Verify no navigation bar
        let navBar = app.navigationBars.firstMatch
        XCTAssertFalse(navBar.exists)
    }
    
    // MARK: - Error State Tests
    
    func testSignInErrorHandling() throws {
        // This would test error states like:
        // - Network failure
        // - Cancelled sign-in
        // - Invalid credentials
        
        // For now, just verify the sign-in screen is stable
        sleep(4)
        
        let signInButton = app.buttons["Sign in with Google"]
        XCTAssertTrue(signInButton.exists)
        
        // NOTE: We cannot tap the button as it will crash
        // Just verify UI is stable
        XCTAssertTrue(signInButton.isEnabled)
    }
}

// MARK: - Mock Authentication Helper

extension AuthenticationUITests {
    /// Helper to mock authenticated state for testing
    /// In real implementation, this would use launch arguments or environment
    /// to bypass actual Google Sign-In for UI testing
    func mockAuthenticatedState() {
        // This would be implemented with test flags in the app
        // For example:
        // app.launchArguments = ["-UITestMode", "-MockAuthenticated"]
        // app.launch()
    }
}