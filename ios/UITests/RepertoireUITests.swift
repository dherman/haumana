//
//  RepertoireUITests.swift
//  haumanaUITests
//
//  Created on 6/2/2025.
//

import XCTest

final class RepertoireUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    func testBasicNavigation() throws {
        // Wait for app to fully launch
        sleep(5)
        
        // The app should have some navigation structure
        let navBars = app.navigationBars
        XCTAssertTrue(navBars.count > 0, "Should have at least one navigation bar")
    }
    
    func testAddPieceFlow() throws {
        // Wait for splash
        sleep(5)
        
        // Find any add button - could be floating button or empty state button
        let addButtons = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'add' OR label CONTAINS[c] 'plus'"))
        
        if addButtons.count == 0 {
            // Try the last button (often the floating action button)
            let allButtons = app.buttons
            if allButtons.count > 0 {
                allButtons.element(boundBy: allButtons.count - 1).tap()
            }
        } else {
            addButtons.firstMatch.tap()
        }
        
        // Should now be on add screen - verify save button exists
        let saveButton = app.navigationBars.buttons["Save"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 2), "Save button should appear")
        
        // Cancel to go back
        if app.navigationBars.buttons["Cancel"].exists {
            app.navigationBars.buttons["Cancel"].tap()
            
            // Handle potential confirmation dialog
            if app.alerts.count > 0 {
                app.alerts.buttons["Discard"].tap()
            }
        }
    }
    
    func testListInteraction() throws {
        // First add a piece
        sleep(5)
        
        // Navigate to add screen
        let addButtons = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'add' OR label CONTAINS[c] 'plus'"))
        if addButtons.count > 0 {
            addButtons.firstMatch.tap()
        } else if app.buttons.count > 0 {
            app.buttons.element(boundBy: app.buttons.count - 1).tap()
        }
        
        // Fill minimum required fields
        let textFields = app.textFields
        if textFields.count > 0 {
            textFields.firstMatch.tap()
            textFields.firstMatch.typeText("Test Piece")
        }
        
        let textViews = app.textViews
        if textViews.count > 0 {
            textViews.firstMatch.tap()
            textViews.firstMatch.typeText("Test lyrics")
        }
        
        // Save if possible
        if app.navigationBars.buttons["Save"].isEnabled {
            app.navigationBars.buttons["Save"].tap()
            sleep(1)
            
            // Verify we have at least one cell
            XCTAssertTrue(app.cells.count > 0, "Should have at least one piece in the list")
        }
    }
}