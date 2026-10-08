import Foundation

enum Difficulty: String, CaseIterable, Codable, Identifiable {
    case easy, medium, hard, expert

    var id: String { rawValue }
    var title: String {
        switch self {
        case .easy: "Easy"
        case .medium: "Medium"
        case .hard: "Hard"
        case .expert: "Extra hard"
        }
    }
    var letterCount: Int {
        switch self {
        case .easy: 4
        case .medium: 5
        case .hard: 6
        case .expert: 7
        }
    }
    var guessLimit: Int {
        switch self {
        case .easy: 7
        case .medium, .hard: 6
        case .expert: 5
        }
    }
    var detail: String { "\(letterCount) letters · \(guessLimit) guesses" }
    var description: String {
        switch self {
        case .easy: "Short words. A little breathing room."
        case .medium: "Five letters. The familiar challenge."
        case .hard: "Longer words. More to untangle."
        case .expert: "Seven letters. Reuse every revealed letter."
        }
    }
    var symbol: String {
        switch self {
        case .easy: "leaf"
        case .medium: "circle.lefthalf.filled"
        case .hard: "flame"
        case .expert: "bolt"
        }
    }
}

enum LetterMark: Int, Codable, Comparable {
    case absent, present, correct

    static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }
    var description: String {
        switch self {
        case .absent: "Not in the word"
        case .present: "In the word, different position"
        case .correct: "Correct position"
        }
    }
    var shareSymbol: String {
        switch self {
        case .absent: "⬜"
        case .present: "🟨"
        case .correct: "🟩"
        }
    }
}

struct EvaluatedGuess: Codable, Equatable {
    let word: String
    let marks: [LetterMark]

    static func evaluate(_ word: String, answer: String) -> Self {
        let letters = Array(word)
        let target = Array(answer)
        precondition(letters.count == target.count)
        var marks = Array(repeating: LetterMark.absent, count: target.count)
        var remaining: [Character: Int] = [:]
        // Reserve exact matches first so repeated letters never get extra credit.
        for index in target.indices {
            if letters[index] == target[index] {
                marks[index] = .correct
            } else {
                remaining[target[index], default: 0] += 1
            }
        }
        for index in letters.indices where marks[index] != .correct {
            if remaining[letters[index], default: 0] > 0 {
                marks[index] = .present
                remaining[letters[index], default: 0] -= 1
            }
        }
        return Self(word: word, marks: marks)
    }
}

enum RoundOutcome: String, Codable { case playing, won, lost, surrendered }

struct GameRound: Codable, Equatable {
    var id = UUID()
    let difficulty: Difficulty
    let answer: String
    var draft = ""
    var guesses: [EvaluatedGuess] = []
    var outcome: RoundOutcome = .playing
    var startedAt = Date()
    var finishedAt: Date?

    var isFinished: Bool { outcome != .playing }
    var remainingGuesses: Int { difficulty.guessLimit - guesses.count }
    var keyboardMarks: [Character: LetterMark] {
        var result: [Character: LetterMark] = [:]
        for guess in guesses {
            for (letter, mark) in zip(guess.word, guess.marks) {
                result[letter] = max(result[letter] ?? .absent, mark)
            }
        }
        return result
    }

    func validationError(for word: String, acceptedWords: Set<String>) -> String? {
        guard word.count == difficulty.letterCount else {
            return "Enter a \(difficulty.letterCount)-letter word."
        }
        guard acceptedWords.contains(word) || word == answer else {
            return "That word isn’t in our dictionary. Try another."
        }
        guard !guesses.contains(where: { $0.word == word }) else {
            return "You’ve tried that word. Try something new."
        }
        if difficulty == .expert {
            for guess in guesses {
                let letters = Array(guess.word)
                let proposed = Array(word)
                var required: [Character: Int] = [:]
                for index in letters.indices {
                    if guess.marks[index] == .correct && proposed[index] != letters[index] {
                        return "Keep \(letters[index]) in position \(index + 1)."
                    }
                    if guess.marks[index] != .absent {
                        required[letters[index], default: 0] += 1
                    }
                }
                for (letter, count) in required.sorted(by: { $0.key < $1.key }) {
                    if proposed.filter({ $0 == letter }).count < count {
                        return count > 1 ? "Your next word needs \(count) \(letter)s." : "Use the \(letter) you found."
                    }
                }
            }
        }
        return nil
    }

    mutating func submit(acceptedWords: Set<String>, now: Date = Date()) -> String? {
        guard !isFinished else { return nil }
        if let error = validationError(for: draft, acceptedWords: acceptedWords) { return error }
        guesses.append(.evaluate(draft, answer: answer))
        if draft == answer { outcome = .won }
        else if guesses.count == difficulty.guessLimit { outcome = .lost }
        draft = ""
        if isFinished { finishedAt = now }
        return nil
    }

    var shareText: String {
        let score = outcome == .won ? String(guesses.count) : "X"
        let board = guesses.map { $0.marks.map(\.shareSymbol).joined() }.joined(separator: "\n")
        return "Encore · \(difficulty.title) · \(score)/\(difficulty.guessLimit)\n\n\(board)\n\nOne more good word."
    }
}

struct RoundRecord: Codable, Identifiable {
    let id: UUID
    let difficulty: Difficulty
    let answer: String
    let outcome: RoundOutcome
    let guessCount: Int
    let finishedAt: Date
}

struct GameStatistics {
    let records: [RoundRecord]
    var played: Int { records.count }
    var wins: Int { records.filter { $0.outcome == .won }.count }
    var winRate: Int { played == 0 ? 0 : Int((Double(wins) / Double(played) * 100).rounded()) }
    var currentStreak: Int {
        records.reversed().prefix(while: { $0.outcome == .won }).count
    }
    var bestStreak: Int {
        var best = 0
        var current = 0
        for record in records {
            current = record.outcome == .won ? current + 1 : 0
            best = max(best, current)
        }
        return best
    }
    var averageGuesses: Double {
        let winning = records.filter { $0.outcome == .won }
        guard !winning.isEmpty else { return 0 }
        return Double(winning.reduce(0) { $0 + $1.guessCount }) / Double(winning.count)
    }
}
