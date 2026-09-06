// PredictionEngine.swift — Keyboat
// Protocol stub + UILexicon-backed V1 implementation.
// Async so it never blocks the main thread (typing must never wait for prediction).

import Foundation
import NaturalLanguage

// MARK: - PredictionEngineProtocol

public protocol PredictionEngineProtocol: AnyObject, Sendable {
    /// Returns ranked candidate words given the text before the cursor.
    /// Returns empty array if no useful predictions available.
    func candidates(for contextBefore: String) async -> [String]
}

// MARK: - LexiconPredictionEngine

/// V1: Uses UILexicon entries + NLTokenizer for basic next-word candidates.
/// The UILexicon must be injected from the keyboard extension (it requires UIKit).
/// This class is UIKit-free — it only receives the lexicon entries as strings.
public final class LexiconPredictionEngine: PredictionEngineProtocol, @unchecked Sendable {

    private let lexiconEntries: [String]        // injected from KeyboardViewController
    private let tokenizer: NLTokenizer

    public init(lexiconEntries: [String] = []) {
        self.lexiconEntries = lexiconEntries
        self.tokenizer = NLTokenizer(unit: .word)
    }

    public func candidates(for contextBefore: String) async -> [String] {
        guard !contextBefore.isEmpty else { return [] }

        // Extract the current incomplete word being typed
        let currentWord = extractCurrentWord(from: contextBefore).lowercased()
        guard !currentWord.isEmpty else { return [] }

        // Match against lexicon entries
        let matches = lexiconEntries
            .filter { $0.lowercased().hasPrefix(currentWord) && $0.lowercased() != currentWord }
            .prefix(5)
            .map { $0 }

        return matches.isEmpty ? staticFallback(for: currentWord) : Array(matches)
    }

    // MARK: - Private

    private func extractCurrentWord(from text: String) -> String {
        // Walk backwards from end, collecting non-whitespace characters
        return String(text.reversed().prefix(while: { !$0.isWhitespace && !$0.isNewline }).reversed())
    }

    private func staticFallback(for prefix: String) -> [String] {
        // Basic English completion fallback for very short prefixes
        let common = ["the", "that", "this", "they", "then", "there",
                      "with", "what", "when", "where", "which", "while",
                      "have", "has", "had", "here", "how", "her",
                      "and", "are", "all", "also", "any", "about",
                      "for", "from", "if", "in", "is", "it", "its",
                      "on", "of", "or", "out", "our", "one",
                      "be", "but", "by", "been", "being",
                      "you", "your", "we", "was", "were", "will", "would",
                      "not", "no", "new", "now", "next", "need",
                      "can", "could", "com", "just", "know", "like",
                      "so", "some", "she", "said"]
        return common
            .filter { $0.hasPrefix(prefix) }
            .prefix(3)
            .map { $0 }
    }
}

// MARK: - StubPredictionEngine (testing)

public final class StubPredictionEngine: PredictionEngineProtocol, @unchecked Sendable {
    public var stubbedCandidates: [String] = []
    public init() {}
    public func candidates(for contextBefore: String) async -> [String] { stubbedCandidates }
}
