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
        app.textFields["guessField"].tap()
        app.textFields["guessField"].typeText(word)
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
        let board = app.otherElements["wordBoard"]
        XCTAssertLessThanOrEqual(board.frame.maxY, app.textFields["guessField"].frame.minY,
                                 "The system keyboard and input must leave the full board visible")
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["submitButton"].isEnabled)
        enter("CRANE")
        XCTAssertTrue(app.buttons["submitButton"].isEnabled)
        app.buttons["submitButton"].tap()
        XCTAssertTrue(app.buttons["playAgainButton"].waitForExistence(timeout: 5), app.debugDescription)
        XCTAssertEqual(app.staticTexts["revealedAnswer"].label, "CRANE")
        capture("Encore-Win")
        app.buttons["playAgainButton"].tap()
        XCTAssertTrue(app.textFields["guessField"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["submitButton"].isEnabled)
        XCTAssertFalse(app.staticTexts["revealedAnswer"].exists)
        app.buttons["statsButton"].tap()
        XCTAssertTrue(app.staticTexts["Recent rounds"].waitForExistence(timeout: 5))
        capture("Encore-Statistics")
    }

    func testUnfinishedRoundSurvivesRelaunch() {
        enter("SLATE")
        app.buttons["submitButton"].tap()
        enter("CR")
        app.terminate()
        app.launchArguments = ["-ui-testing-resume"]
        app.launch()
        XCTAssertTrue(app.textFields["guessField"].waitForExistence(timeout: 10))
        enter("ANE")
        XCTAssertTrue(app.buttons["submitButton"].isEnabled)
        app.buttons["submitButton"].tap()
        XCTAssertTrue(app.buttons["playAgainButton"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Found in 2 guesses. There’s always another."].exists)
    }

    func testLargeTextKeepsInputAndReplayReachable() {
        app.terminate()
        app.launchArguments = ["-ui-testing", "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityM"]
        app.launch()
        XCTAssertTrue(app.textFields["guessField"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.textFields["guessField"].isHittable)
        XCTAssertLessThanOrEqual(app.otherElements["wordBoard"].frame.maxY,
                                 app.textFields["guessField"].frame.minY)
        capture("Encore-Larger-Text")
        enter("CRANE")
        app.buttons["submitButton"].tap()
        XCTAssertTrue(app.buttons["playAgainButton"].waitForExistence(timeout: 5))
        if !app.buttons["playAgainButton"].isHittable { app.scrollViews.firstMatch.swipeUp() }
        XCTAssertTrue(app.buttons["playAgainButton"].isHittable)
    }

    func testInvalidGuessAndDeletePreserveAttempts() {
        enter("ZZZZZ")
        app.buttons["submitButton"].tap()
        XCTAssertTrue(app.staticTexts["gameMessage"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["gameMessage"].label.contains("dictionary"))
        capture("Encore-Validation")
        app.keys["delete"].tap()
        XCTAssertFalse(app.buttons["submitButton"].isEnabled)
        XCTAssertFalse(app.staticTexts["gameMessage"].exists)
    }

    func testAllFourDifficultiesArePlayable() {
        for (difficulty, letters) in [("easy", "4"), ("hard", "6"), ("expert", "7"), ("medium", "5")] {
            app.buttons["difficultyMenu"].tap()
            app.buttons["difficulty_\(difficulty)"].tap()
            XCTAssertTrue(app.buttons["difficultyMenu"].label.contains("\(letters) letters"))
            XCTAssertTrue(app.textFields["guessField"].isHittable)
            XCTAssertTrue(app.buttons["submitButton"].exists)
            XCTAssertLessThanOrEqual(app.otherElements["wordBoard"].frame.maxY,
                                     app.textFields["guessField"].frame.minY)
            if difficulty == "expert" { capture("Encore-Extra-Hard") }
        }
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
        XCTAssertTrue(app.textFields["guessField"].exists)
        app.buttons["moreButton"].tap()
        app.buttons["Reveal word"].tap()
        app.buttons["Reveal word"].tap()
        XCTAssertTrue(app.buttons["playAgainButton"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["revealedAnswer"].label, "CRANE")
        capture("Encore-Reveal")
    }

    func testStartedRoundRequiresConfirmationToChangeDifficulty() {
        enter("SLATE")
        app.buttons["submitButton"].tap()
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
