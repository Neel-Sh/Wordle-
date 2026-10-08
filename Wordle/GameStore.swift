import Foundation
import Observation

struct SavedGame: Codable {
    var round: GameRound
    var records: [RoundRecord] = []
    var seen: [Difficulty: [String]] = [:]
}

@Observable @MainActor
final class GameStore {
    private(set) var round: GameRound
    private(set) var records: [RoundRecord]
    var message: String?
    private(set) var errorPulse = 0
    private(set) var feedbackPulse = 0
    private(set) var saveError: String?

    let library: WordLibrary
    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private var seen: [Difficulty: [String]]
    @ObservationIgnored private let saveKey = "encore.savedGame.v1"

    var statistics: GameStatistics { GameStatistics(records: records) }

    init(library: WordLibrary? = nil, defaults: UserDefaults = .standard) {
        let library = library ?? WordLibrary()
        self.library = library
        self.defaults = defaults
        if let data = defaults.data(forKey: saveKey),
           let saved = try? JSONDecoder().decode(SavedGame.self, from: data),
           Self.isValid(saved.round, library: library) {
            round = saved.round
            records = saved.records
            seen = saved.seen
        } else {
            var used: [String] = []
            let answer = library.nextAnswer(for: .medium, seen: &used, previous: nil)
            round = GameRound(difficulty: .medium, answer: answer)
            records = []
            seen = [.medium: used]
        }
        persist()
    }

    private static func isValid(_ round: GameRound, library: WordLibrary) -> Bool {
        let count = round.difficulty.letterCount
        return library.acceptedWords.contains(round.answer)
            && round.answer.count == count
            && round.draft.count <= count
            && round.guesses.count <= round.difficulty.guessLimit
            && round.guesses.allSatisfy { $0.word.count == count && $0.marks.count == count }
    }

    func enter(_ letter: String) {
        guard !round.isFinished, round.draft.count < round.difficulty.letterCount,
              letter.count == 1, let scalar = letter.uppercased().unicodeScalars.first,
              (65...90).contains(scalar.value) else { return }
        round.draft.append(letter.uppercased())
        message = nil
        persist()
    }

    func delete() {
        guard !round.isFinished, !round.draft.isEmpty else { return }
        round.draft.removeLast()
        message = nil
        persist()
    }

    func replaceDraft(_ input: String) {
        guard !round.isFinished else { return }
        let letters = input.uppercased().unicodeScalars.filter { (65...90).contains($0.value) }
        round.draft = String(String.UnicodeScalarView(letters.prefix(round.difficulty.letterCount)))
        message = nil
        persist()
    }

    func submit() {
        guard !round.isFinished else { return }
        if let error = round.submit(acceptedWords: library.acceptedWords) {
            message = error
            errorPulse += 1
        } else {
            message = nil
            feedbackPulse += 1
            if round.isFinished { recordResult() }
            persist()
        }
    }

    func startNewRound(difficulty: Difficulty? = nil) {
        // Switching a started round counts as a loss; untouched rounds are free to switch.
        if !round.isFinished && !round.guesses.isEmpty { surrender() }
        let difficulty = difficulty ?? round.difficulty
        var used = seen[difficulty] ?? []
        let answer = library.nextAnswer(for: difficulty, seen: &used, previous: round.answer)
        seen[difficulty] = used
        round = GameRound(difficulty: difficulty, answer: answer)
        message = nil
        persist()
    }

    func surrender() {
        guard !round.isFinished else { return }
        round.outcome = .surrendered
        round.finishedAt = Date()
        round.draft = ""
        message = nil
        recordResult()
        persist()
    }

    private func recordResult() {
        guard !records.contains(where: { $0.id == round.id }) else { return }
        records.append(RoundRecord(id: round.id, difficulty: round.difficulty, answer: round.answer,
                                   outcome: round.outcome, guessCount: round.guesses.count,
                                   finishedAt: round.finishedAt ?? Date()))
    }

    func persist() {
        do {
            let data = try JSONEncoder().encode(SavedGame(round: round, records: records, seen: seen))
            defaults.set(data, forKey: saveKey)
            saveError = nil
        } catch {
            saveError = "Your progress couldn’t be saved."
        }
    }

    #if DEBUG
    func prepareUITest(answer: String, difficulty: Difficulty = .medium) {
        round = GameRound(difficulty: difficulty, answer: answer)
        records = []
        seen = [difficulty: [answer]]
        persist()
    }
    #endif
}
