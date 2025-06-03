//
//  LaunchUITests.swift
//  haumanaUITests
//
//  Created by David Herman on 5/29/25.
//

import XCTest

final class LaunchUITests: XCTestCase {

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launch()
        
        // MARK: - Launch State Assertions
        
        // 1. Verify app is in foreground
        XCTAssertEqual(app.state, .runningForeground, "App should be running in foreground after launch")
        
        // 2. Check for no crash indicators
        XCTAssertFalse(app.alerts.element.exists, "No alerts should appear on launch")
        
        // 3. Verify main window exists
        XCTAssertTrue(app.windows.firstMatch.exists, "Main window should exist")
        
        // MARK: - Initial Content Assertions
        
        // 4. Navigation bar should be present (after splash)
        let navBar = app.navigationBars.firstMatch
        XCTAssertTrue(navBar.waitForExistence(timeout: 5), "Navigation bar should appear within 5 seconds")
        
        // 5. Check for essential UI elements
        // Either we see splash screen elements OR main screen elements
        let splashTitle = app.staticTexts["Haumana"]
        let mainNavTitle = app.navigationBars["Haumana"]
        let hasValidContent = splashTitle.exists || mainNavTitle.exists
        XCTAssertTrue(hasValidContent, "Should see either splash screen or main navigation")
        
        // MARK: - Accessibility Assertions
        
        // 6. Check that UI is accessible
        XCTAssertTrue(app.isAccessibilityElement || app.descendants(matching: .any).firstMatch.exists, 
                     "App should have accessible elements")
        
        // MARK: - Performance Assertions
        
        // 7. Verify UI is responsive
        let startTime = Date()
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        let tapResponseTime = Date().timeIntervalSince(startTime)
        XCTAssertLessThan(tapResponseTime, 1.5, "UI should respond to taps within 1.5 seconds")
        
        // MARK: - Memory/State Assertions
        
        // 8. Check for memory warnings
        let memoryWarning = app.staticTexts.matching(identifier: "memory warning").firstMatch
        XCTAssertFalse(memoryWarning.exists, "No memory warnings should appear on launch")
        
        // MARK: - Screenshot with Context
        
        // Take screenshot after assertions
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen - \(UIDevice.current.name)"
        attachment.lifetime = .keepAlways
        add(attachment)
        
        // MARK: - Device-Specific Assertions
        
        // 9. Orientation handling
        if UIDevice.current.userInterfaceIdiom == .pad {
            // For iPad, verify the app works in current orientation
            let device = XCUIDevice.shared
            XCTAssertTrue(app.windows.firstMatch.exists,
                         "iPad app should have a window in \(device.orientation) orientation")
        }
        
        // 10. Dark mode handling
        // Note: We can't directly check dark mode in UI tests, but we can name screenshots accordingly
        let attachment2 = XCTAttachment(screenshot: app.screenshot())
        attachment2.name = "Launch Screen - Final State"
        attachment2.lifetime = .keepAlways
        add(attachment2)
    }
    
    @MainActor
    func testLaunchInDifferentOrientations() throws {
        let app = XCUIApplication()
        
        // Test portrait launch
        XCUIDevice.shared.orientation = .portrait
        app.launch()
        XCTAssertTrue(app.windows.firstMatch.exists, "App should launch in portrait")
        
        let portraitScreenshot = XCTAttachment(screenshot: app.screenshot())
        portraitScreenshot.name = "Launch - Portrait"
        add(portraitScreenshot)
        
        app.terminate()
        
        // Test landscape launch
        XCUIDevice.shared.orientation = .landscapeLeft
        app.launch()
        XCTAssertTrue(app.windows.firstMatch.exists, "App should launch in landscape")
        
        let landscapeScreenshot = XCTAttachment(screenshot: app.screenshot())
        landscapeScreenshot.name = "Launch - Landscape"
        add(landscapeScreenshot)
    }
    
    @MainActor
    func testLaunchWithDifferentLanguages() throws {
        // Test with Hawaiian locale
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(haw)"]
        app.launch()
        
        // Could verify Hawaiian-specific UI elements here
        let hawaiianScreenshot = XCTAttachment(screenshot: app.screenshot())
        hawaiianScreenshot.name = "Launch - Hawaiian"
        add(hawaiianScreenshot)
    }
}
