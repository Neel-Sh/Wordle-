import SwiftUI

enum EncoreTheme {
    static let accent = Color("AccentColor")
    static let correct = Color("CorrectColor")
    static let present = Color("PresentColor")
}

struct EncoreBackdrop: View {
    var body: some View {
        Color(uiColor: .systemGroupedBackground).ignoresSafeArea()
    }
}

struct LetterTile: View {
    let letter: String
    var mark: LetterMark?
    var isCurrent = false
    var usesSymbols = false
    @Environment(\.colorScheme) private var scheme
    @Environment(\.colorSchemeContrast) private var contrast

    private var fill: Color {
        switch mark {
        case .correct: EncoreTheme.correct
        case .present: EncoreTheme.present
        case .absent: Color(uiColor: .tertiarySystemFill)
        case nil: Color(uiColor: .secondarySystemGroupedBackground).opacity(scheme == .dark ? 0.8 : 0.75)
        }
    }

    private var letterColor: Color {
        switch mark {
        case .correct: .white
        case .present: .black
        default: .primary
        }
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            RoundedRectangle(cornerRadius: 13, style: .continuous).fill(fill)
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .strokeBorder(isCurrent ? EncoreTheme.accent.opacity(0.65) : Color.primary.opacity(contrast == .increased ? 0.28 : 0.04),
                              lineWidth: isCurrent ? 1.5 : 1)
            Text(letter).font(.system(.title2, design: .rounded, weight: .semibold))
                .foregroundStyle(letterColor)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            if usesSymbols, let mark, !letter.isEmpty {
                Image(systemName: mark == .correct ? "checkmark" : mark == .present ? "arrow.left.arrow.right" : "minus")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(letterColor).padding(5)
            }
        }
    }
}
