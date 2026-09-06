// KeyboardRootView.swift — Keyboat
// Top-level SwiftUI view for the keyboard extension.
// Switches between: main keyboard, emoji panel, clipboard panel.

import SwiftUI
import KeyboatCore

// MARK: - KeyboardPage (local alias for panel routing)
private extension KeyboardPage {
    var isAlphabetic: Bool { self == .alphabetic }
}

// MARK: - KeyboardRootView

struct KeyboardRootView: View {

    // MARK: Dependencies
    @ObservedObject var inputEngine: InputEngine
    @ObservedObject var themeEngine: ThemeEngine
    @ObservedObject var prefs: PreferencesStore

    let clipboardStore: any ClipboardServiceProtocol
    let predictionEngine: any PredictionEngineProtocol
    let proxy: any TextProxyProtocol
    let onAction: (KeyAction) -> Void

    // MARK: Local state
    @State private var showClipboard = false
    @State private var showEmoji = false
    @State private var suggestions: [String] = []

    private func makeTheme(active: Theme, height: CGFloat) -> Theme {
        var t = active
        t.keyHeight = height
        return t
    }

    var body: some View {
        let activeTheme = themeEngine.activeTheme

        GeometryReader { rootGeo in
            let containerWidth = rootGeo.size.width > 0 ? rootGeo.size.width : UIScreen.main.bounds.width
            let containerHeight = rootGeo.size.height > 0 ? rootGeo.size.height : 260

            let rowCount: CGFloat = prefs.numberRowEnabled ? 5 : 4
            let topBarHeight: CGFloat = 2
            let suggestionHeight: CGFloat = suggestions.isEmpty ? 24 : 36
            let bottomPadding: CGFloat = 4
            let rowPaddings: CGFloat = (rowCount * 2) * 2

            let availableForRows = max(100, containerHeight - topBarHeight - suggestionHeight - bottomPadding - rowPaddings)
            let calculatedKeyHeight = max(32, min(54, availableForRows / rowCount))

            let theme = makeTheme(active: activeTheme, height: calculatedKeyHeight)

            VStack(spacing: 0) {
                // Distinct visual indicator bar to verify custom rendering
                Rectangle()
                    .fill(Color(token: theme.accentColor))
                    .frame(height: topBarHeight)

                // Suggestion bar
                SuggestionBarView(
                    suggestions: suggestions,
                    theme: theme,
                    onSelect: { word in
                        onAction(.replaceCurrentWord(word))
                        refreshSuggestions()
                    },
                    onOpenSettings: {
                        onAction(.openSettings)
                    }
                )

                // Keyboard body
                if showClipboard {
                    ClipboardPanelView(
                        store: clipboardStore,
                        theme: theme,
                        onPaste: { item in
                            onAction(.insertString(item.text))
                            clipboardStore.markUsed(id: item.id)
                            withAnimation(.spring(duration: 0.25)) { showClipboard = false }
                        },
                        onClose: {
                            withAnimation(.spring(duration: 0.25)) { showClipboard = false }
                        }
                    )
                } else if showEmoji {
                    EmojiPanelView(
                        theme: theme,
                        onSelectEmoji: { emoji in
                            onAction(.insertString(emoji))
                        },
                        onClose: {
                            withAnimation(.spring(duration: 0.25)) { showEmoji = false }
                        }
                    )
                } else {
                    mainKeyboard(theme: theme, containerWidth: containerWidth)
                }

                Spacer(minLength: 0)
            }
            .background(Color(token: theme.keyboardBackground))
        }
    }

    // MARK: - Main keyboard view

    @ViewBuilder
    private func mainKeyboard(theme: Theme, containerWidth: CGFloat) -> some View {
        let pad: CGFloat = 2

        VStack(spacing: 0) {
            // Number row (conditional)
            if prefs.numberRowEnabled,
               let layout = LayoutEngine.shared.currentLayout,
               let numberRow = layout.numberRow {
                KeyboardRowView(
                    row: RowDefinition(
                        id: "number-row",
                        keys: numberRow.keys,
                        edgeSpacingFactor: 0
                    ),
                    theme: theme,
                    shiftState: inputEngine.shiftState,
                    containerWidth: containerWidth,
                    onAction: routeAction
                )
                .padding(.vertical, pad)
            }

            // Letter rows
            if let layout = LayoutEngine.shared.currentLayout {
                ForEach(layout.rows) { row in
                    KeyboardRowView(
                        row: row,
                        theme: theme,
                        shiftState: inputEngine.shiftState,
                        containerWidth: containerWidth,
                        onAction: routeAction
                    )
                    .padding(.vertical, pad)
                }

                // Bottom row
                BottomRowView(
                    bottom: layout.bottomRow,
                    theme: theme,
                    shiftState: inputEngine.shiftState,
                    containerWidth: containerWidth,
                    onAction: routeAction
                )
                .padding(.vertical, pad)
            }
        }
        .padding(.bottom, 4)
    }

    // MARK: - Action routing

    private func routeAction(_ action: KeyAction) {
        switch action {
        case .clipboard:
            withAnimation(.spring(duration: 0.3)) { showClipboard.toggle() }
            return
        case .emoji:
            withAnimation(.spring(duration: 0.3)) { showEmoji.toggle() }
            return
        default:
            break
        }
        onAction(action)
        refreshSuggestions()
    }

    // MARK: - Suggestions

    @MainActor
    private func refreshSuggestions() {
        let context = proxy.documentContextBeforeInput ?? ""
        Task { @MainActor in
            let results = await predictionEngine.candidates(for: context)
            self.suggestions = results
        }
    }
}

// MARK: - LayoutEngine (simple singleton for Phase 1)

@MainActor
final class LayoutEngine: ObservableObject {

    static let shared = LayoutEngine()

    @Published private(set) var currentLayout: KeyboardLayout?

    private init() {
        loadDefault()
    }

    private func loadDefault() {
        let bundle = Bundle(for: LayoutEngine.self)
        if let url = bundle.url(forResource: "en-QWERTY", withExtension: "json") ?? Bundle.main.url(forResource: "en-QWERTY", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let layout = try? JSONDecoder().decode(KeyboardLayout.self, from: data) {
            currentLayout = layout
        } else {
            currentLayout = KeyboardLayout.fallback()
        }
    }
}

// MARK: - Fallback layout (hardcoded safety net)

extension KeyboardLayout {
    static func fallback() -> KeyboardLayout {
        let numbers = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"].map { n in
            KeyDefinition(id: "num-\(n)", label: n, action: .character(n), accessibilityLabel: n)
        }
        let row1 = "qwertyuiop".map { c in
            KeyDefinition(id: String(c), label: String(c), action: .character(String(c)), accessibilityLabel: String(c).uppercased())
        }
        let row2 = "asdfghjkl".map { c in
            KeyDefinition(id: String(c), label: String(c), action: .character(String(c)), accessibilityLabel: String(c).uppercased())
        }
        let row3Letters = "zxcvbnm".map { c in
            KeyDefinition(id: String(c), label: String(c), action: .character(String(c)), accessibilityLabel: String(c).uppercased())
        }
        let shiftKey = KeyDefinition(id: "shift", label: "⇧", action: .shift, widthFactor: 1.5, accessibilityLabel: "Shift")
        let deleteKey = KeyDefinition(id: "delete", label: "⌫", action: .backspace, widthFactor: 1.5, accessibilityLabel: "Delete")
        let row3 = [shiftKey] + row3Letters + [deleteKey]

        let numSwitch = KeyDefinition(id: "numSwitch", label: "123", action: .numbers, widthFactor: 1.3, accessibilityLabel: "Numbers")
        let settingsKey = KeyDefinition(id: "settings", label: "⚙︎", action: .openSettings, widthFactor: 1.0, accessibilityLabel: "Settings")
        let emojiKey = KeyDefinition(id: "emoji", label: "😃", action: .emoji, widthFactor: 1.0, accessibilityLabel: "Emoji")
        let spaceKey = KeyDefinition(id: "space", label: "keyboat", action: .space, widthFactor: 3.7, accessibilityLabel: "Space")
        let periodKey = KeyDefinition(id: "period", label: ".", action: .character("."), widthFactor: 1.0, accessibilityLabel: "Period")
        let returnKey = KeyDefinition(id: "return", label: "return", action: .return, widthFactor: 2.0, accessibilityLabel: "Return")

        return KeyboardLayout(
            id: "fallback", locale: "en", displayName: "English",
            rows: [
                RowDefinition(id: "row1", keys: row1),
                RowDefinition(id: "row2", keys: row2, edgeSpacingFactor: 0.5),
                RowDefinition(id: "row3", keys: row3)
            ],
            numberRow: NumberRowDefinition(keys: numbers),
            bottomRow: BottomRowDefinition(
                leftKeys: [numSwitch, settingsKey, emojiKey],
                spaceKey: spaceKey,
                rightKeys: [periodKey, returnKey]
            )
        )
    }
}

// MARK: - SwiftUI Color from ColorToken

extension Color {
    init(token: ColorToken) {
        self.init(.sRGB, red: token.r, green: token.g, blue: token.b, opacity: token.a)
    }
}
