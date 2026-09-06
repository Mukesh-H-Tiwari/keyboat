// ThemeEngine.swift — Keyboat
// Manages active theme, built-in presets, and user custom themes.
// Observable so SwiftUI views react to theme changes without restart.

import Foundation
import Combine

// MARK: - ThemeEngineProtocol

@MainActor
public protocol ThemeEngineProtocol: AnyObject {
    var activeTheme: Theme { get }
    var allThemes: [Theme] { get }
    func activate(themeID: String)
    func save(theme: Theme)
    func delete(themeID: String)
}

// MARK: - ThemeEngine

@MainActor
public final class ThemeEngine: ObservableObject, ThemeEngineProtocol {

    public static let shared = ThemeEngine()

    @Published public private(set) var activeTheme: Theme
    @Published public private(set) var allThemes: [Theme]

    private let prefs: PreferencesStore
    private let customThemesKey = "kbt.customThemes"

    private init(prefs: PreferencesStore? = nil) {
        let store = prefs ?? PreferencesStore.shared
        self.prefs = store
        let builtIns = ThemeEngine.builtInThemes()
        let customs  = ThemeEngine.loadCustomThemes()
        let all      = builtIns + customs
        self.allThemes   = all
        let saved    = store.themeID
        self.activeTheme = all.first(where: { $0.id == saved }) ?? builtIns[0]
    }

    // MARK: - Activation

    public func activate(themeID: String) {
        guard let theme = allThemes.first(where: { $0.id == themeID }) else { return }
        activeTheme = theme
        prefs.themeID = themeID
    }

    // MARK: - User theme persistence

    public func save(theme: Theme) {
        if let idx = allThemes.firstIndex(where: { $0.id == theme.id }) {
            allThemes[idx] = theme
        } else {
            allThemes.append(theme)
        }
        persistCustomThemes()
        if activeTheme.id == theme.id { activeTheme = theme }
    }

    public func delete(themeID: String) {
        allThemes.removeAll { $0.id == themeID && !$0.isBuiltIn }
        persistCustomThemes()
        if activeTheme.id == themeID, let first = allThemes.first {
            activate(themeID: first.id)
        }
    }

    // MARK: - Private

    private func persistCustomThemes() {
        let customs = allThemes.filter { !$0.isBuiltIn }
        if let data = try? JSONEncoder().encode(customs) {
            AppGroup.defaults.set(data, forKey: customThemesKey)
        }
    }

    private static func loadCustomThemes() -> [Theme] {
        guard let data = AppGroup.defaults.data(forKey: "kbt.customThemes"),
              let themes = try? JSONDecoder().decode([Theme].self, from: data)
        else { return [] }
        return themes
    }

    // MARK: - Built-in themes

    public nonisolated static func builtInThemes() -> [Theme] {
        [midnightTheme(), auroraTheme(), oceanTheme(), emberTheme()]
    }

    // MARK: Midnight (deep black OLED — default)
    private nonisolated static func midnightTheme() -> Theme {
        Theme(
            id: "dark", name: "Midnight", isBuiltIn: true,
            keyboardBackground:    .hex("#0A0A0F"),
            numberRowBackground:   .hex("#060608"),
            keyBackground:         .hex("#1E1E2E"),
            keyForeground:         .hex("#E2E2FF"),
            keyShadow:             ColorToken(r: 0, g: 0, b: 0, a: 0.9),
            keyCornerRadius:       11,
            specialKeyBackground:  .hex("#12121C"),
            specialKeyForeground:  .hex("#9898C8"),
            spaceKeyBackground:    .hex("#1E1E2E"),
            spaceKeyForeground:    .hex("#5555AA"),
            suggestionBarBackground: .hex("#08080D"),
            suggestionTextColor:   .hex("#E2E2FF"),
            suggestionDividerColor: .hex("#2A2A3E"),
            clipboardBackground:   .hex("#0A0A0F"),
            clipboardItemBackground: .hex("#1E1E2E"),
            clipboardItemText:     .hex("#E2E2FF"),
            clipboardPinnedBadge:  .hex("#7C6FCD"),
            accentColor:           .hex("#7C6FCD"),
            keyFont:               .init(size: 17, weight: .regular),
            specialKeyFont:        .init(size: 13, weight: .medium),
            keySpacing:            6, keyHeight: 44, shadowOpacity: 0.9
        )
    }

    // MARK: Aurora (purple ↔ cyan glow — flagship)
    private nonisolated static func auroraTheme() -> Theme {
        Theme(
            id: "aurora", name: "Aurora", isBuiltIn: true,
            keyboardBackground:    .hex("#0D0D1A"),
            numberRowBackground:   .hex("#080812"),
            keyBackground:         .hex("#1A1A35"),
            keyForeground:         .hex("#D0D8FF"),
            keyShadow:             ColorToken(r: 0.1, g: 0, b: 0.3, a: 0.8),
            keyCornerRadius:       12,
            specialKeyBackground:  .hex("#0F0F28"),
            specialKeyForeground:  .hex("#8888FF"),
            spaceKeyBackground:    .hex("#1A1A35"),
            spaceKeyForeground:    .hex("#6666CC"),
            suggestionBarBackground: .hex("#0A0A14"),
            suggestionTextColor:   .hex("#D0D8FF"),
            suggestionDividerColor: .hex("#222244"),
            clipboardBackground:   .hex("#0D0D1A"),
            clipboardItemBackground: .hex("#1A1A35"),
            clipboardItemText:     .hex("#D0D8FF"),
            clipboardPinnedBadge:  .hex("#00E5FF"),
            accentColor:           .hex("#00E5FF"),
            keyFont:               .init(size: 17, weight: .regular),
            specialKeyFont:        .init(size: 13, weight: .medium),
            keySpacing:            6, keyHeight: 44, shadowOpacity: 0.8
        )
    }

    // MARK: Ocean (deep teal)
    private nonisolated static func oceanTheme() -> Theme {
        Theme(
            id: "ocean", name: "Ocean", isBuiltIn: true,
            keyboardBackground:    .hex("#071520"),
            numberRowBackground:   .hex("#040E17"),
            keyBackground:         .hex("#0E3050"),
            keyForeground:         .hex("#C8E8F8"),
            keyShadow:             ColorToken(r: 0, g: 0.1, b: 0.25, a: 0.9),
            keyCornerRadius:       12,
            specialKeyBackground:  .hex("#071E35"),
            specialKeyForeground:  .hex("#60C0E0"),
            spaceKeyBackground:    .hex("#0E3050"),
            spaceKeyForeground:    .hex("#4090C0"),
            suggestionBarBackground: .hex("#050F18"),
            suggestionTextColor:   .hex("#C8E8F8"),
            suggestionDividerColor: .hex("#0E2A40"),
            clipboardBackground:   .hex("#071520"),
            clipboardItemBackground: .hex("#0E3050"),
            clipboardItemText:     .hex("#C8E8F8"),
            clipboardPinnedBadge:  .hex("#00D4FF"),
            accentColor:           .hex("#00D4FF"),
            keyFont:               .init(size: 17, weight: .regular),
            specialKeyFont:        .init(size: 13, weight: .medium),
            keySpacing:            7, keyHeight: 44, shadowOpacity: 0.8
        )
    }

    // MARK: Ember (warm orange/red — bold)
    private nonisolated static func emberTheme() -> Theme {
        Theme(
            id: "ember", name: "Ember", isBuiltIn: true,
            keyboardBackground:    .hex("#130800"),
            numberRowBackground:   .hex("#0C0500"),
            keyBackground:         .hex("#2A1200"),
            keyForeground:         .hex("#FFE0B0"),
            keyShadow:             ColorToken(r: 0.2, g: 0.05, b: 0, a: 0.9),
            keyCornerRadius:       11,
            specialKeyBackground:  .hex("#1A0C00"),
            specialKeyForeground:  .hex("#FF8040"),
            spaceKeyBackground:    .hex("#2A1200"),
            spaceKeyForeground:    .hex("#CC5500"),
            suggestionBarBackground: .hex("#0E0600"),
            suggestionTextColor:   .hex("#FFE0B0"),
            suggestionDividerColor: .hex("#2A1800"),
            clipboardBackground:   .hex("#130800"),
            clipboardItemBackground: .hex("#2A1200"),
            clipboardItemText:     .hex("#FFE0B0"),
            clipboardPinnedBadge:  .hex("#FF6B00"),
            accentColor:           .hex("#FF6B00"),
            keyFont:               .init(size: 17, weight: .regular),
            specialKeyFont:        .init(size: 13, weight: .medium),
            keySpacing:            6, keyHeight: 44, shadowOpacity: 0.9
        )
    }
}
