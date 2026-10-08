# Encore

A native iPhone and iPad word game for the moment you want one more round.

Play whenever you like: there is no daily gate, subscription, account, or network requirement. Each difficulty draws randomly from its own answer pool without repeats until the pool is exhausted. It then starts a fresh cycle, avoiding an immediate repeat of the last answer.

| Difficulty | Letters | Guesses | Answers |
| --- | --- | --- | --- |
| Easy | 4 | 7 | 1,982 |
| Medium | 5 | 6 | 4,426 |
| Hard | 6 | 6 | 7,014 |
| Extra hard | 7 | 5 | 10,278 |

Extra hard requires correct letters to stay in place and all revealed letters to be reused, including repeated copies. There are 23,700 answers and 35,643 accepted guesses. The English library includes some plurals and inflected forms. Proper names, punctuation, abbreviations, and selected sensitive terms are excluded from answer pools.

Unfinished rounds, input, results, streaks, and word history save locally. Switching difficulty after a submitted guess or revealing an answer counts as a loss after confirmation. An untouched round can switch freely. Winning and losing both lead directly to another round. Share results through the native share sheet without including the answer.

## Design

Built with SwiftUI and the iOS 27 SDK, targeting iOS/iPadOS 27. The interface is monochrome; green and yellow are reserved for letter clues. The board uses clear, rounded content tiles and adapts its row height to the space above the system keyboard. Native navigation toolbars, glass buttons, menus, sheets, and confirmation dialogs provide the interaction layer. The editable `Wordle/EncoreIcon.icon` uses a rounded W vector with native Icon Composer glass materials and light, dark, and tinted appearances.

The design follows Apple's current [Materials guidance](https://developer.apple.com/design/human-interface-guidelines/materials), [Buttons guidance](https://developer.apple.com/design/human-interface-guidelines/buttons), [Toolbars guidance](https://developer.apple.com/design/human-interface-guidelines/toolbars), and [Liquid Glass adoption guidance](https://developer.apple.com/documentation/technologyoverviews/adopting-liquid-glass). Standard controls receive glass automatically; the content board remains readable.

Supports Dark Mode, Dynamic Type with a scrollable board, Reduce Motion, Reduce Transparency, Increase Contrast, and Differentiate Without Color. Every tile and key exposes the letter and clue to accessibility. Input uses Apple’s standard keyboard with English letter input, autocorrection disabled, and native paste, selection, and hardware-keyboard editing. The game board bounds its letter size to preserve every column; surrounding text follows the system text size. Haptics and visual clue symbols can be configured in Settings.

## Run

Open `Wordle.xcodeproj`, select the **Wordle** scheme, and run on an iOS 27 iPhone or iPad. The Home Screen name is **Encore** and the bundle identifier is `com.neelsharma.encore`. Device signing uses the project's configured development team.

The Codex **Run Encore** action calls:

```sh
./script/build_and_run.sh
```

Set `ENCORE_SIMULATOR_ID` to use a different iOS 27 simulator. The script defaults to the iPhone 18 Pro simulator.

## Verification

The core regression suite exercises the exact production game model, word-selection policy, and save store:

```sh
./script/test_core.sh
```

The Xcode scheme includes UI tests for unlimited replay, all four difficulties, invalid words and deletion, help and settings, reveal confirmation, difficulty-switch confirmation, and relaunch restoration:

```sh
xcodebuild -project Wordle.xcodeproj -scheme Wordle \
  -destination 'platform=iOS Simulator,name=iPhone 18 Pro' \
  -parallel-testing-enabled NO -collect-test-diagnostics never \
  CODE_SIGNING_ALLOWED=NO test
```

See [the verification record](docs/VERIFICATION.md) for completed checks and their limits. Simulator interaction and build evidence are separate from physical-device haptic and VoiceOver acceptance or App Store distribution.

## Word library

The bundled library derives from [SCOWL 2020.12.07](https://wordlist.aspell.net) by Kevin Atkinson and its contributors. The full redistribution notice is included in the bundle and visible in Settings → Word library credits. No word service is contacted during play.

Rebuild from the official release archive:

```sh
python3 script/build_word_library.py /path/to/scowl-2020.12.07
```

`Wordle/Resources/WordLibraryManifest.json` records the source, commonness levels, counts, and checksums. Answer pools use American and general English commonness levels 40, 50, 50, and 55; accepted guesses include levels through 70.

Encore is an independent implementation and has no association with The New York Times. No Wordle artwork, interface assets, or answer lists are used.
# Wordle-
