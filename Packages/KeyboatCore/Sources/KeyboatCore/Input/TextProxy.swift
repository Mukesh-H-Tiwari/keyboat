// TextProxy.swift — Keyboat
// Protocol abstraction over UITextDocumentProxy.
// InputEngine only talks to this protocol — never to UIKit directly.
// This makes 100% of the input engine unit-testable without a running keyboard.

import Foundation

// MARK: - TextProxyProtocol

@MainActor
public protocol TextProxyProtocol: AnyObject {

    // MARK: Text content
    /// Text immediately before the cursor in the current document.
    var documentContextBeforeInput: String? { get }
    /// Text immediately after the cursor.
    var documentContextAfterInput: String? { get }
    /// Selected text, if any.
    var selectedText: String? { get }

    // MARK: Mutating operations
    /// Insert a string at the cursor position.
    func insertText(_ text: String)
    /// Delete one character to the left of the cursor.
    func deleteBackward()
    /// Adjust the cursor position by `offset` characters.
    /// Positive = right, negative = left.
    func adjustTextPosition(byCharacterOffset offset: Int)

    // MARK: Document state
    var hasText: Bool { get }
    var documentInputMode: DocumentInputMode? { get }
    var keyboardType: KeyboardTypeHint { get }
    var returnKeyType: ReturnKeyHint { get }
    var autocorrectionType: AutocorrectionHint { get }
}

// MARK: - Supporting enums (UIKit-free equivalents)

public enum DocumentInputMode: Sendable {
    case text
    case email
    case url
    case number
    case phone
    case search
    case password
}

public enum KeyboardTypeHint: Sendable {
    case `default`, asciiCapable, numbersAndPunctuation
    case url, numberPad, phonePad, namePhonePad
    case emailAddress, decimalPad, twitter, webSearch, asciiCapableNumberPad
}

public enum ReturnKeyHint: Sendable {
    case `default`, go, google, join, next, route, search, send, yahoo, done, emergencyCall, `continue`
}

public enum AutocorrectionHint: Sendable {
    case `default`, no, yes
}

// MARK: - MockTextProxy (for testing & SwiftUI previews)

/// Drop-in mock used in unit tests and SwiftUI previews.
/// Captures operations as a simple transcript.
@MainActor
public final class MockTextProxy: TextProxyProtocol {

    public private(set) var log: [ProxyOp] = []
    public var simulatedContext: String = ""

    public var documentContextBeforeInput: String? { simulatedContext }
    public var documentContextAfterInput: String? { nil }
    public var selectedText: String? { nil }
    public var hasText: Bool { !simulatedContext.isEmpty }
    public var documentInputMode: DocumentInputMode? { .text }
    public var keyboardType: KeyboardTypeHint { .default }
    public var returnKeyType: ReturnKeyHint { .default }
    public var autocorrectionType: AutocorrectionHint { .default }

    public init() {}

    public func insertText(_ text: String) {
        simulatedContext += text
        log.append(.insert(text))
    }

    public func deleteBackward() {
        if !simulatedContext.isEmpty { simulatedContext.removeLast() }
        log.append(.deleteBackward)
    }

    public func adjustTextPosition(byCharacterOffset offset: Int) {
        log.append(.adjustCursor(offset))
    }

    public func reset() {
        log.removeAll()
        simulatedContext = ""
    }

    public enum ProxyOp: Equatable {
        case insert(String)
        case deleteBackward
        case adjustCursor(Int)
    }
}
