# Verification

Date: October 7, 2026 (America/Los_Angeles).

## Passed

- Xcode 27 Debug simulator build and Release build for a generic iOS device. The Release build was unsigned; this verifies compilation and packaging, not distribution signing.
- Signed Release build, code-signature validation, installation, and foreground launch on Neel's physical iPhone 18 Pro Max running iOS 27.2. The running app process was confirmed with `devicectl`; the game board, input, and native keyboard were observed on-device.
- The updated monochrome W icon was inspected in Icon Composer's iOS 27 light and dark previews. The signed Release asset catalog contains the W vector, native glass group, and light/dark/tinted stacks. The updated app was installed and launched on the phone; `devicectl` returned its actual, non-placeholder icon for visual verification (`docs/screenshots/Encore-W-Icon.png`).
- 31 production-model checks: repeated-letter scoring, answer and guess lengths, invalid and repeated guesses, Extra hard clue constraints, win/loss boundaries, score sharing without answers, word-pool cycling, native keyboard/paste normalization, relaunch persistence, history, streaks, win rate, and immediate replay.
- Library integrity: all 23,700 answers have the expected length, are unique within their difficulty, and are included among the 35,643 accepted guesses. The bundled data matches the recorded checksums.
- Six interaction tests on the iOS 27 iPhone 18 Pro simulator: all difficulty options, word validation/deletion using Apple's keyboard, help/settings/reveal confirmation, difficulty-switch confirmation, restoring an unfinished round after relaunch, and winning then playing again immediately.
- Final targeted regression runs passed for all four difficulties, native confirmation/replay, and larger text. The seventh UI flow verifies that large-text input and replay stay reachable, and that the full board stays above the input accessory.
- The board bounds are checked against the input accessory for every difficulty. Native keyboard visibility and the primary input/action are exercised through UI automation.

## Visual evidence

Screenshots in `docs/screenshots/` show the game, letter clues, result, difficulty, settings, help, statistics, and accessibility text size. Dark Mode with Increase Contrast was also visually inspected. The current interface is monochrome, with green and yellow reserved for word clues. Native Apple buttons, menus, navigation toolbars, keyboard, and sheets supply system interaction behavior.

## Acceptance boundaries

Physical-device haptic feel, spoken VoiceOver navigation, and App Store distribution have not been verified. There is no backend or live word service to validate; the complete game and library operate locally. Dictionary commonness levels and a sensitive-term exclusion list are documented, but the answer pools have not each received a manual editorial review.
