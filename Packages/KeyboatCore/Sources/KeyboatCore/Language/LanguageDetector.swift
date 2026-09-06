// LanguageDetector.swift — Keyboat
// NaturalLanguage-backed language detection and tokenization.
// Stateless struct — creates NL objects per-call to be Sendable-clean.

import Foundation
@preconcurrency import NaturalLanguage

// MARK: - LanguageDetectorProtocol

public protocol LanguageDetectorProtocol: Sendable {
    func detect(in text: String) -> String?           // BCP-47 tag or nil
    func tokenize(_ text: String) -> [String]
    func currentWord(in text: String) -> String
}

// MARK: - LanguageDetector

public struct LanguageDetector: LanguageDetectorProtocol, Sendable {

    public init() {}

    public func detect(in text: String) -> String? {
        guard text.count >= 5 else { return nil }
        let r = NLLanguageRecognizer()
        r.processString(text)
        return r.dominantLanguage?.rawValue
    }

    public func tokenize(_ text: String) -> [String] {
        let t = NLTokenizer(unit: .word)
        t.string = text
        var tokens: [String] = []
        t.enumerateTokens(in: text.startIndex..<text.endIndex) { range, _ in
            tokens.append(String(text[range]))
            return true
        }
        return tokens
    }

    public func currentWord(in text: String) -> String {
        String(text.reversed().prefix(while: { !$0.isWhitespace && !$0.isNewline }).reversed())
    }
}
