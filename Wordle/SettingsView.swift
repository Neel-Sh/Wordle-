import SwiftUI

struct SettingsView: View {
    let library: WordLibrary
    @AppStorage("encore.haptics") private var haptics = true
    @AppStorage("encore.symbols") private var showSymbols = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Haptic feedback", systemImage: "hand.tap", isOn: $haptics)
                    Toggle("Show clue symbols", systemImage: "checkmark.square", isOn: $showSymbols)
                } header: {
                    Text("Make it yours")
                } footer: {
                    Text("Clue symbols add a checkmark, arrows, or a dash to letters. They also turn on automatically when Differentiate Without Color is enabled.")
                }
                Section {
                    LabeledContent("Playable answers", value: library.answerCount.formatted())
                    LabeledContent("Accepted guesses", value: library.acceptedWords.count.formatted())
                    ForEach(Difficulty.allCases) { difficulty in
                        LabeledContent(difficulty.title, value: (library.answers[difficulty]?.count ?? 0).formatted())
                    }
                } header: {
                    Text("Room for one more")
                } footer: {
                    Text("The whole dictionary lives on your device. Each difficulty avoids repeated answers until its pool has been played, then starts a fresh shuffle. No account or internet connection needed.")
                }
                Section {
                    NavigationLink("Word library credits") { WordCreditsView() }
                } footer: {
                    Text("Encore · One more good word.\nAn independent word game, with no connection to The New York Times.")
                }
            }
            .navigationTitle("Settings").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", systemImage: "checkmark") { dismiss() }
                        .accessibilityIdentifier("doneButton")
                }
            }
        }.tint(EncoreTheme.accent)
    }
}

struct WordCreditsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("English words, thoughtfully selected.").font(.title2.weight(.semibold))
                Text("Encore’s word library is derived from SCOWL (Spell Checker Oriented Word Lists), release 2020.12.07, by Kevin Atkinson and its contributors. Answer pools use commonness levels appropriate to each difficulty. Proper names, abbreviations, punctuation, and a list of sensitive terms are excluded from answers.")
                Link("SCOWL project", destination: URL(string: "https://wordlist.aspell.net")!)
                Text(license).font(.footnote).foregroundStyle(.secondary)
            }.padding(24)
        }
        .navigationTitle("Word library credits").navigationBarTitleDisplayMode(.inline)
    }

    private var license: String {
        guard let url = Bundle.main.url(forResource: "WordListLicense", withExtension: "txt") else { return "" }
        return (try? String(contentsOf: url, encoding: .utf8)) ?? ""
    }
}
