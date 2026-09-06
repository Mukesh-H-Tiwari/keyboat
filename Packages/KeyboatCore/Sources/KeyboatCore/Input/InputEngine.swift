// InputEngine.swift — Keyboat
// Core input processor. Receives KeyActions, applies them to the TextProxy.
// This is THE critical path — must be fast, allocation-free on hot path.
// Fully UIKit-free, 100% unit testable.

import Foundation
import Combine
import os

// MARK: - InputEngineProtocol

public protocol InputEngineProtocol: AnyObject, Sendable {
    /// Handle a key action. Must be called on the main actor.
    @MainActor
    func handle(_ action: KeyAction, proxy: any TextProxyProtocol)
    /// Current shift state observed by the UI.
    @MainActor
    var shiftState: ShiftState { get }
    /// Current page (alphabetic / numeric / symbol).
    @MainActor
    var keyboardPage: KeyboardPage { get }
}

// MARK: - ShiftState

public enum ShiftState: Sendable, Equatable {
    case off
    case once       // engaged; deactivates after next character
    case locked     // CapsLock
}

// MARK: - KeyboardPage

public enum KeyboardPage: Sendable, Equatable {
    case alphabetic
    case numeric
    case symbolic
}

// MARK: - InputEngine (concrete)

@MainActor
public final class InputEngine: ObservableObject, InputEngineProtocol, Sendable {

    // MARK: State
    @Published public private(set) var shiftState: ShiftState = .once  // starts capitalised
    @Published public private(set) var keyboardPage: KeyboardPage = .alphabetic

    // MARK: Logging
    private let logger = Logger(subsystem: "com.mukeshtiwari.keyboat", category: "InputEngine")

    public init() {}

    // MARK: - Handle

    public func handle(_ action: KeyAction, proxy: any TextProxyProtocol) {
        switch action {

        // MARK: Character
        case .character(let char):
            let final = applyShift(to: char)
            proxy.insertText(String(final))
            advanceShiftAfterCharacter()

        // MARK: Simple insertions
        case .space:
            proxy.insertText(" ")
            advanceShiftAfterCharacter()

        case .return:
            proxy.insertText("\n")

        case .tab:
            proxy.insertText("\t")

        // MARK: Deletion
        case .backspace:
            proxy.deleteBackward()

        case .forwardDelete:
            proxy.adjustTextPosition(byCharacterOffset: 1)
            proxy.deleteBackward()

        // MARK: Shift
        case .shift:
            toggleShift()

        case .capsLock:
            shiftState = (shiftState == .locked) ? .off : .locked

        // MARK: Page switches
        case .numbers:
            keyboardPage = .numeric

        case .symbols:
            keyboardPage = .symbolic

        case .alphabet:
            keyboardPage = .alphabetic

        // MARK: Cursor movement
        case .moveCursor(let direction, _):
            handleCursorMovement(direction: direction, proxy: proxy)

        // MARK: Composed text
        case .insertString(let str):
            proxy.insertText(str)
            advanceShiftAfterCharacter()

        case .replaceCurrentWord(let replacement):
            replaceCurrentWord(with: replacement, proxy: proxy)

        // MARK: Feature actions (handled by KeyboardViewController, not InputEngine)
        case .nextKeyboard, .dismissKeyboard, .clipboard, .emoji, .dictation, .openSettings:
            logger.debug("Feature action \(String(describing: action)) forwarded to controller.")

        // MARK: Show alternates (UI concern only)
        case .showAlternates:
            break
        }
    }

    // MARK: - Private helpers

    private func applyShift(to char: Character) -> Character {
        switch shiftState {
        case .off:
            return char.lowercased().first ?? char
        case .once, .locked:
            return char.uppercased().first ?? char
        }
    }

    private func advanceShiftAfterCharacter() {
        if shiftState == .once { shiftState = .off }
    }

    private func toggleShift() {
        switch shiftState {
        case .off:   shiftState = .once
        case .once:  shiftState = .off
        case .locked: shiftState = .off
        }
    }

    private func handleCursorMovement(direction: CursorDirection, proxy: any TextProxyProtocol) {
        switch direction {
        case .left:       proxy.adjustTextPosition(byCharacterOffset: -1)
        case .right:      proxy.adjustTextPosition(byCharacterOffset: 1)
        case .wordLeft:   moveByWord(direction: -1, proxy: proxy)
        case .wordRight:  moveByWord(direction: 1, proxy: proxy)
        case .lineStart:  moveToLineStart(proxy: proxy)
        case .lineEnd:    moveToLineEnd(proxy: proxy)
        default:          break  // up/down/document require more context
        }
    }

    private func moveByWord(direction: Int, proxy: any TextProxyProtocol) {
        let context = direction < 0
            ? proxy.documentContextBeforeInput ?? ""
            : proxy.documentContextAfterInput ?? ""
        let words = context.components(separatedBy: .whitespaces)
        let move = (words.last ?? "").count + 1   // +1 for the space
        proxy.adjustTextPosition(byCharacterOffset: direction * move)
    }

    private func moveToLineStart(proxy: any TextProxyProtocol) {
        let before = proxy.documentContextBeforeInput ?? ""
        let toNewline = before.reversed().prefix(while: { $0 != "\n" }).count
        proxy.adjustTextPosition(byCharacterOffset: -toNewline)
    }

    private func moveToLineEnd(proxy: any TextProxyProtocol) {
        let after = proxy.documentContextAfterInput ?? ""
        let toNewline = after.prefix(while: { $0 != "\n" }).count
        proxy.adjustTextPosition(byCharacterOffset: toNewline)
    }

    private func replaceCurrentWord(with replacement: String, proxy: any TextProxyProtocol) {
        let before = proxy.documentContextBeforeInput ?? ""
        // Find the start of the current word
        let wordChars = before.reversed().prefix(while: { !$0.isWhitespace && !$0.isNewline })
        for _ in wordChars { proxy.deleteBackward() }
        proxy.insertText(replacement)
    }
}
