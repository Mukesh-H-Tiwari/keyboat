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

        // Keep activeTheme synchronized whenever store.themeID changes across App Group or App UI
        store.$themeID
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newID in
                self?.activate(themeID: newID)
            }
            .store(in: &cancellables)
    }

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Activation

    public func reloadCustomThemes() {
        let builtIns = ThemeEngine.builtInThemes()
        let customs  = ThemeEngine.loadCustomThemes()
        self.allThemes = builtIns + customs
    }

    public func activate(themeID: String) {
        reloadCustomThemes()
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
        [
            // iOS System Category
            iosLightSystemTheme(),
            iosDarkSystemTheme(),
            cupertinoBlueTheme(),
            
            // Dark & OLED Category
            midnightTheme(),
            spaceGrayTheme(),
            cyberpunkOledTheme(),
            
            // Minimal & Pastel Category
            softChalkTheme(),
            roseGoldTheme(),
            pastelMintTheme(),
            lavenderBlissTheme(),
            
            // Vibrant & Neon Category
            auroraTheme(),
            oceanTheme(),
            emberTheme(),
            neonVaporTheme()
        ]
    }

    // MARK: - iOS System Themes

    private nonisolated static func iosLightSystemTheme() -> Theme {
        Theme(
            id: "ios_light", name: "iOS Light", category: .iosSystem, isBuiltIn: true,
            keyboardBackground:    .hex("#CBD0D8"),
            numberRowBackground:   .hex("#BFC4CD"),
            keyBackground:         .hex("#FFFFFF"),
            keyForeground:         .hex("#000000"),
            keyShadow:             ColorToken(r: 0, g: 0, b: 0, a: 0.35),
            keyCornerRadius:       9,
            specialKeyBackground:  .hex("#ACB3BD"),
            specialKeyForeground:  .hex("#000000"),
            spaceKeyBackground:    .hex("#FFFFFF"),
            spaceKeyForeground:    .hex("#333333"),
            suggestionBarBackground: .hex("#C3C8D0"),
            suggestionTextColor:   .hex("#000000"),
            suggestionDividerColor: .hex("#B2B7C0"),
            clipboardBackground:   .hex("#CBD0D8"),
            clipboardItemBackground: .hex("#FFFFFF"),
            clipboardItemText:     .hex("#000000"),
            clipboardPinnedBadge:  .hex("#007AFF"),
            accentColor:           .hex("#007AFF"),
            keyFont:               .init(size: 17, weight: .regular),
            specialKeyFont:        .init(size: 13, weight: .medium),
            keySpacing:            6, keyHeight: 44, shadowOpacity: 0.35
        )
    }

    private nonisolated static func iosDarkSystemTheme() -> Theme {
        Theme(
            id: "ios_dark", name: "iOS Dark", category: .iosSystem, isBuiltIn: true,
            keyboardBackground:    .hex("#2B2B2C"),
            numberRowBackground:   .hex("#202021"),
            keyBackground:         .hex("#636366"),
            keyForeground:         .hex("#FFFFFF"),
            keyShadow:             ColorToken(r: 0, g: 0, b: 0, a: 0.6),
            keyCornerRadius:       9,
            specialKeyBackground:  .hex("#444446"),
            specialKeyForeground:  .hex("#FFFFFF"),
            spaceKeyBackground:    .hex("#636366"),
            spaceKeyForeground:    .hex("#E5E5EA"),
            suggestionBarBackground: .hex("#242425"),
            suggestionTextColor:   .hex("#FFFFFF"),
            suggestionDividerColor: .hex("#3A3A3C"),
            clipboardBackground:   .hex("#2B2B2C"),
            clipboardItemBackground: .hex("#636366"),
            clipboardItemText:     .hex("#FFFFFF"),
            clipboardPinnedBadge:  .hex("#0A84FF"),
            accentColor:           .hex("#0A84FF"),
            keyFont:               .init(size: 17, weight: .regular),
            specialKeyFont:        .init(size: 13, weight: .medium),
            keySpacing:            6, keyHeight: 44, shadowOpacity: 0.6
        )
    }

    private nonisolated static func cupertinoBlueTheme() -> Theme {
        Theme(
            id: "cupertino_blue", name: "Cupertino Blue", category: .iosSystem, isBuiltIn: true,
            keyboardBackground:    .hex("#E6F0FA"),
            numberRowBackground:   .hex("#D5E4F5"),
            keyBackground:         .hex("#FFFFFF"),
            keyForeground:         .hex("#0A2540"),
            keyShadow:             ColorToken(r: 0, g: 0.2, b: 0.5, a: 0.15),
            keyCornerRadius:       10,
            specialKeyBackground:  .hex("#CBE0F5"),
            specialKeyForeground:  .hex("#0066CC"),
            spaceKeyBackground:    .hex("#FFFFFF"),
            spaceKeyForeground:    .hex("#0066CC"),
            suggestionBarBackground: .hex("#DCEDFC"),
            suggestionTextColor:   .hex("#0A2540"),
            suggestionDividerColor: .hex("#BDD8F2"),
            clipboardBackground:   .hex("#E6F0FA"),
            clipboardItemBackground: .hex("#FFFFFF"),
            clipboardItemText:     .hex("#0A2540"),
            clipboardPinnedBadge:  .hex("#0066CC"),
            accentColor:           .hex("#0066CC"),
            keyFont:               .init(size: 17, weight: .regular),
            specialKeyFont:        .init(size: 13, weight: .semibold),
            keySpacing:            6, keyHeight: 44, shadowOpacity: 0.2
        )
    }

    // MARK: - Dark & OLED Themes

    private nonisolated static func midnightTheme() -> Theme {
        Theme(
            id: "dark", name: "Midnight", category: .oledDark, isBuiltIn: true,
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

    private nonisolated static func spaceGrayTheme() -> Theme {
        Theme(
            id: "space_gray", name: "Space Gray", category: .oledDark, isBuiltIn: true,
            keyboardBackground:    .hex("#1A1A1A"),
            numberRowBackground:   .hex("#121212"),
            keyBackground:         .hex("#2C2C2E"),
            keyForeground:         .hex("#F2F2F7"),
            keyShadow:             ColorToken(r: 0, g: 0, b: 0, a: 0.8),
            keyCornerRadius:       10,
            specialKeyBackground:  .hex("#202022"),
            specialKeyForeground:  .hex("#8E8E93"),
            spaceKeyBackground:    .hex("#2C2C2E"),
            spaceKeyForeground:    .hex("#AEAEB2"),
            suggestionBarBackground: .hex("#151516"),
            suggestionTextColor:   .hex("#F2F2F7"),
            suggestionDividerColor: .hex("#3A3A3C"),
            clipboardBackground:   .hex("#1A1A1A"),
            clipboardItemBackground: .hex("#2C2C2E"),
            clipboardItemText:     .hex("#F2F2F7"),
            clipboardPinnedBadge:  .hex("#64D2FF"),
            accentColor:           .hex("#64D2FF"),
            keyFont:               .init(size: 17, weight: .regular),
            specialKeyFont:        .init(size: 13, weight: .medium),
            keySpacing:            6, keyHeight: 44, shadowOpacity: 0.8
        )
    }

    private nonisolated static func cyberpunkOledTheme() -> Theme {
        Theme(
            id: "cyberpunk_oled", name: "OLED Cyber", category: .oledDark, isBuiltIn: true,
            keyboardBackground:    .hex("#000000"),
            numberRowBackground:   .hex("#050505"),
            keyBackground:         .hex("#111115"),
            keyForeground:         .hex("#00FFCC"),
            keyShadow:             ColorToken(r: 0, g: 0.8, b: 0.7, a: 0.3),
            keyCornerRadius:       12,
            specialKeyBackground:  .hex("#0A0A10"),
            specialKeyForeground:  .hex("#FF0055"),
            spaceKeyBackground:    .hex("#111115"),
            spaceKeyForeground:    .hex("#00FFCC"),
            suggestionBarBackground: .hex("#050508"),
            suggestionTextColor:   .hex("#00FFCC"),
            suggestionDividerColor: .hex("#222233"),
            clipboardBackground:   .hex("#000000"),
            clipboardItemBackground: .hex("#111115"),
            clipboardItemText:     .hex("#00FFCC"),
            clipboardPinnedBadge:  .hex("#FF0055"),
            accentColor:           .hex("#FF0055"),
            keyFont:               .init(size: 17, weight: .semibold),
            specialKeyFont:        .init(size: 13, weight: .bold),
            keySpacing:            6, keyHeight: 44, shadowOpacity: 0.5
        )
    }

    // MARK: - Minimal & Pastel Themes

    private nonisolated static func softChalkTheme() -> Theme {
        Theme(
            id: "soft_chalk", name: "Soft Chalk", category: .minimalPastel, isBuiltIn: true,
            keyboardBackground:    .hex("#F4F4F6"),
            numberRowBackground:   .hex("#EAEAED"),
            keyBackground:         .hex("#FFFFFF"),
            keyForeground:         .hex("#3A3A3C"),
            keyShadow:             ColorToken(r: 0, g: 0, b: 0, a: 0.08),
            keyCornerRadius:       14,
            specialKeyBackground:  .hex("#E5E5EA"),
            specialKeyForeground:  .hex("#6C6C70"),
            spaceKeyBackground:    .hex("#FFFFFF"),
            spaceKeyForeground:    .hex("#8E8E93"),
            suggestionBarBackground: .hex("#EFEFF1"),
            suggestionTextColor:   .hex("#3A3A3C"),
            suggestionDividerColor: .hex("#D1D1D6"),
            clipboardBackground:   .hex("#F4F4F6"),
            clipboardItemBackground: .hex("#FFFFFF"),
            clipboardItemText:     .hex("#3A3A3C"),
            clipboardPinnedBadge:  .hex("#8E8E93"),
            accentColor:           .hex("#8E8E93"),
            keyFont:               .init(size: 17, weight: .regular),
            specialKeyFont:        .init(size: 13, weight: .medium),
            keySpacing:            7, keyHeight: 44, shadowOpacity: 0.1
        )
    }

    private nonisolated static func roseGoldTheme() -> Theme {
        Theme(
            id: "rose_gold", name: "Rose Gold", category: .minimalPastel, isBuiltIn: true,
            keyboardBackground:    .hex("#FAF0EE"),
            numberRowBackground:   .hex("#F4E4E1"),
            keyBackground:         .hex("#FFFFFF"),
            keyForeground:         .hex("#5C3A38"),
            keyShadow:             ColorToken(r: 0.5, g: 0.2, b: 0.2, a: 0.1),
            keyCornerRadius:       12,
            specialKeyBackground:  .hex("#F2DDD9"),
            specialKeyForeground:  .hex("#B86B66"),
            spaceKeyBackground:    .hex("#FFFFFF"),
            spaceKeyForeground:    .hex("#B86B66"),
            suggestionBarBackground: .hex("#F7E8E5"),
            suggestionTextColor:   .hex("#5C3A38"),
            suggestionDividerColor: .hex("#E8CFC9"),
            clipboardBackground:   .hex("#FAF0EE"),
            clipboardItemBackground: .hex("#FFFFFF"),
            clipboardItemText:     .hex("#5C3A38"),
            clipboardPinnedBadge:  .hex("#D9827B"),
            accentColor:           .hex("#D9827B"),
            keyFont:               .init(size: 17, weight: .regular),
            specialKeyFont:        .init(size: 13, weight: .medium),
            keySpacing:            6, keyHeight: 44, shadowOpacity: 0.15
        )
    }

    private nonisolated static func pastelMintTheme() -> Theme {
        Theme(
            id: "pastel_mint", name: "Pastel Mint", category: .minimalPastel, isBuiltIn: true,
            keyboardBackground:    .hex("#EDF7F5"),
            numberRowBackground:   .hex("#DEEFEA"),
            keyBackground:         .hex("#FFFFFF"),
            keyForeground:         .hex("#265249"),
            keyShadow:             ColorToken(r: 0.1, g: 0.3, b: 0.2, a: 0.08),
            keyCornerRadius:       12,
            specialKeyBackground:  .hex("#D3E9E3"),
            specialKeyForeground:  .hex("#3B8073"),
            spaceKeyBackground:    .hex("#FFFFFF"),
            spaceKeyForeground:    .hex("#3B8073"),
            suggestionBarBackground: .hex("#E4F3EF"),
            suggestionTextColor:   .hex("#265249"),
            suggestionDividerColor: .hex("#C3E2D9"),
            clipboardBackground:   .hex("#EDF7F5"),
            clipboardItemBackground: .hex("#FFFFFF"),
            clipboardItemText:     .hex("#265249"),
            clipboardPinnedBadge:  .hex("#3B8073"),
            accentColor:           .hex("#3B8073"),
            keyFont:               .init(size: 17, weight: .regular),
            specialKeyFont:        .init(size: 13, weight: .medium),
            keySpacing:            6, keyHeight: 44, shadowOpacity: 0.12
        )
    }

    private nonisolated static func lavenderBlissTheme() -> Theme {
        Theme(
            id: "lavender_bliss", name: "Lavender Bliss", category: .minimalPastel, isBuiltIn: true,
            keyboardBackground:    .hex("#F3F0FA"),
            numberRowBackground:   .hex("#E7E2F3"),
            keyBackground:         .hex("#FFFFFF"),
            keyForeground:         .hex("#3C315B"),
            keyShadow:             ColorToken(r: 0.2, g: 0.1, b: 0.4, a: 0.1),
            keyCornerRadius:       12,
            specialKeyBackground:  .hex("#DFD7EE"),
            specialKeyForeground:  .hex("#7B61B8"),
            spaceKeyBackground:    .hex("#FFFFFF"),
            spaceKeyForeground:    .hex("#7B61B8"),
            suggestionBarBackground: .hex("#ECE6F6"),
            suggestionTextColor:   .hex("#3C315B"),
            suggestionDividerColor: .hex("#D2C7E5"),
            clipboardBackground:   .hex("#F3F0FA"),
            clipboardItemBackground: .hex("#FFFFFF"),
            clipboardItemText:     .hex("#3C315B"),
            clipboardPinnedBadge:  .hex("#8C6ECF"),
            accentColor:           .hex("#8C6ECF"),
            keyFont:               .init(size: 17, weight: .regular),
            specialKeyFont:        .init(size: 13, weight: .medium),
            keySpacing:            6, keyHeight: 44, shadowOpacity: 0.15
        )
    }

    // MARK: - Vibrant & Neon Themes

    private nonisolated static func auroraTheme() -> Theme {
        Theme(
            id: "aurora", name: "Aurora Neon", category: .vibrantNeon, isBuiltIn: true,
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

    private nonisolated static func oceanTheme() -> Theme {
        Theme(
            id: "ocean", name: "Ocean Deep", category: .vibrantNeon, isBuiltIn: true,
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

    private nonisolated static func emberTheme() -> Theme {
        Theme(
            id: "ember", name: "Ember Glow", category: .vibrantNeon, isBuiltIn: true,
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

    private nonisolated static func neonVaporTheme() -> Theme {
        Theme(
            id: "neon_vapor", name: "Synthwave Vapor", category: .vibrantNeon, isBuiltIn: true,
            keyboardBackground:    .hex("#18002E"),
            numberRowBackground:   .hex("#100020"),
            keyBackground:         .hex("#2C0052"),
            keyForeground:         .hex("#FF77FF"),
            keyShadow:             ColorToken(r: 0.4, g: 0, b: 0.4, a: 0.6),
            keyCornerRadius:       10,
            specialKeyBackground:  .hex("#1E0038"),
            specialKeyForeground:  .hex("#00FFFF"),
            spaceKeyBackground:    .hex("#2C0052"),
            spaceKeyForeground:    .hex("#00FFFF"),
            suggestionBarBackground: .hex("#140026"),
            suggestionTextColor:   .hex("#FF77FF"),
            suggestionDividerColor: .hex("#3B006B"),
            clipboardBackground:   .hex("#18002E"),
            clipboardItemBackground: .hex("#2C0052"),
            clipboardItemText:     .hex("#FF77FF"),
            clipboardPinnedBadge:  .hex("#FF007F"),
            accentColor:           .hex("#FF007F"),
            keyFont:               .init(size: 17, weight: .medium),
            specialKeyFont:        .init(size: 13, weight: .bold),
            keySpacing:            6, keyHeight: 44, shadowOpacity: 0.7
        )
    }
}
