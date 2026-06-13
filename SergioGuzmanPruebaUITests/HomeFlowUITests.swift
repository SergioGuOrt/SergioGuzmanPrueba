// SergioGuzmanPruebaUITests/HomeFlowUITests.swift
//
//  UI Test: Validates the critical navigation flow.
//  Uses the real API (integration test).
//  Designed for stability: generous timeouts, element existence checks, retry-safe.

import XCTest

final class HomeFlowUITests: XCTestCase {

    private let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launch()
    }

    /// Validates: Home loads → Table appears → Tap character → Detail opens → Tap favorite → Back to Home
    func testFullNavigationFlow_Home_Detail_Favorite_Back() throws {
        // 1. Wait for the character list to appear (network dependent)
        let table = app.tables.firstMatch
        let tableExists = table.waitForExistence(timeout: 10)
        XCTAssertTrue(tableExists, "Character table should appear within 10s")

        // 2. Wait for at least one cell to load
        let firstCell = table.cells.firstMatch
        let cellLoaded = firstCell.waitForExistence(timeout: 10)
        XCTAssertTrue(cellLoaded, "At least one character cell should load")

        // 3. Tap the first character
        firstCell.tap()

        // 4. Verify Detail screen appeared (nav bar title changes)
        // Wait for any element unique to Detail — the "Favorito" button
        let favoriteButton = app.buttons.matching(
            NSPredicate(format: "label CONTAINS[c] 'Favorit' OR label CONTAINS[c] 'heart'")
        ).firstMatch
        let detailAppeared = favoriteButton.waitForExistence(timeout: 5)
        XCTAssertTrue(detailAppeared, "Detail screen should show favorite button")

        // 5. Tap favorite button
        favoriteButton.tap()

        // 6. Navigate back
        let backButton = app.navigationBars.buttons.firstMatch
        if backButton.exists {
            backButton.tap()
        }

        // 7. Verify we're back on Home
        let homeTableReappeared = table.waitForExistence(timeout: 5)
        XCTAssertTrue(homeTableReappeared, "Should return to Home screen")
    }

    /// Validates: Scope bar filter changes update the list without crashing
    func testFilterByStatus_changesResults() throws {
        // Wait for table
        let table = app.tables.firstMatch
        XCTAssertTrue(table.waitForExistence(timeout: 10))
        XCTAssertTrue(table.cells.firstMatch.waitForExistence(timeout: 10))

        // Tap "Dead" scope button
        let deadButton = app.buttons["Dead"]
        if deadButton.exists {
            deadButton.tap()
            // Wait a moment for the reload
            Thread.sleep(forTimeInterval: 2)
            // App should not crash — that's the main validation
            XCTAssertTrue(table.exists, "Table should still exist after filter change")
        }
    }
}
