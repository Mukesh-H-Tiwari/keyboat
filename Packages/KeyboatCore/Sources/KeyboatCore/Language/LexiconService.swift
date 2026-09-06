// LexiconService.swift — Keyboat
// Manages the UILexicon words, injected from KeyboardViewController.
// Kept UIKit-free here — the extension injects word strings.

import Foundation

// MARK: - LexiconServiceProtocol

public protocol LexiconServiceProtocol: AnyObject, Sendable {
    var words: [String] { get }
    func inject(words: [String])
    func contains(_ word: String) -> Bool
}

// MARK: - LexiconService

public final class LexiconService: LexiconServiceProtocol, @unchecked Sendable {

    public static let shared = LexiconService()

    private var _words: [String] = []
    private var _wordSet: Set<String> = []
    private let lock = NSLock()

    private init() {}

    public var words: [String] {
        lock.lock(); defer { lock.unlock() }
        return _words
    }

    /// Called once from KeyboardViewController after UILexicon is available.
    public func inject(words: [String]) {
        lock.lock(); defer { lock.unlock() }
        _words = words
        _wordSet = Set(words.map { $0.lowercased() })
    }

    public func contains(_ word: String) -> Bool {
        lock.lock(); defer { lock.unlock() }
        return _wordSet.contains(word.lowercased())
    }
}
