import SwiftUI

struct ContentView: View {
    @State private var game = Self.makeGame()
    @State private var sheet: GameSheet?
    @State private var pendingDifficulty: Difficulty?
    @State private var showConfirmation = false
    @State private var confirmationIsReveal = false
    @AppStorage("encore.haptics") private var haptics = true
    @AppStorage("encore.symbols") private var showSymbols = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiate
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                VStack(spacing: 0) {
                    roundHeader.padding(.top, 8).padding(.bottom, 16)
                    if geometry.size.width > geometry.size.height && !game.round.isFinished {
                        landscapeGame(size: geometry.size)
                    } else {
                        portraitGame(size: geometry.size)
                    }
                }
            }
            .background(EncoreBackdrop())
            .navigationTitle("Encore")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Encore").font(.system(.title3, design: .serif, weight: .semibold))
                        .accessibilityAddTraits(.isHeader)
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button("How to play", systemImage: "questionmark") { sheet = .help }
                        .accessibilityIdentifier("helpButton")
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button("Statistics", systemImage: "chart.bar.xaxis") { sheet = .statistics }
                        .accessibilityIdentifier("statsButton")
                    Menu {
                        Button("Settings", systemImage: "slider.horizontal.3") { sheet = .settings }
                        if !game.round.isFinished {
                            Button("Reveal word", systemImage: "eye") {
                                confirmationIsReveal = true
                                showConfirmation = true
                            }
                        }
                    } label: { Label("More", systemImage: "ellipsis") }
                    .accessibilityIdentifier("moreButton")
                }
            }
            .sheet(item: $sheet) { selected in
                switch selected {
                case .help: HowToPlayView()
                case .statistics: StatisticsView(game: game)
                case .settings: SettingsView(library: game.library)
                }
            }
            .confirmationDialog(confirmationIsReveal ? "Reveal this word?" : "Start a new round?",
                                isPresented: $showConfirmation, titleVisibility: .visible) {
                if confirmationIsReveal {
                    Button("Reveal word") { game.surrender() }
                } else {
                    Button("Start \(pendingDifficulty?.title ?? "new") round") {
                        if let difficulty = pendingDifficulty { game.startNewRound(difficulty: difficulty) }
                        pendingDifficulty = nil
                    }
                }
                Button("Keep playing") { }
            } message: {
                Text(confirmationIsReveal
                     ? "This ends the round and counts as a loss. You can play again straight away."
                     : "Your current round will count as a loss. Your previous results will stay saved.")
            }
            .sensoryFeedback(.error, trigger: game.errorPulse) { _, _ in haptics }
            .sensoryFeedback(.success, trigger: game.feedbackPulse) { _, _ in haptics && game.round.outcome == .won }
            .onChange(of: scenePhase) { _, phase in
                if phase != .active { game.persist() }
            }
            .background {
                HardwareKeyboardInput(isActive: sheet == nil && !showConfirmation && !game.round.isFinished,
                                      onLetter: game.enter, onDelete: game.delete, onSubmit: submit)
                    .frame(width: 0, height: 0).accessibilityHidden(true)
            }
        }
        .tint(EncoreTheme.accent)
    }

    private func portraitGame(size: CGSize) -> some View {
        let keyboardHeight: CGFloat = 202
        let headerHeight: CGFloat = typeSize.isAccessibilitySize ? 94 : 68
        let statusHeight: CGFloat = typeSize.isAccessibilitySize ? 54 : 38
        let boardHeight = max(180, size.height - headerHeight - (game.round.isFinished ? 220 : keyboardHeight + statusHeight))
        return VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 0) {
                    board(width: size.width, height: boardHeight)
                        .frame(minHeight: boardHeight)
                    if game.round.isFinished {
                        result.padding(.top, 24).padding(.bottom, 24)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .scrollIndicators(.hidden)
            if !game.round.isFinished {
                status.frame(minHeight: statusHeight).padding(.bottom, 6)
                keyboard.padding(.bottom, 8)
            }
        }
    }

    private func landscapeGame(size: CGSize) -> some View {
        let keyboardWidth = min(560, size.width * 0.5)
        return HStack(spacing: 12) {
            ScrollView {
                board(width: size.width - keyboardWidth - 12, height: size.height - 84)
                    .frame(maxWidth: .infinity).padding(.vertical, 4)
            }
            .scrollIndicators(.hidden)
            VStack(spacing: 10) {
                status
                keyboard
            }
            .frame(width: keyboardWidth)
        }
        .padding(.bottom, 8)
    }

    private var keyboard: some View {
        GameKeyboard(marks: game.round.keyboardMarks,
                     canSubmit: game.round.draft.count == game.round.difficulty.letterCount,
                     usesSymbols: showSymbols || differentiate,
                     onLetter: game.enter, onDelete: game.delete, onSubmit: submit)
            .frame(maxWidth: 560).frame(maxWidth: .infinity)
    }

    private var roundHeader: some View {
        HStack(spacing: 12) {
            Menu {
                ForEach(Difficulty.allCases) { difficulty in
                    Button { changeDifficulty(difficulty) } label: {
                        if game.round.difficulty == difficulty {
                            Label("\(difficulty.title) · \(difficulty.detail)", systemImage: "checkmark")
                        } else { Text("\(difficulty.title) · \(difficulty.detail)") }
                    }
                    .accessibilityIdentifier("difficulty_\(difficulty.rawValue)")
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: game.round.difficulty.symbol)
                    Text(game.round.difficulty.title).fontWeight(.semibold)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption2.weight(.semibold)).foregroundStyle(.secondary)
                }
                .font(.subheadline).padding(.horizontal, 4).padding(.vertical, 4)
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
            }
            .buttonStyle(.glass)
            .accessibilityLabel("Difficulty, \(game.round.difficulty.title), \(game.round.difficulty.detail)")
            .accessibilityIdentifier("difficultyMenu")
            Spacer(minLength: 4)
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(game.round.difficulty.letterCount) letters")
                    .font(typeSize.isAccessibilitySize ? .caption.weight(.medium) : .subheadline.weight(.medium))
                Text(game.round.isFinished ? "Unlimited rounds" : "\(game.round.remainingGuesses) guesses\(typeSize.isAccessibilitySize ? "" : " left")")
                    .font(.caption).foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .combine)
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: 560).frame(maxWidth: .infinity)
    }

    private func board(width: CGFloat, height: CGFloat) -> some View {
        let difficulty = game.round.difficulty
        let gap: CGFloat = 7
        let availableWidth = (min(width, 560) - 48 - CGFloat(difficulty.letterCount - 1) * gap) / CGFloat(difficulty.letterCount)
        let availableHeight = (height - 12 - CGFloat(difficulty.guessLimit - 1) * gap) / CGFloat(difficulty.guessLimit)
        let tileSize = max(24, min(62, availableWidth, availableHeight))
        return VStack(spacing: gap) {
            ForEach(0..<difficulty.guessLimit, id: \.self) { row in
                let guess = row < game.round.guesses.count ? game.round.guesses[row] : nil
                let active = !game.round.isFinished && row == game.round.guesses.count
                let letters = Array(guess?.word ?? (active ? game.round.draft : ""))
                HStack(spacing: gap) {
                    ForEach(0..<difficulty.letterCount, id: \.self) { column in
                        LetterTile(letter: column < letters.count ? String(letters[column]) : "",
                                   mark: guess?.marks[column], isCurrent: active && column == letters.count,
                                   usesSymbols: showSymbols || differentiate)
                        .frame(width: tileSize, height: tileSize)
                        .accessibilityIdentifier("tile_\(row)_\(column)")
                        .accessibilityLabel("Position \(column + 1), \(column < letters.count ? String(letters[column]) : "empty")\(guess.map { ", " + $0.marks[column].description } ?? "")")
                    }
                }
                .accessibilityElement(children: .contain)
                .accessibilityLabel("Guess \(row + 1)\(active ? ", current guess" : "")")
            }
        }
        .animation(reduceMotion ? nil : .smooth(duration: 0.18), value: game.round.guesses.count)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("wordBoard")
        .dynamicTypeSize(...DynamicTypeSize.xxLarge)
    }

    private var status: some View {
        Group {
            if let message = game.message ?? game.saveError {
                Text(message).font(.caption).foregroundStyle(.primary)
                    .multilineTextAlignment(.center).accessibilityIdentifier("gameMessage")
            } else {
                HStack(spacing: 16) {
                    legend(typeSize.isAccessibilitySize ? "Right" : "Right spot", mark: .correct)
                    legend(typeSize.isAccessibilitySize ? "Move" : "Wrong spot", mark: .present)
                    legend(typeSize.isAccessibilitySize ? "Absent" : "Not here", mark: .absent)
                }
                .font(.caption2).foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 20).frame(minHeight: 22)
    }

    private func legend(_ title: String, mark: LetterMark) -> some View {
        HStack(spacing: 5) {
            RoundedRectangle(cornerRadius: 3).fill(EncoreTheme.fill(for: mark))
                .frame(width: 9, height: 9).accessibilityHidden(true)
            Text(title)
        }
    }

    private var result: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Text(game.round.outcome == .won ? "Nicely done." : "A word for next time.")
                    .font(.system(.title2, design: .serif, weight: .medium))
                    .accessibilityIdentifier("gameHeading")
                Text(game.round.answer).font(.system(.title2, design: .rounded, weight: .bold))
                    .tracking(5).foregroundStyle(game.round.outcome == .won ? EncoreTheme.correct : .primary)
                    .accessibilityIdentifier("revealedAnswer")
                Text(game.round.outcome == .won
                     ? "Found in \(game.round.guesses.count) \(game.round.guesses.count == 1 ? "guess" : "guesses"). There’s always another."
                     : "Every round is a fresh start.")
                    .font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
            }
            GlassEffectContainer(spacing: 16) {
                HStack(spacing: 12) {
                    Button("Play again", systemImage: "arrow.right") { game.startNewRound() }
                        .buttonStyle(.glassProminent).controlSize(.large)
                        .accessibilityIdentifier("playAgainButton")
                    ShareLink(item: game.round.shareText) {
                        Label("Share result", systemImage: "square.and.arrow.up").labelStyle(.iconOnly)
                    }
                    .buttonStyle(.glass).controlSize(.large).accessibilityIdentifier("shareButton")
                }
            }
        }
        .padding(.horizontal, 24)
    }

    private func changeDifficulty(_ difficulty: Difficulty) {
        guard difficulty != game.round.difficulty else { return }
        if !game.round.isFinished && !game.round.guesses.isEmpty {
            pendingDifficulty = difficulty
            confirmationIsReveal = false
            showConfirmation = true
        } else { game.startNewRound(difficulty: difficulty) }
    }

    private func submit() {
        withAnimation(reduceMotion ? nil : .smooth(duration: 0.2)) { game.submit() }
        if let error = game.message { AccessibilityNotification.Announcement(error).post() }
        else if game.round.isFinished {
            AccessibilityNotification.Announcement(game.round.outcome == .won
                ? "Nicely done! The word was \(game.round.answer). Play again whenever you like."
                : "The word was \(game.round.answer). You can play again.").post()
        }
    }

    private static func makeGame() -> GameStore {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-ui-testing") {
            let defaults = EncorePreferences.defaults
            defaults.removePersistentDomain(forName: "encore.ui-tests")
            let game = GameStore(defaults: defaults)
            game.prepareUITest(answer: "CRANE")
            return game
        }
        #endif
        return GameStore(defaults: EncorePreferences.defaults)
    }
}

enum GameSheet: String, Identifiable {
    case help, statistics, settings
    var id: String { rawValue }
}

#Preview { ContentView() }
