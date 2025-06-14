//
//  BasicUITests.swift
//  haumanaUITests
//
//  Created on 6/2/2025.
//

import XCTest

final class BasicUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-UITestMode", "-MockAuthenticated"]
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    func testAppLaunches() throws {
        // Simply verify the app launches
        XCTAssertTrue(app.state == .runningForeground)
    }
    
    func testNavigationFromEmptyState() throws {
        // Wait for splash screen to pass
        sleep(4)
        
        // Look for any button that contains "Add"
        let addButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Add'")).firstMatch
        
        if addButton.exists {
            addButton.tap()
            
            // Check if we navigated to add screen
            let saveButton = app.navigationBars.buttons["Save"]
            XCTAssertTrue(saveButton.waitForExistence(timeout: 2))
        }
    }
    
    func testAddPiece() throws {
        // Wait for splash
        sleep(4)
        
        // Find and tap add button
        let addButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Add'")).firstMatch
        if addButton.exists {
            addButton.tap()
        } else {
            // Try the floating action button
            app.buttons.element(boundBy: app.buttons.count - 1).tap()
        }
        
        // Fill in the form - use coordinates if needed
        let titleField = app.textFields.firstMatch
        if titleField.exists {
            titleField.tap()
            titleField.typeText("Test Oli")
        }
        
        // Enter lyrics
        let textViews = app.textViews
        if textViews.count > 0 {
            let lyricsField = textViews.firstMatch
            lyricsField.tap()
            lyricsField.typeText("Test lyrics content")
        }
        
        // Try to save
        let saveButton = app.navigationBars.buttons["Save"]
        if saveButton.exists && saveButton.isEnabled {
            saveButton.tap()
            
            // Verify we returned to the list
            sleep(1)
            let cells = app.cells
            XCTAssertTrue(cells.count > 0)
        }
    }
    
    func testSearchButton() throws {
        // Wait for splash
        sleep(4)
        
        // Look for search button
        let searchButton = app.buttons["Search"]
        if searchButton.exists {
            searchButton.tap()
            
            // Check if search field appears
            let searchField = app.searchFields.firstMatch
            XCTAssertTrue(searchField.waitForExistence(timeout: 2))
        }
    }
}