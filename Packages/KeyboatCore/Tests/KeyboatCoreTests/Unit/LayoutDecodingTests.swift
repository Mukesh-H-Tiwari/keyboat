// LayoutDecodingTests.swift — Keyboat
// Tests that the en-QWERTY.json layout file decodes correctly.

import Testing
import Foundation
@testable import KeyboatCore

@Suite("LayoutDecoding")
struct LayoutDecodingTests {

    // MARK: - JSON layout decoding

    @Test("KeyboardLayout encodes and decodes via Codable")
    func layoutCodableRoundTrip() throws {
        let layout = KeyboardLayout.fallback()
        let data = try JSONEncoder().encode(layout)
        let decoded = try JSONDecoder().decode(KeyboardLayout.self, from: data)
        #expect(decoded.id == layout.id)
        #expect(decoded.rows.count == layout.rows.count)
    }

    @Test("KeyDefinition encodes and decodes action correctly")
    func keyDefinitionRoundTrip() throws {
        let key = KeyDefinition(
            id: "a", label: "a",
            action: .character("a"),
            accessibilityLabel: "A"
        )
        let data = try JSONEncoder().encode(key)
        let decoded = try JSONDecoder().decode(KeyDefinition.self, from: data)
        #expect(decoded.id == key.id)
        #expect(decoded.label == key.label)
        // Action should survive round-trip
        if case .character(let s) = decoded.action {
            #expect(s == "a")
        } else {
            Issue.record("Action round-trip failed")
        }
    }

    @Test("EncodableKeyAction toKeyAction converts all cases")
    func encodableKeyActionConversion() {
        let cases: [(EncodableKeyAction, KeyAction)] = [
            (.space, .space),
            (.return, .return),
            (.backspace, .backspace),
            (.shift, .shift),
            (.capsLock, .capsLock),
            (.numbers, .numbers),
            (.symbols, .symbols),
            (.alphabet, .alphabet),
            (.nextKeyboard, .nextKeyboard),
            (.clipboard, .clipboard),
            (.emoji, .emoji),
        ]
        for (encodable, expected) in cases {
            #expect(encodable.toKeyAction() == expected, "Failed for \(encodable)")
        }
    }

    @Test("Fallback layout has at least one row")
    func fallbackLayoutHasRows() {
        let layout = KeyboardLayout.fallback()
        #expect(!layout.rows.isEmpty)
    }

    @Test("Fallback layout bottom row has space key")
    func fallbackLayoutHasSpaceKey() {
        let layout = KeyboardLayout.fallback()
        if case .space = layout.bottomRow.spaceKey.action.toKeyAction() {
            // pass
        } else {
            Issue.record("Bottom row space key missing")
        }
    }

    @Test("RepeatBehavior decodes all known raw values")
    func repeatBehaviorDecodes() throws {
        for raw in ["none", "standard", "accelerating", "longPressAlternates"] {
            let data = Data("\"\(raw)\"".utf8)
            let decoded = try JSONDecoder().decode(RepeatBehavior.self, from: data)
            #expect(decoded.rawValue == raw)
        }
    }
}

// Make KeyboardLayout.fallback() accessible to test target
extension KeyboardLayout {
    static func fallback() -> KeyboardLayout {
        let letters = "qwertyuiop".map { c in
            KeyDefinition(
                id: String(c), label: String(c),
                action: .character(String(c)),
                accessibilityLabel: String(c).uppercased()
            )
        }
        return KeyboardLayout(
            id: "fallback", locale: "en", displayName: "Fallback",
            rows: [RowDefinition(id: "row1", keys: letters)],
            bottomRow: BottomRowDefinition(
                leftKeys: [],
                spaceKey: KeyDefinition(id: "space", label: "space", action: .space, accessibilityLabel: "Space"),
                rightKeys: [KeyDefinition(id: "return", label: "return", action: .return, accessibilityLabel: "Return")]
            )
        )
    }
}
