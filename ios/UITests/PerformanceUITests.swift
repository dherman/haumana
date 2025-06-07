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
        app.launch()
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
    
    @MainActor
    func testCarouselPerformanceWithManyPieces() throws {
        // Navigate to Repertoire tab
        let tabBar = app.tabBars["Tab Bar"]
        let repertoireTab = tabBar.buttons["Repertoire"]
        XCTAssertTrue(repertoireTab.waitForExistence(timeout: 5))
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
        
        // Measure carousel scrolling performance
        measure(metrics: [XCTOSSignpostMetric.scrollDecelerationMetric]) {
            // Wait for carousel to appear
            let carousel = app.scrollViews.firstMatch
            XCTAssertTrue(carousel.waitForExistence(timeout: 5))
            
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
    }
    
    @MainActor
    func testRapidCarouselSwiping() throws {
        // Navigate to Practice tab
        let tabBar = app.tabBars["Tab Bar"]
        let practiceTab = tabBar.buttons["Practice"]
        practiceTab.tap()
        
        // Wait for carousel
        let carousel = app.scrollViews.firstMatch
        
        if carousel.waitForExistence(timeout: 5) {
            // Test rapid swiping without delays
            measure {
                for _ in 1...20 {
                    carousel.swipeLeft()
                }
            }
        }
    }
}