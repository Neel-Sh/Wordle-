import SwiftUI

enum EncoreTheme {
    static let accent = Color("AccentColor")
    static let correct = Color("CorrectColor")
    static let present = Color("PresentColor")
    static let absent = Color(uiColor: .systemGray)

    static func fill(for mark: LetterMark) -> Color {
        switch mark {
        case .correct: correct
        case .present: present
        case .absent: absent
        }
    }

    static func ink(for mark: LetterMark?) -> Color {
        switch mark {
        case .correct, .absent: .white
        case .present: .black
        case nil: .primary
        }
    }
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
        case let mark?: EncoreTheme.fill(for: mark)
        case nil: Color(uiColor: .secondarySystemGroupedBackground).opacity(scheme == .dark ? 0.8 : 1)
        }
    }

    private var letterColor: Color {
        EncoreTheme.ink(for: mark)
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            RoundedRectangle(cornerRadius: 12, style: .continuous).fill(fill)
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(isCurrent ? EncoreTheme.accent.opacity(0.55) : Color.primary.opacity(contrast == .increased ? 0.35 : (!letter.isEmpty && mark == nil ? 0.25 : 0.07)),
                              lineWidth: isCurrent ? 2 : 1)
            Text(letter).font(.system(size: 26, weight: .bold, design: .rounded))
                .minimumScaleFactor(0.6).lineLimit(1)
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
