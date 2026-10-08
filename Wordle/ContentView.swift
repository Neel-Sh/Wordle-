import SwiftUI

struct ContentView: View {
    @State private var game = Self.makeGame()
    @State private var sheet: GameSheet?
    @State private var pendingDifficulty: Difficulty?
    @State private var showConfirmation = false
    @State private var confirmationIsReveal = false
    @FocusState private var inputFocused: Bool
    @AppStorage("encore.haptics") private var haptics = true
    @AppStorage("encore.symbols") private var showSymbols = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiate
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: 0) {
                        roundHeader.padding(.top, 8).padding(.bottom, 14)
                        board(width: geometry.size.width, height: geometry.size.height)
                        if game.round.isFinished {
                            result.padding(.top, 24).padding(.bottom, 24)
                        } else {
                            status.padding(.top, 12).padding(.bottom, 8)
                        }
                    }
                    .frame(maxWidth: 560)
                    .frame(maxWidth: .infinity)
                }
                .scrollIndicators(.hidden)
                .scrollDismissesKeyboard(.interactively)
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    if !game.round.isFinished { guessInput }
                }
            }
            .background(EncoreBackdrop())
            .navigationTitle("Encore")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
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
                                inputFocused = false
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
            .onChange(of: game.round.isFinished) { _, finished in inputFocused = !finished }
            .onChange(of: game.round.id) { _, _ in inputFocused = !game.round.isFinished }
            .onChange(of: sheet) { _, value in inputFocused = value == nil && !game.round.isFinished }
            .onChange(of: showConfirmation) { _, presented in
                if !presented { inputFocused = !game.round.isFinished }
            }
            .task { inputFocused = !game.round.isFinished }
        }
        .tint(EncoreTheme.accent)
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
    }

    private func board(width: CGFloat, height: CGFloat) -> some View {
        let difficulty = game.round.difficulty
        let gap: CGFloat = 6
        let tileWidth = max(28, min(56, (min(width, 560) - 48 - CGFloat(difficulty.letterCount - 1) * gap) / CGFloat(difficulty.letterCount)))
        // Geometry already follows the system keyboard's safe area. Reserve room
        // for the header, clue line, and input accessory, then fit every row.
        let budget = max(120, height - (typeSize.isAccessibilitySize ? 220 : 180))
        let fittedHeight = (budget - CGFloat(difficulty.guessLimit - 1) * gap) / CGFloat(difficulty.guessLimit)
        let tileHeight = max(24, min(tileWidth, fittedHeight))
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
                        .frame(width: tileWidth, height: tileHeight)
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

    private var guessInput: some View {
        HStack(spacing: 12) {
            TextField("Type a \(game.round.difficulty.letterCount)-letter word", text: Binding(
                get: { game.round.draft }, set: { game.replaceDraft($0) }))
                .font(.system(.body, design: .rounded, weight: .medium))
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .keyboardType(.asciiCapable)
                .submitLabel(.return)
                .focused($inputFocused)
                .onSubmit(submit)
                .frame(minHeight: 44)
                .accessibilityLabel("Your guess")
                .accessibilityIdentifier("guessField")
            Button("Check", systemImage: "arrow.turn.down.left", action: submit)
                .buttonStyle(.glassProminent)
                .controlSize(.large)
                .disabled(game.round.draft.count != game.round.difficulty.letterCount)
                .accessibilityIdentifier("submitButton")
        }
        .padding(.horizontal, 20).padding(.vertical, 8)
        .frame(maxWidth: 560)
        .frame(maxWidth: .infinity)
        .background(.bar)
    }

    private var status: some View {
        Group {
            if let message = game.message ?? game.saveError {
                Text(message).font(.caption).foregroundStyle(.primary)
                    .multilineTextAlignment(.center).accessibilityIdentifier("gameMessage")
            } else {
                HStack(spacing: 16) {
                    legend(typeSize.isAccessibilitySize ? "Right" : "Right spot", symbol: "checkmark")
                    legend(typeSize.isAccessibilitySize ? "Move" : "Wrong spot", symbol: "arrow.left.arrow.right")
                    legend(typeSize.isAccessibilitySize ? "Absent" : "Not here", symbol: "minus")
                }
                .font(.caption2).foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 20).frame(minHeight: 22)
    }

    private func legend(_ title: String, symbol: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: symbol).font(.system(size: 9, weight: .bold))
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
            inputFocused = false
            pendingDifficulty = difficulty
            confirmationIsReveal = false
            showConfirmation = true
        } else { game.startNewRound(difficulty: difficulty) }
    }

    private func submit() {
        withAnimation(reduceMotion ? nil : .smooth(duration: 0.2)) { game.submit() }
        if let error = game.message { AccessibilityNotification.Announcement(error).post() }
        else if game.round.isFinished {
            inputFocused = false
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
