import Foundation

@main
struct CoreTests {
    @MainActor static func main() throws {
        var passed = 0
        func check(_ condition: @autoclosure () -> Bool, _ name: String) {
            guard condition() else { fatalError("FAILED: \(name)") }
            passed += 1
            print("PASS: \(name)")
        }

        let repeated = EvaluatedGuess.evaluate("ALLEY", answer: "APPLE")
        check(repeated.marks == [.correct, .present, .absent, .present, .absent], "Duplicate letters receive only available matches")
        check(EvaluatedGuess.evaluate("SASSY", answer: "GLASS").marks == [.present, .present, .absent, .correct, .absent], "Exact matches reserve repeated letters before misplaced matches")
        check(EvaluatedGuess.evaluate("APPLE", answer: "APPLE").marks.allSatisfy { $0 == .correct }, "Correct answer evaluates all letters")

        let dictionaries: [Difficulty: [String]] = [.easy: ["MOON", "TREE", "STAR"], .medium: ["CRANE", "SLATE", "APPLE"], .hard: ["PLANET", "STREAM", "FLOWER"], .expert: ["LETTERS", "ORANGES", "FREEDOM"]]
        let accepted = Set(dictionaries.values.flatMap { $0 }).union(["ALLEY", "SASSY", "GLASS", "TELLERS", "SETTLER"])
        let library = WordLibrary(answers: dictionaries, acceptedWords: accepted)
        for difficulty in Difficulty.allCases {
            check(dictionaries[difficulty]!.allSatisfy { $0.count == difficulty.letterCount }, "\(difficulty.title) answer lengths")
        }

        var round = GameRound(difficulty: .medium, answer: "CRANE")
        round.draft = "CR"
        check(round.submit(acceptedWords: accepted) != nil && round.guesses.isEmpty, "Short words don't use a guess")
        round.draft = "ZZZZZ"
        check(round.submit(acceptedWords: accepted) != nil && round.guesses.isEmpty, "Unknown words don't use a guess")
        round.draft = "SLATE"
        check(round.submit(acceptedWords: accepted) == nil && round.remainingGuesses == 5, "Accepted guess uses exactly one attempt")
        round.draft = "SLATE"
        check(round.submit(acceptedWords: accepted) != nil && round.remainingGuesses == 5, "Duplicate guess doesn't use another attempt")
        round.draft = "CRANE"
        check(round.submit(acceptedWords: accepted) == nil && round.outcome == .won && round.finishedAt != nil, "Correct answer finishes the round")
        check(round.shareText.contains("2/6") && !round.shareText.contains("CRANE"), "Share grid includes score without spoiling answer")
        let keyMarks = round.keyboardMarks
        check(keyMarks["A"] == .correct && keyMarks["S"] == .absent, "Keyboard retains strongest clue")
        var repeatedKeys = GameRound(difficulty: .medium, answer: "APPLE")
        repeatedKeys.guesses = [.evaluate("ALLEY", answer: "APPLE")]
        check(repeatedKeys.keyboardMarks["L"] == .present, "An absent duplicate cannot gray out a known present letter")
        repeatedKeys.guesses.append(.evaluate("SLATE", answer: "APPLE"))
        check(repeatedKeys.keyboardMarks["A"] == .correct && repeatedKeys.keyboardMarks["E"] == .correct,
              "Keyboard clues upgrade to green and never downgrade")

        var expert = GameRound(difficulty: .expert, answer: "LETTERS")
        expert.draft = "TELLERS"
        check(expert.submit(acceptedWords: accepted) == nil, "Extra hard accepts a valid first guess")
        expert.draft = "ORANGES"
        check(expert.submit(acceptedWords: accepted)?.contains("Keep") == true && expert.guesses.count == 1, "Extra hard enforces exact positions without consuming attempts")
        expert.draft = "LETTERS"
        check(expert.submit(acceptedWords: accepted) == nil && expert.outcome == .won, "Extra hard answer always remains playable")
        var duplicateExpert = GameRound(difficulty: .expert, answer: "LETTERS")
        duplicateExpert.guesses = [.evaluate("SETTLER", answer: "LETTERS")]
        check(duplicateExpert.validationError(for: "LETTERS", acceptedWords: accepted) == nil, "Extra hard correctly handles multiple revealed copies")

        var loss = GameRound(difficulty: .medium, answer: "CRANE")
        let misses = ["APPLE", "SLATE", "ALLEY", "SASSY", "GLASS", "STARE"]
        for miss in misses { loss.draft = miss; _ = loss.submit(acceptedWords: accepted.union(["STARE"])) }
        check(loss.outcome == .lost && loss.remainingGuesses == 0 && loss.finishedAt != nil, "Final wrong guess ends the round")
        let lostCount = loss.guesses.count
        loss.draft = "CRANE"
        _ = loss.submit(acceptedWords: accepted)
        check(loss.guesses.count == lostCount && loss.outcome == .lost, "Finished rounds can't be changed")

        var seen: [String] = []
        var previous: String?
        var cycle: Set<String> = []
        for _ in 0..<3 {
            let next = library.nextAnswer(for: .easy, seen: &seen, previous: previous)
            cycle.insert(next); previous = next
        }
        check(cycle.count == 3 && seen.count == 3, "No repeated answers within a pool cycle")
        let next = library.nextAnswer(for: .easy, seen: &seen, previous: previous)
        check(next != previous && seen.count == 1, "Exhausted pools keep playing without an immediate repeat")

        let suiteName = "encore.core-tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = GameStore(library: library, defaults: defaults)
        let original = store.round.answer
        store.enter("1"); store.enter("AB")
        check(store.round.draft.isEmpty, "Input ignores digits and multi-letter input")
        store.enter("C"); store.enter("R")
        store.replaceDraft("c r123aneMORE")
        check(store.round.draft == "CRANE", "System keyboard input and pasted text normalize and respect word length")
        store.replaceDraft("cr")
        let restored = GameStore(library: library, defaults: defaults)
        check(restored.round.draft == "CR" && restored.round.answer == original, "Unfinished round and typed input survive relaunch")
        restored.delete(); restored.delete()
        for letter in original { restored.enter(String(letter)) }
        restored.submit(); restored.submit()
        check(restored.records.count == 1 && restored.statistics.wins == 1, "Results are recorded exactly once")
        restored.startNewRound()
        check(restored.round.keyboardMarks.isEmpty && restored.round.draft.isEmpty, "Replay clears keyboard clues and direct board entry")
        check(restored.round.answer != original && !restored.round.isFinished && restored.records.count == 1, "Play again immediately keeps history and changes answer")
        restored.surrender(); restored.surrender()
        check(restored.records.count == 2 && restored.statistics.currentStreak == 0 && restored.statistics.bestStreak == 1, "Surrender counts once and ends the streak")
        restored.startNewRound(difficulty: .hard)
        check(restored.round.difficulty == .hard && restored.round.answer.count == 6, "Switching difficulty creates appropriate round")
        let finalRestore = GameStore(library: library, defaults: defaults)
        check(finalRestore.records.count == 2 && finalRestore.round == restored.round, "History and difficulty persist together")
        check(finalRestore.statistics.winRate == 50 && finalRestore.statistics.averageGuesses == 1, "Statistics reflect wins and losses")
        print("\(passed) core checks passed.")
    }
}
