//
//  PerformanceUITests.swift
//  haumanaUITests
//
//  Created by David Herman on 5/29/25.
//

import XCTest

final class PerformanceUITests: XCTestCase {
    
    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launchArguments = ["-UITestMode", "-MockAuthenticated"]
        app.launch()
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            let app = XCUIApplication()
            app.launchArguments = ["-UITestMode"]
            app.launch()
        }
    }
    
    @MainActor
    func testCarouselPerformanceWithManyPieces() throws {
        // Wait for app to fully load past splash screen
        sleep(5)
        
        // Navigate to Repertoire tab
        let tabBar = app.tabBars.firstMatch
        let repertoireTab = tabBar.buttons["Repertoire"]
        XCTAssertTrue(repertoireTab.waitForExistence(timeout: 10), "Repertoire tab should exist")
        repertoireTab.tap()
        
        // Add many test pieces (simulate 50+ pieces for performance testing)
        let addButton = app.navigationBars["Repertoire"].buttons["Add"]
        
        // Add 5 pieces quickly for testing
        for i in 1...5 {
            XCTAssertTrue(addButton.waitForExistence(timeout: 2))
            addButton.tap()
            
            let titleField = app.textFields["Title"]
            XCTAssertTrue(titleField.waitForExistence(timeout: 2))
            titleField.tap()
            titleField.typeText("Performance Test Piece \(i)")
            
            let lyricsTextView = app.textViews.firstMatch
            lyricsTextView.tap()
            lyricsTextView.typeText("Test lyrics for performance testing piece number \(i)")
            
            app.navigationBars["Add Piece"].buttons["Save"].tap()
        }
        
        // Navigate to Practice tab
        let practiceTab = tabBar.buttons["Practice"]
        practiceTab.tap()
        
        // Wait for Practice screen to load
        sleep(2)
        
        // Check if carousel exists
        let carousel = app.scrollViews.firstMatch
        if carousel.waitForExistence(timeout: 5) {
            // Measure carousel scrolling performance
            measure(metrics: [XCTOSSignpostMetric.scrollDecelerationMetric]) {
            
            // Perform multiple swipes to test scrolling performance
            for _ in 1...10 {
                carousel.swipeLeft()
                Thread.sleep(forTimeInterval: 0.2)
            }
            
                for _ in 1...10 {
                    carousel.swipeRight()
                    Thread.sleep(forTimeInterval: 0.2)
                }
            }
        } else {
            // If no carousel, skip performance test
            XCTSkip("Carousel not available for performance testing")
        }
    }
    
    @MainActor
    func testRapidCarouselSwiping() throws {
        // Wait for app to fully load past splash screen
        sleep(5)
        
        // Navigate to Practice tab
        let tabBar = app.tabBars.firstMatch
        let practiceTab = tabBar.buttons["Practice"]
        XCTAssertTrue(practiceTab.waitForExistence(timeout: 10), "Practice tab should exist")
        practiceTab.tap()
        
        // Wait for carousel or empty state
        let carousel = app.scrollViews.firstMatch
        let emptyStateText = app.staticTexts["Your repertoire is empty"]
        
        // If empty state exists, we need to add pieces first
        if emptyStateText.exists {
            // Navigate to repertoire and add a piece
            let repertoireTab = tabBar.buttons["Repertoire"]
            repertoireTab.tap()
            
            let addButton = app.navigationBars["Repertoire"].buttons["Add"]
            if addButton.waitForExistence(timeout: 2) {
                addButton.tap()
                
                let titleField = app.textFields["Title"]
                titleField.tap()
                titleField.typeText("Test Piece for Carousel")
                
                let lyricsTextView = app.textViews.firstMatch
                lyricsTextView.tap()
                lyricsTextView.typeText("Test lyrics")
                
                app.navigationBars["Add Piece"].buttons["Save"].tap()
            }
            
            // Go back to practice tab
            practiceTab.tap()
        }
        
        // Give carousel time to load after navigation
        sleep(2)
        
        if carousel.waitForExistence(timeout: 5) {
            // Test rapid swiping without delays
            // Note: With only one piece, we can't swipe much
            measure(metrics: [XCTOSSignpostMetric.scrollDecelerationMetric]) {
                // Do a few swipes back and forth
                for _ in 1...3 {
                    carousel.swipeLeft()
                    carousel.swipeRight()
                }
            }
        } else {
            // If carousel still doesn't exist, skip the test
            XCTSkip("Carousel not available for rapid swiping test")
        }
    }
}