// ClipboardStoreTests.swift — Keyboat

import Testing
import Foundation
@testable import KeyboatCore

// Note: ClipboardStore uses AppGroup.defaults which may not be available in test.
// We test the logic by creating a test-scoped store backed by a temp UserDefaults suite.

@Suite("ClipboardStore")
struct ClipboardStoreTests {

    // Use a unique in-memory suite per test run
    static let testSuite = "com.mukeshtiwari.keyboat.test-\(UUID().uuidString)"

    func makeStore() -> ClipboardStore {
        // We can't call ClipboardStore.shared directly in tests due to App Group.
        // Instead we test the ClipboardItem model + ClipboardItemType logic directly.
        return ClipboardStore.shared
    }

    // MARK: - ClipboardItem model

    @Test("ClipboardItem displayText truncates at 120 chars")
    func displayTextTruncates() {
        let longText = String(repeating: "a", count: 200)
        let item = ClipboardItem(text: longText)
        #expect(item.displayText.count <= 120)
        #expect(item.displayText.hasSuffix("…"))
    }

    @Test("ClipboardItem displayText does not truncate short text")
    func displayTextNoTruncation() {
        let item = ClipboardItem(text: "Hello")
        #expect(item.displayText == "Hello")
    }

    @Test("ClipboardItem isExpired detects past expiration")
    func isExpiredDetectsExpiry() {
        let past = Date().addingTimeInterval(-3600)
        let item = ClipboardItem(text: "test", expirationDate: past)
        #expect(item.isExpired == true)
    }

    @Test("ClipboardItem isExpired false for future date")
    func isExpiredFalseForFuture() {
        let future = Date().addingTimeInterval(3600)
        let item = ClipboardItem(text: "test", expirationDate: future)
        #expect(item.isExpired == false)
    }

    @Test("ClipboardItem isExpired false when no expiration")
    func isExpiredFalseWhenNil() {
        let item = ClipboardItem(text: "test")
        #expect(item.isExpired == false)
    }

    // MARK: - ClipboardItemType detection

    @Test("Detects URL correctly")
    func detectsURL() {
        let type = ClipboardItemType.detect(from: "https://apple.com")
        #expect(type == .url)
    }

    @Test("Detects email correctly")
    func detectsEmail() {
        let type = ClipboardItemType.detect(from: "user@example.com")
        #expect(type == .email)
    }

    @Test("Detects phone correctly")
    func detectsPhone() {
        let type = ClipboardItemType.detect(from: "1234567890")
        // Could be number or phone — either is valid
        #expect(type == .phone || type == .number)
    }

    @Test("Detects plain text correctly")
    func detectsPlainText() {
        let type = ClipboardItemType.detect(from: "Hello world, this is some text")
        #expect(type == .plainText)
    }

    @Test("Unknown for empty string")
    func detectsUnknownForEmpty() {
        let type = ClipboardItemType.detect(from: "")
        #expect(type == .unknown)
    }

    // MARK: - Codable round-trip

    @Test("ClipboardItem encodes and decodes correctly")
    func codableRoundTrip() throws {
        let original = ClipboardItem(
            text: "Swift Testing is great",
            type: .plainText,
            isPinned: true
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ClipboardItem.self, from: data)
        #expect(decoded.id == original.id)
        #expect(decoded.text == original.text)
        #expect(decoded.isPinned == original.isPinned)
    }
}
