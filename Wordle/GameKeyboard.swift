import SwiftUI

struct GameKeyboard: View {
    let marks: [Character: LetterMark]
    let canSubmit: Bool
    let usesSymbols: Bool
    let onLetter: (String) -> Void
    let onDelete: () -> Void
    let onSubmit: () -> Void

    private let gap: CGFloat = 6
    private let keyHeight: CGFloat = 56

    var body: some View {
        GeometryReader { geometry in
            let keyWidth = max(1, (geometry.size.width - 20 - gap * 9) / 10)
            VStack(spacing: 8) {
                letterRow("QWERTYUIOP", keyWidth: keyWidth)
                letterRow("ASDFGHJKL", keyWidth: keyWidth)
                HStack(spacing: gap) {
                    Button(action: onSubmit) {
                        Text("ENTER").font(.system(size: 11, weight: .bold, design: .rounded))
                            .minimumScaleFactor(0.7).lineLimit(1)
                            .frame(width: keyWidth * 1.5 + gap / 2, height: keyHeight)
                    }
                    .buttonStyle(KeyboardKeyStyle(isEmphasized: canSubmit))
                    .accessibilityLabel("Enter guess")
                    .accessibilityHint("Checks the word in the current row")
                    .accessibilityIdentifier("keyboardEnter")
                    ForEach(Array("ZXCVBNM"), id: \.self) { letter in
                        letterKey(letter, width: keyWidth)
                    }
                    Button(action: onDelete) {
                        Image(systemName: "delete.left").font(.system(size: 19, weight: .medium))
                            .frame(width: keyWidth * 1.5 + gap / 2, height: keyHeight)
                    }
                    .buttonStyle(KeyboardKeyStyle())
                    .accessibilityLabel("Delete letter")
                    .accessibilityIdentifier("keyboardDelete")
                }
            }
            .frame(maxWidth: .infinity)
        }
        .frame(height: keyHeight * 3 + 16)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Game keyboard")
        .accessibilityIdentifier("gameKeyboard")
    }

    private func letterRow(_ letters: String, keyWidth: CGFloat) -> some View {
        HStack(spacing: gap) {
            ForEach(Array(letters), id: \.self) { letter in
                letterKey(letter, width: keyWidth)
            }
        }
    }

    private func letterKey(_ letter: Character, width: CGFloat) -> some View {
        let mark = marks[letter]
        return Button { onLetter(String(letter)) } label: {
            ZStack(alignment: .bottom) {
                Text(String(letter)).font(.system(size: 18, weight: .semibold, design: .rounded))
                    .frame(width: width, height: keyHeight)
                if usesSymbols, let mark {
                    Image(systemName: mark == .correct ? "checkmark" : mark == .present ? "arrow.left.arrow.right" : "minus")
                        .font(.system(size: 7, weight: .bold)).padding(.bottom, 5)
                }
            }
        }
        .buttonStyle(KeyboardKeyStyle(mark: mark))
        .accessibilityLabel(String(letter))
        .accessibilityValue(mark?.description ?? "Not used")
        .accessibilityIdentifier("key_\(letter)")
    }
}

private struct KeyboardKeyStyle: ButtonStyle {
    var mark: LetterMark?
    var isEmphasized = false
    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        let shape = RoundedRectangle(cornerRadius: 9, style: .continuous)
        configuration.label
            .foregroundStyle(isEmphasized ? Color(uiColor: .systemBackground) : EncoreTheme.ink(for: mark))
            .background {
                if let mark {
                    shape.fill(EncoreTheme.fill(for: mark))
                } else {
                    shape.fill(isEmphasized ? Color.primary : Color(uiColor: .secondarySystemGroupedBackground))
                }
            }
            .overlay {
                shape.strokeBorder(Color.primary.opacity(contrast == .increased ? 0.3 : 0.07), lineWidth: 1)
            }
            .compositingGroup()
            .shadow(color: .black.opacity(configuration.isPressed ? 0 : 0.06), radius: 0, y: 2)
            .opacity(configuration.isPressed ? 0.7 : 1)
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.96 : 1)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.1), value: configuration.isPressed)
            .contentShape(shape)
    }
}
