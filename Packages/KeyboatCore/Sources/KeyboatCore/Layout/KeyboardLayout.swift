// KeyboardLayout.swift — Keyboat
// Data model for a complete keyboard layout.
// Codable so layouts can be loaded from JSON in Resources/Layouts/.
// Sendable so it can be passed safely across concurrency boundaries.

import Foundation

// MARK: - KeyboardLayout

public struct KeyboardLayout: Codable, Sendable, Identifiable {
    public let id: String                       // e.g. "en-QWERTY"
    public let locale: String                   // BCP-47 locale tag, e.g. "en"
    public let displayName: String              // e.g. "English (QWERTY)"
    public let rows: [RowDefinition]
    public let numberRow: NumberRowDefinition?
    public let bottomRow: BottomRowDefinition

    public init(
        id: String,
        locale: String,
        displayName: String,
        rows: [RowDefinition],
        numberRow: NumberRowDefinition? = nil,
        bottomRow: BottomRowDefinition
    ) {
        self.id = id
        self.locale = locale
        self.displayName = displayName
        self.rows = rows
        self.numberRow = numberRow
        self.bottomRow = bottomRow
    }
}

// MARK: - RowDefinition

public struct RowDefinition: Codable, Sendable, Identifiable {
    public let id: String
    public let keys: [KeyDefinition]
    public let edgeSpacingFactor: CGFloat   // relative horizontal margin

    public init(id: String, keys: [KeyDefinition], edgeSpacingFactor: CGFloat = 0.0) {
        self.id = id
        self.keys = keys
        self.edgeSpacingFactor = edgeSpacingFactor
    }
}

// MARK: - NumberRowDefinition

public struct NumberRowDefinition: Codable, Sendable {
    public let keys: [KeyDefinition]

    public init(keys: [KeyDefinition]) {
        self.keys = keys
    }
}

// MARK: - BottomRowDefinition

public struct BottomRowDefinition: Codable, Sendable {
    public let leftKeys: [KeyDefinition]      // e.g. [globe, numbers]
    public let spaceKey: KeyDefinition
    public let rightKeys: [KeyDefinition]     // e.g. [return]

    public init(leftKeys: [KeyDefinition], spaceKey: KeyDefinition, rightKeys: [KeyDefinition]) {
        self.leftKeys = leftKeys
        self.spaceKey = spaceKey
        self.rightKeys = rightKeys
    }
}

// MARK: - KeyDefinition

public struct KeyDefinition: Codable, Sendable, Identifiable {
    public let id: String
    public let label: String                  // primary display text
    public let secondaryLabel: String?        // shown in top corner (number row hint)
    public let action: EncodableKeyAction
    public let widthFactor: CGFloat           // 1.0 = standard key width
    public let heightFactor: CGFloat          // 1.0 = standard key height
    public let repeatBehavior: RepeatBehavior
    public let accessibilityLabel: String
    public let accessibilityHint: String?

    public init(
        id: String,
        label: String,
        secondaryLabel: String? = nil,
        action: EncodableKeyAction,
        widthFactor: CGFloat = 1.0,
        heightFactor: CGFloat = 1.0,
        repeatBehavior: RepeatBehavior = .none,
        accessibilityLabel: String,
        accessibilityHint: String? = nil
    ) {
        self.id = id
        self.label = label
        self.secondaryLabel = secondaryLabel
        self.action = action
        self.widthFactor = widthFactor
        self.heightFactor = heightFactor
        self.repeatBehavior = repeatBehavior
        self.accessibilityLabel = accessibilityLabel
        self.accessibilityHint = accessibilityHint
    }
}

// MARK: - EncodableKeyAction
// A Codable mirror of KeyAction for JSON layout files.
// Translated to KeyAction at runtime by LayoutEngine.

public enum EncodableKeyAction: Codable, Sendable {
    case character(String)          // single char as String for JSON compatibility
    case space
    case `return`
    case tab
    case backspace
    case shift
    case capsLock
    case numbers
    case symbols
    case alphabet
    case nextKeyboard
    case dismissKeyboard
    case clipboard
    case emoji
    case dictation
    case openSettings

    /// Convert to the canonical KeyAction used by InputEngine.
    public func toKeyAction() -> KeyAction {
        switch self {
        case .character(let s):   return .character(s.first ?? " ")
        case .space:              return .space
        case .return:             return .return
        case .tab:                return .tab
        case .backspace:          return .backspace
        case .shift:              return .shift
        case .capsLock:           return .capsLock
        case .numbers:            return .numbers
        case .symbols:            return .symbols
        case .alphabet:           return .alphabet
        case .nextKeyboard:       return .nextKeyboard
        case .dismissKeyboard:    return .dismissKeyboard
        case .clipboard:          return .clipboard
        case .emoji:              return .emoji
        case .dictation:          return .dictation
        case .openSettings:       return .openSettings
        }
    }
}
