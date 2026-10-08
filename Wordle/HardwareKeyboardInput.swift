import SwiftUI
import UIKit

// A responder for physical keyboards, with no text field or software keyboard.
struct HardwareKeyboardInput: UIViewRepresentable {
    let isActive: Bool
    let onLetter: (String) -> Void
    let onDelete: () -> Void
    let onSubmit: () -> Void

    func makeUIView(context: Context) -> CommandView { CommandView() }

    func updateUIView(_ view: CommandView, context: Context) {
        view.onLetter = onLetter
        view.onDelete = onDelete
        view.onSubmit = onSubmit
        view.isActive = isActive
        if isActive && view.window != nil && !view.isFirstResponder {
            view.becomeFirstResponder()
        } else if !isActive && view.isFirstResponder {
            view.resignFirstResponder()
        }
    }

    final class CommandView: UIView {
        var isActive = false
        var onLetter: ((String) -> Void)?
        var onDelete: (() -> Void)?
        var onSubmit: (() -> Void)?
        override var canBecomeFirstResponder: Bool { isActive }

        override func didMoveToWindow() {
            super.didMoveToWindow()
            if window != nil && isActive { becomeFirstResponder() }
        }

        override var keyCommands: [UIKeyCommand]? {
            guard isActive else { return [] }
            let letters = "abcdefghijklmnopqrstuvwxyz".flatMap { letter in
                [UIKeyCommand(input: String(letter), modifierFlags: [], action: #selector(typeLetter)),
                 UIKeyCommand(input: String(letter), modifierFlags: .shift, action: #selector(typeLetter))]
            }
            return letters + [
                UIKeyCommand(input: "\r", modifierFlags: [], action: #selector(submitGuess)),
                UIKeyCommand(input: UIKeyCommand.inputDelete, modifierFlags: [], action: #selector(deleteLetter))
            ]
        }

        @objc private func typeLetter(_ command: UIKeyCommand) {
            guard isActive, let input = command.input else { return }
            onLetter?(input.uppercased())
        }
        @objc private func deleteLetter() { if isActive { onDelete?() } }
        @objc private func submitGuess() { if isActive { onSubmit?() } }
    }
}
