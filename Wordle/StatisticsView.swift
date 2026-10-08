import SwiftUI

struct StatisticsView: View {
    let game: GameStore
    @State private var selectedDifficulty: Difficulty?
    @Environment(\.dismiss) private var dismiss

    private var filtered: [RoundRecord] {
        game.records.filter { selectedDifficulty == nil || $0.difficulty == selectedDifficulty }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Menu {
                        Picker("Difficulty", selection: $selectedDifficulty) {
                            Text("All difficulties").tag(Optional<Difficulty>.none)
                            ForEach(Difficulty.allCases) { difficulty in
                                Text(difficulty.title).tag(Optional(difficulty))
                            }
                        }
                    } label: {
                        Label(selectedDifficulty?.title ?? "All difficulties", systemImage: "line.3.horizontal.decrease")
                    }
                    .buttonStyle(.glass)

                    let statistics = GameStatistics(records: filtered)
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        metric("Played", value: "\(statistics.played)", symbol: "square.grid.2x2")
                        metric("Win rate", value: "\(statistics.winRate)%", symbol: "checkmark")
                        metric("Current streak", value: "\(statistics.currentStreak)", symbol: "flame")
                        metric("Best streak", value: "\(statistics.bestStreak)", symbol: "trophy")
                    }
                    .accessibilityIdentifier("statisticsGrid")

                    if filtered.isEmpty {
                        ContentUnavailableView("Your story starts here", systemImage: "chart.bar.xaxis",
                            description: Text("Finish a round to see your progress. There’s no daily limit on a good streak."))
                    } else {
                        distribution
                        recentRounds
                    }
                }
                .padding(24).frame(maxWidth: 600)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Your wordplay").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", systemImage: "checkmark") { dismiss() }
                        .accessibilityIdentifier("doneButton")
                }
            }
        }
        .tint(EncoreTheme.accent)
    }

    private func metric(_ title: String, value: String, symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: symbol).foregroundStyle(EncoreTheme.accent).font(.subheadline)
            Text(value).font(.system(.largeTitle, design: .rounded, weight: .semibold)).monospacedDigit()
            Text(title).font(.subheadline).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading).padding(18)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 22))
        .accessibilityElement(children: .ignore).accessibilityLabel("\(title), \(value)")
    }

    private var distribution: some View {
        let wins = filtered.filter { $0.outcome == .won }
        let counts = (1...7).map { guess in wins.filter { $0.guessCount == guess }.count }
        let highest = max(counts.max() ?? 0, 1)
        return VStack(alignment: .leading, spacing: 12) {
            Text("Guesses to a good word").font(.headline)
            ForEach(1...7, id: \.self) { guess in
                HStack(spacing: 12) {
                    Text("\(guess)").font(.subheadline.monospacedDigit()).frame(width: 16)
                    GeometryReader { geometry in
                        RoundedRectangle(cornerRadius: 6)
                            .fill(counts[guess - 1] > 0 ? EncoreTheme.accent : Color.primary.opacity(0.08))
                            .frame(width: max(28, geometry.size.width * CGFloat(counts[guess - 1]) / CGFloat(highest)))
                            .overlay(alignment: .trailing) {
                                Text("\(counts[guess - 1])").font(.caption.weight(.semibold))
                                    .foregroundStyle(counts[guess - 1] > 0 ? Color(uiColor: .systemBackground) : .secondary).padding(.trailing, 8)
                            }
                    }.frame(height: 26)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(guess) guesses, \(counts[guess - 1]) wins")
            }
            Text("Winning rounds only. Streaks count consecutive rounds, so you can build one any day.")
                .font(.footnote).foregroundStyle(.secondary)
        }
    }

    private var recentRounds: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent rounds").font(.headline)
            ForEach(Array(filtered.suffix(12).reversed())) { record in
                HStack(spacing: 12) {
                    Image(systemName: record.outcome == .won ? "checkmark.circle.fill" : "arrow.uturn.forward.circle")
                        .foregroundStyle(.secondary)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(record.answer).font(.system(.subheadline, design: .rounded, weight: .semibold)).tracking(2)
                        Text(record.difficulty.title).font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 3) {
                        Text(record.outcome == .won ? "\(record.guessCount)/\(record.difficulty.guessLimit)" : "Not solved")
                            .font(.subheadline.monospacedDigit())
                        Text(record.finishedAt, style: .date).font(.caption2).foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}
