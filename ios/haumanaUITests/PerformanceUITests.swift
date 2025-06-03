//
//  PerformanceUITests.swift
//  haumanaUITests
//
//  Created by David Herman on 5/29/25.
//

import XCTest

final class PerformanceUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}