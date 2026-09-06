// SuggestionBarView.swift — Keyboat
// Horizontal bar of autocomplete candidates above the keyboard.
// Premium design: Keyboat logo branding + settings access.

import SwiftUI
import KeyboatCore

struct SuggestionBarView: View {

    let suggestions: [String]
    let theme: Theme
    let onSelect: (String) -> Void
    let onOpenSettings: (() -> Void)?

    init(suggestions: [String], theme: Theme, onSelect: @escaping (String) -> Void, onOpenSettings: (() -> Void)? = nil) {
        self.suggestions = suggestions
        self.theme = theme
        self.onSelect = onSelect
        self.onOpenSettings = onOpenSettings
    }

    var body: some View {
        HStack(spacing: 0) {
            if !suggestions.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 0) {
                        ForEach(Array(suggestions.enumerated()), id: \.offset) { idx, word in
                            HStack(spacing: 0) {
                                if idx > 0 {
                                    Rectangle()
                                        .fill(Color(token: theme.suggestionDividerColor))
                                        .frame(width: 1, height: 18)
                                }
                                Button {
                                    onSelect(word)
                                } label: {
                                    Text(word)
                                        .font(.system(size: 15.5, weight: .regular, design: .rounded))
                                        .foregroundStyle(Color(token: theme.suggestionTextColor))
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            } else {
                Spacer()
            }
        }
        .frame(height: suggestions.isEmpty ? 24 : 36)
        // Accent stripe along the top of the suggestion bar
        .overlay(alignment: .top) {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(token: theme.accentColor).opacity(0.7),
                            Color(token: theme.accentColor).opacity(0.0)
                        ],
                        startPoint: .leading, endPoint: .trailing
                    )
                )
                .frame(height: 1)
        }
        .background(Color(token: theme.suggestionBarBackground))
    }
}

#Preview {
    SuggestionBarView(
        suggestions: ["the", "that", "they"],
        theme: ThemeEngine.builtInThemes()[0],
        onSelect: { _ in }
    )
    .preferredColorScheme(.dark)
}
