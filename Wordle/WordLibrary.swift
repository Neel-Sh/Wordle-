import Foundation

struct WordLibrary {
    let answers: [Difficulty: [String]]
    let acceptedWords: Set<String>

    var answerCount: Int { answers.values.reduce(0) { $0 + $1.count } }

    init(bundle: Bundle = .main) {
        guard let answersURL = bundle.url(forResource: "answers", withExtension: "json"),
              let guessesURL = bundle.url(forResource: "accepted", withExtension: "txt"),
              let data = try? Data(contentsOf: answersURL),
              let lists = try? JSONDecoder().decode([String: [String]].self, from: data),
              let guesses = try? String(contentsOf: guessesURL, encoding: .utf8) else {
            preconditionFailure("Encore’s bundled word library is missing or invalid.")
        }
        answers = Dictionary(uniqueKeysWithValues: Difficulty.allCases.map { difficulty in
            let words = lists[difficulty.rawValue] ?? []
            precondition(!words.isEmpty, "Missing answer pool for \(difficulty.title)")
            return (difficulty, words)
        })
        acceptedWords = Set(guesses.split(separator: "\n").map(String.init))
            .union(answers.values.flatMap { $0 })
    }

    init(answers: [Difficulty: [String]], acceptedWords: Set<String>) {
        self.answers = answers
        self.acceptedWords = acceptedWords.union(answers.values.flatMap { $0 })
    }

    func nextAnswer(for difficulty: Difficulty, seen: inout [String], previous: String?) -> String {
        let pool = answers[difficulty] ?? []
        precondition(!pool.isEmpty)
        let seenSet = Set(seen)
        var available = pool.filter { !seenSet.contains($0) }
        if available.isEmpty {
            seen.removeAll()
            available = pool.filter { $0 != previous }
            if available.isEmpty { available = pool }
        }
        let answer = available.randomElement()!
        seen.append(answer)
        return answer
    }
}
