// ThemeEngineTests.swift — Keyboat

import Testing
import Foundation
@testable import KeyboatCore

@Suite("ThemeEngine")
@MainActor
struct ThemeEngineTests {

    // MARK: - Built-in themes

    @Test("Four built-in themes are available")
    func fourBuiltInThemes() {
        let themes = ThemeEngine.builtInThemes()
        #expect(themes.count == 4)
    }

    @Test("Built-in theme IDs are unique")
    func builtInThemeIDsUnique() {
        let themes = ThemeEngine.builtInThemes()
        let ids = Set(themes.map(\.id))
        #expect(ids.count == themes.count)
    }

    @Test("Dark theme exists and has correct ID")
    func darkThemeExists() {
        let themes = ThemeEngine.builtInThemes()
        #expect(themes.contains(where: { $0.id == "dark" }))
    }

    @Test("All built-in themes are marked isBuiltIn")
    func builtInThemesMarked() {
        let themes = ThemeEngine.builtInThemes()
        let allBuiltIn = themes.allSatisfy { $0.isBuiltIn }
        #expect(allBuiltIn)
    }

    // MARK: - Codable

    @Test("Theme encodes and decodes correctly")
    func themeRoundTrip() throws {
        let themes = ThemeEngine.builtInThemes()
        guard let dark = themes.first(where: { $0.id == "dark" }) else {
            Issue.record("Dark theme not found"); return
        }
        let data = try JSONEncoder().encode(dark)
        let decoded = try JSONDecoder().decode(Theme.self, from: data)
        #expect(decoded.id == dark.id)
        #expect(decoded.name == dark.name)
        #expect(decoded.keyCornerRadius == dark.keyCornerRadius)
    }

    // MARK: - ColorToken

    @Test("ColorToken hex parsing parses white correctly")
    func colorTokenWhite() {
        let c = ColorToken.hex("#FFFFFF")
        #expect(abs(c.r - 1.0) < 0.001)
        #expect(abs(c.g - 1.0) < 0.001)
        #expect(abs(c.b - 1.0) < 0.001)
    }

    @Test("ColorToken hex parsing parses black correctly")
    func colorTokenBlack() {
        let c = ColorToken.hex("#000000")
        #expect(abs(c.r) < 0.001)
        #expect(abs(c.g) < 0.001)
        #expect(abs(c.b) < 0.001)
    }

    @Test("ColorToken encodes and decodes correctly")
    func colorTokenRoundTrip() throws {
        let original = ColorToken(r: 0.2, g: 0.5, b: 0.8, a: 0.9)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ColorToken.self, from: data)
        #expect(abs(decoded.r - original.r) < 0.001)
        #expect(abs(decoded.a - original.a) < 0.001)
    }
}
