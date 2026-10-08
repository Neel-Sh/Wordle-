import XCTest

final class EncoreUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-ui-testing"]
        app.launch()
        XCTAssertTrue(app.buttons["difficultyMenu"].waitForExistence(timeout: 10))
    }

    private func enter(_ word: String) {
        for letter in word.uppercased() { app.buttons["key_\(letter)"].tap() }
    }

    private var enterKey: XCUIElement { app.buttons["keyboardEnter"] }
    private var keyboard: XCUIElement { app.otherElements["gameKeyboard"] }

    private func assertBoardAboveKeyboard() {
        XCTAssertLessThanOrEqual(app.otherElements["wordBoard"].frame.maxY, keyboard.frame.minY,
                                 "Every board row should fit above the custom keyboard")
    }

    private var cancelButton: XCUIElement {
        app.buttons["Keep playing"].exists ? app.buttons["Keep playing"] : app.buttons["Cancel"]
    }

    private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testWinThenPlayAgainWithoutDailyLimit() {
        capture("Encore-Light")
        assertBoardAboveKeyboard()
        XCTAssertFalse(app.keyboards.firstMatch.exists)
        XCTAssertFalse(app.textFields["guessField"].exists)
        XCTAssertFalse(app.buttons["submitButton"].exists)
        enter("CRANE")
        enterKey.tap()
        XCTAssertTrue(app.buttons["playAgainButton"].waitForExistence(timeout: 5), app.debugDescription)
        XCTAssertEqual(app.staticTexts["revealedAnswer"].label, "CRANE")
        capture("Encore-Win")
        app.buttons["playAgainButton"].tap()
        XCTAssertTrue(enterKey.waitForExistence(timeout: 5))
        XCTAssertEqual(app.buttons["key_C"].value as? String, "Not used")
        XCTAssertFalse(app.staticTexts["revealedAnswer"].exists)
        app.buttons["statsButton"].tap()
        XCTAssertTrue(app.staticTexts["Recent rounds"].waitForExistence(timeout: 5))
        capture("Encore-Statistics")
    }

    func testUnfinishedRoundSurvivesRelaunch() {
        enter("SLATE")
        enterKey.tap()
        enter("CR")
        app.terminate()
        app.launchArguments = ["-ui-testing-resume"]
        app.launch()
        XCTAssertTrue(enterKey.waitForExistence(timeout: 10))
        XCTAssertEqual(app.buttons["key_S"].value as? String, "Not in the word")
        enter("ANE")
        enterKey.tap()
        XCTAssertTrue(app.buttons["playAgainButton"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Found in 2 guesses. There’s always another."].exists)
    }

    func testLargeTextKeepsInputAndReplayReachable() {
        app.terminate()
        app.launchArguments = ["-ui-testing", "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityM"]
        app.launch()
        XCTAssertTrue(enterKey.waitForExistence(timeout: 10))
        XCTAssertTrue(enterKey.isHittable)
        assertBoardAboveKeyboard()
        capture("Encore-Larger-Text")
        enter("CRANE")
        enterKey.tap()
        XCTAssertTrue(app.buttons["playAgainButton"].waitForExistence(timeout: 5))
        if !app.buttons["playAgainButton"].isHittable { app.scrollViews.firstMatch.swipeUp() }
        XCTAssertTrue(app.buttons["playAgainButton"].isHittable)
    }

    func testInvalidGuessAndDeletePreserveAttempts() {
        enterKey.tap()
        XCTAssertTrue(app.staticTexts["gameMessage"].label.contains("5-letter"))
        enter("ZZZZZ")
        enter("A") // A full row ignores further letter presses.
        enterKey.tap()
        XCTAssertTrue(app.staticTexts["gameMessage"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["gameMessage"].label.contains("dictionary"))
        capture("Encore-Validation")
        app.buttons["keyboardDelete"].tap()
        XCTAssertFalse(app.staticTexts["gameMessage"].exists)
        enterKey.tap()
        XCTAssertTrue(app.staticTexts["gameMessage"].label.contains("5-letter"))
        XCTAssertTrue(app.staticTexts["6 guesses left"].exists)
        XCTAssertEqual(app.buttons["key_Z"].value as? String, "Not used")
    }

    func testKeyboardCluesAndDirectGridEntry() {
        enter("SLATE")
        XCTAssertTrue(app.descendants(matching: .any)["tile_0_0"].label.contains("S"))
        enterKey.tap()
        XCTAssertEqual(app.buttons["key_S"].value as? String, "Not in the word")
        XCTAssertEqual(app.buttons["key_L"].value as? String, "Not in the word")
        XCTAssertEqual(app.buttons["key_A"].value as? String, "Correct position")
        XCTAssertEqual(app.buttons["key_E"].value as? String, "Correct position")
        XCTAssertEqual(app.buttons["key_C"].value as? String, "Not used")
        capture("Encore-Custom-Keyboard-Clues")
        enter("REACH")
        enterKey.tap()
        XCTAssertEqual(app.buttons["key_R"].value as? String, "In the word, different position")
        XCTAssertEqual(app.buttons["key_E"].value as? String, "Correct position",
                       "A green clue must survive a later yellow clue")
        XCTAssertEqual(app.buttons["key_H"].value as? String, "Not in the word")
        enter("S") // Gray keys remain usable, as in Wordle.
        XCTAssertTrue(app.descendants(matching: .any)["tile_2_0"].label.contains("S"))
        app.buttons["keyboardDelete"].tap()
        enter("CRANE")
        enterKey.tap()
        XCTAssertTrue(app.buttons["playAgainButton"].waitForExistence(timeout: 5))
    }

    func testAllFourDifficultiesArePlayable() {
        for (difficulty, letters) in [("easy", "4"), ("hard", "6"), ("expert", "7"), ("medium", "5")] {
            app.buttons["difficultyMenu"].tap()
            app.buttons["difficulty_\(difficulty)"].tap()
            XCTAssertTrue(app.buttons["difficultyMenu"].label.contains("\(letters) letters"))
            XCTAssertTrue(enterKey.isHittable)
            assertBoardAboveKeyboard()
            enter(String(repeating: "Z", count: Int(letters)!))
            enterKey.tap()
            XCTAssertTrue(app.staticTexts["gameMessage"].label.contains("dictionary"))
            if difficulty == "expert" { capture("Encore-Extra-Hard") }
        }
    }

    func testLandscapeKeyboardKeepsGridPlayable() {
        XCUIDevice.shared.orientation = .landscapeLeft
        defer { XCUIDevice.shared.orientation = .portrait }
        let layoutSettled = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            let screen = self.app.frame
            let keys = self.keyboard.frame
            return screen.width > screen.height && keys.width > 0
                && keys.maxX <= screen.maxX && keys.maxY <= screen.maxY
                && self.app.otherElements["wordBoard"].frame.maxX <= keys.minX
        }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [layoutSettled], timeout: 10), .completed)
        XCTAssertTrue(enterKey.isHittable)
        XCTAssertLessThanOrEqual(app.otherElements["wordBoard"].frame.maxX, keyboard.frame.minX,
                                 "Landscape should place the grid beside the keyboard")
        enter("SLATE")
        enterKey.tap()
        XCTAssertEqual(app.buttons["key_S"].value as? String, "Not in the word")
        XCTAssertEqual(app.buttons["key_E"].value as? String, "Correct position")
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = "Encore-Landscape-Keyboard"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testHelpSettingsAndRevealFlow() {
        app.buttons["helpButton"].tap()
        XCTAssertTrue(app.staticTexts["Follow the letters"].waitForExistence(timeout: 5))
        capture("Encore-Help")
        app.buttons["doneButton"].tap()
        app.buttons["moreButton"].tap()
        app.buttons["Settings"].tap()
        XCTAssertTrue(app.switches["Haptic feedback"].waitForExistence(timeout: 5))
        app.switches["Show clue symbols"].tap()
        capture("Encore-Settings")
        app.buttons["doneButton"].tap()
        app.buttons["moreButton"].tap()
        app.buttons["Reveal word"].tap()
        XCTAssertTrue(cancelButton.waitForExistence(timeout: 5), app.debugDescription)
        cancelButton.tap()
        XCTAssertTrue(enterKey.exists)
        app.buttons["moreButton"].tap()
        app.buttons["Reveal word"].tap()
        app.buttons["Reveal word"].tap()
        XCTAssertTrue(app.buttons["playAgainButton"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["revealedAnswer"].label, "CRANE")
        capture("Encore-Reveal")
    }

    func testStartedRoundRequiresConfirmationToChangeDifficulty() {
        enter("SLATE")
        enterKey.tap()
        capture("Encore-Clues")
        app.buttons["difficultyMenu"].tap()
        app.buttons["difficulty_hard"].tap()
        XCTAssertTrue(cancelButton.waitForExistence(timeout: 5), app.debugDescription)
        cancelButton.tap()
        XCTAssertTrue(app.buttons["difficultyMenu"].label.contains("Medium"))
        app.buttons["difficultyMenu"].tap()
        app.buttons["difficulty_hard"].tap()
        app.buttons["Start Hard round"].tap()
        XCTAssertTrue(app.buttons["difficultyMenu"].label.contains("Hard"))
    }
}
