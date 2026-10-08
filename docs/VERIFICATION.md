# Verification

Updated: October 8, 2026 (America/Los_Angeles).

## October 8: Custom keyboard and grid polish

- Debug simulator compilation passed for the custom keyboard, direct grid entry, square tiles, and physical-keyboard command responder.
- 34 production-model checks passed, including absent duplicate letters retaining a known yellow clue, green clues never being downgraded, and replay clearing the draft and keyboard clues.
- All nine interaction flows passed on the dedicated Encore Keyboard QA iOS 27 simulator: direct entry and clue updates, all difficulties, short/invalid guesses and deletion, help/settings/reveal, difficulty confirmation, larger text, saved-round restoration, unlimited replay, and landscape. They verify that the input field, separate Check button, and system keyboard are absent. Portrait board bounds fit above the keyboard; landscape bounds keep the entire keyboard on screen beside the grid.
- The final build and nine-test run produced no Swift warnings or invalid-frame layout warnings. The only build warning is the existing App Intents metadata skip because the app does not link AppIntents.
- Light and Dark Mode screenshots were inspected. The keyboard uses gray for absent letters and retains yellow/green clues across guesses. Gray keys remain usable. Current keyboard evidence is saved as `Encore-Keyboard-Light.png`, `Encore-Keyboard-Dark.png`, `Encore-Keyboard-Landscape.png`, and `Encore-Keyboard-Larger-Text.png` in `docs/screenshots/`.

Physical-device installation and haptic/VoiceOver acceptance have not been repeated for this revision. Physical-keyboard commands compile but have not received hands-on verification.

## October 7: Previous revision

- Xcode 27 Debug simulator build and Release build for a generic iOS device. The Release build was unsigned; this verifies compilation and packaging, not distribution signing.
- Signed Release build, code-signature validation, installation, and foreground launch on Neel's physical iPhone 18 Pro Max running iOS 27.2. The running app process was confirmed with `devicectl`; the game board, input, and native keyboard were observed on-device.
- The updated monochrome W icon was inspected in Icon Composer's iOS 27 light and dark previews. The signed Release asset catalog contains the W vector, native glass group, and light/dark/tinted stacks. The updated app was installed and launched on the phone; `devicectl` returned its actual, non-placeholder icon for visual verification (`docs/screenshots/Encore-W-Icon.png`).
- 31 production-model checks: repeated-letter scoring, answer and guess lengths, invalid and repeated guesses, Extra hard clue constraints, win/loss boundaries, score sharing without answers, word-pool cycling, native keyboard/paste normalization, relaunch persistence, history, streaks, win rate, and immediate replay.
- Library integrity: all 23,700 answers have the expected length, are unique within their difficulty, and are included among the 35,643 accepted guesses. The bundled data matches the recorded checksums.
- Six interaction tests on the iOS 27 iPhone 18 Pro simulator: all difficulty options, word validation/deletion using Apple's keyboard, help/settings/reveal confirmation, difficulty-switch confirmation, restoring an unfinished round after relaunch, and winning then playing again immediately.
- Final targeted regression runs passed for all four difficulties, native confirmation/replay, and larger text. The seventh UI flow verifies that large-text input and replay stay reachable, and that the full board stays above the input accessory.
- The board bounds are checked against the input accessory for every difficulty. Native keyboard visibility and the primary input/action are exercised through UI automation.

## Visual evidence

Screenshots in `docs/screenshots/` show the game, letter clues, result, difficulty, settings, help, statistics, and accessibility text size. Earlier screenshots document the previous system-keyboard revision. The current interface uses a custom QWERTY keyboard with direct grid entry; native Apple menus, navigation toolbars, and sheets remain. Green and yellow are reserved for letter clues.

## Acceptance boundaries

Physical-device haptic feel, spoken VoiceOver navigation, and App Store distribution have not been verified. There is no backend or live word service to validate; the complete game and library operate locally. Dictionary commonness levels and a sensitive-term exclusion list are documented, but the answer pools have not each received a manual editorial review.
