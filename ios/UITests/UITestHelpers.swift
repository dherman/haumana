//
//  UITestHelpers.swift
//  haumanaUITests
//
//  Created on 6/2/2025.
//

import XCTest

// MARK: - XCUIElement Extension

extension XCUIElement {
    func clearAndTypeText(_ text: String) {
        guard let stringValue = self.value as? String else {
            XCTFail("Tried to clear and type text into a non string value")
            return
        }
        
        self.tap()
        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: stringValue.count)
        self.typeText(deleteString)
        self.typeText(text)
    }
}

// MARK: - Shared Enums

enum PieceCategory: String {
    case oli = "oli"
    case mele = "mele"
}