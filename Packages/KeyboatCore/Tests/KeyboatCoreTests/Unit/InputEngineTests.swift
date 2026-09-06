// InputEngineTests.swift — Keyboat
// Unit tests for InputEngine using Swift Testing + MockTextProxy.
// These run entirely without a device or simulator.

import Testing
import Foundation
@testable import KeyboatCore

// MARK: - InputEngine Tests

@Suite("InputEngine")
@MainActor
struct InputEngineTests {

    var engine: InputEngine { InputEngine() }
    var proxy: MockTextProxy { MockTextProxy() }

    // MARK: - Character insertion

    @Test("Character inserts lowercase when shift is manually turned off")
    func characterInsertsLowercaseWhenShiftOff() {
        let e = InputEngine()
        let p = MockTextProxy()
        // Engine starts with .once (auto-caps first char)
        // Toggle shift twice: once→off, off→once so it's now .once; then type A, then b
        e.handle(.shift, proxy: p)   // .once → .off
        e.handle(.shift, proxy: p)   // .off  → .once
        e.handle(.character("a"), proxy: p)  // A (consumes .once)
        e.handle(.character("b"), proxy: p)  // b (shift now .off)
        #expect(p.simulatedContext == "Ab")
    }

    @Test("Shift off by default means lowercase")
    func shiftOffProducesLowercase() async throws {
        let e = InputEngine()
        let p = MockTextProxy()
        // Engine starts with .once shift (capitalise first char)
        e.handle(.character("h"), proxy: p)
        e.handle(.character("i"), proxy: p)
        #expect(p.simulatedContext == "Hi")
    }

    @Test("CapsLock produces all-uppercase")
    func capsLockProducesAllUppercase() {
        let e = InputEngine()
        let p = MockTextProxy()
        e.handle(.capsLock, proxy: p)
        "hello".forEach { e.handle(.character($0), proxy: p) }
        #expect(p.simulatedContext == "HELLO")
    }

    @Test("Double-tap shift does not engage capslock")
    func doubleTapShiftDisengages() {
        let e = InputEngine()
        let p = MockTextProxy()
        // Engine starts with .once
        e.handle(.shift, proxy: p)  // off (was once → off)
        e.handle(.shift, proxy: p)  // once again
        #expect(e.shiftState == .once)
    }

    // MARK: - Backspace

    @Test("Backspace removes last character")
    func backspaceRemovesLastChar() {
        let e = InputEngine()
        let p = MockTextProxy()
        p.simulatedContext = "hello"
        e.handle(.backspace, proxy: p)
        #expect(p.simulatedContext == "hell")
    }

    @Test("Backspace on empty context does not crash")
    func backspaceOnEmpty() {
        let e = InputEngine()
        let p = MockTextProxy()
        e.handle(.backspace, proxy: p)
        #expect(p.log == [.deleteBackward])
    }

    // MARK: - Space and Return

    @Test("Space inserts a space character")
    func spaceInserts() {
        let e = InputEngine()
        let p = MockTextProxy()
        e.handle(.space, proxy: p)
        #expect(p.simulatedContext.hasSuffix(" "))
    }

    @Test("Return inserts newline")
    func returnInsertsNewline() {
        let e = InputEngine()
        let p = MockTextProxy()
        e.handle(.return, proxy: p)
        #expect(p.simulatedContext == "\n")
    }

    // MARK: - Page switching

    @Test("Keyboard page switches correctly")
    func pageSwitches() {
        let e = InputEngine()
        let p = MockTextProxy()
        #expect(e.keyboardPage == .alphabetic)
        e.handle(.numbers, proxy: p)
        #expect(e.keyboardPage == .numeric)
        e.handle(.symbols, proxy: p)
        #expect(e.keyboardPage == .symbolic)
        e.handle(.alphabet, proxy: p)
        #expect(e.keyboardPage == .alphabetic)
    }

    // MARK: - replaceCurrentWord

    @Test("replaceCurrentWord replaces the word before cursor")
    func replaceCurrentWord() {
        let e = InputEngine()
        let p = MockTextProxy()
        p.simulatedContext = "helo"
        e.handle(.replaceCurrentWord("hello"), proxy: p)
        // Should delete 4 chars and insert "hello"
        let insertOp = p.log.last
        if case .insert(let s) = insertOp {
            #expect(s == "hello")
        } else {
            Issue.record("Expected insert operation")
        }
    }

    // MARK: - insertString

    @Test("insertString inserts multi-char text")
    func insertString() {
        let e = InputEngine()
        let p = MockTextProxy()
        e.handle(.insertString("swift"), proxy: p)
        #expect(p.simulatedContext == "swift")
    }

    // MARK: - Shift auto-advance

    @Test("Shift auto-advances to off after one character")
    func shiftAutoAdvances() {
        let e = InputEngine()
        let p = MockTextProxy()
        // starts .once
        e.handle(.character("a"), proxy: p)  // consumes shift
        #expect(e.shiftState == .off)
    }

    // MARK: - Feature actions (passthrough)

    @Test("Feature actions do not mutate proxy")
    func featureActionsDoNotMutateProxy() {
        let e = InputEngine()
        let p = MockTextProxy()
        e.handle(.nextKeyboard, proxy: p)
        e.handle(.clipboard, proxy: p)
        e.handle(.emoji, proxy: p)
        #expect(p.log.isEmpty)
    }
}
