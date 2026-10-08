import SwiftUI

struct HowToPlayView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    VStack(alignment: .leading, spacing: 10) {
                        Image(systemName: "infinity").font(.largeTitle).foregroundStyle(EncoreTheme.accent)
                        Text("A good word deserves an encore.")
                            .font(.system(.title, design: .serif, weight: .medium))
                        Text("Guess the hidden word, one try at a time. Finish a round and play another whenever you like. No daily limit. No timer.")
                            .font(.body).foregroundStyle(.secondary)
                    }
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Follow the letters").font(.headline)
                        Text("Tap the keyboard to fill the current row, then press Enter to check your word. The keys keep your clues: gray letters are ruled out, yellow letters belong somewhere else, and green letters are in the right spot.")
                            .font(.subheadline).foregroundStyle(.secondary)
                        example("C", mark: .correct, title: "Right letter, right spot", detail: "Keep this letter in this position.")
                        example("A", mark: .present, title: "Right letter, different spot", detail: "The word contains this letter somewhere else.")
                        example("T", mark: .absent, title: "Not in the word", detail: "Try a different letter. Repeated letters only light up as often as they appear in the answer.")
                    }
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Find your challenge").font(.headline)
                        ForEach(Difficulty.allCases) { difficulty in
                            HStack(alignment: .top, spacing: 14) {
                                Image(systemName: difficulty.symbol).foregroundStyle(EncoreTheme.accent)
                                    .frame(width: 24).padding(.top, 2)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("\(difficulty.title) · \(difficulty.detail)").font(.subheadline.weight(.semibold))
                                    Text(difficulty.description).font(.subheadline).foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    Text("Extra hard keeps you honest: your next guess must keep correct letters in place and include every letter you’ve found, including repeats. Any valid dictionary word is accepted; answers use a smaller selection. Some plurals and inflected words are included.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                .padding(24).frame(maxWidth: 600)
            }
            .navigationTitle("How to play").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", systemImage: "checkmark") { dismiss() }
                        .accessibilityIdentifier("doneButton")
                }
            }
        }
        .tint(EncoreTheme.accent)
    }

    private func example(_ letter: String, mark: LetterMark, title: String, detail: String) -> some View {
        HStack(alignment: .center, spacing: 14) {
            LetterTile(letter: letter, mark: mark, usesSymbols: true).frame(width: 48, height: 52)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.subheadline.weight(.semibold))
                Text(detail).font(.subheadline).foregroundStyle(.secondary)
            }
        }
    }
}
