// KeyAction.swift — Keyboat
// Every possible action a key can produce. Sendable for safe actor crossing.

import Foundation

// MARK: - KeyAction

/// The complete action vocabulary of the keyboard.
/// All key presses are translated into one of these before reaching the InputEngine.
public enum KeyAction: Sendable, Equatable {

    // MARK: Character insertion
    case character(Character)
    case space
    case `return`
    case tab

    // MARK: Deletion
    case backspace
    case forwardDelete

    // MARK: Shift state
    case shift
    case capsLock

    // MARK: Page switching
    case numbers        // → numeric / symbol page
    case symbols        // → symbols page (ABC#@!)
    case alphabet       // → back to alphabetic page

    // MARK: Cursor movement
    case moveCursor(direction: CursorDirection, unit: CursorUnit)

    // MARK: System
    case nextKeyboard   // globe key — switch input method
    case dismissKeyboard

    // MARK: Features
    case clipboard      // open clipboard panel
    case emoji          // open emoji panel
    case dictation
    case openSettings   // launch container app

    // MARK: Composed text (autocorrect / snippet insertion)
    case insertString(String)       // multi-char replacement
    case replaceCurrentWord(String) // used by autocorrect

    // MARK: Haptic hint (for long-press popups)
    case showAlternates(Character)
}

// MARK: - Supporting types

public enum CursorDirection: Sendable, Equatable {
    case left, right, up, down
    case wordLeft, wordRight
    case lineStart, lineEnd
    case documentStart, documentEnd
}

public enum CursorUnit: Sendable, Equatable {
    case character
    case word
    case line
    case document
}

// MARK: - Key repeat behaviour

/// Describes how a key behaves under long-press.
public enum RepeatBehavior: String, Codable, Sendable {
    case none           // tap only (e.g. Shift)
    case standard       // repeat at standard UIKit rate (Backspace, Arrow keys)
    case accelerating   // repeats and speeds up (Backspace long-hold)
    case longPressAlternates  // shows alternatives popup (letters with diacritics)
}
