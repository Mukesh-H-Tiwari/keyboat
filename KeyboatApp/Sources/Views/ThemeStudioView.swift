// ThemeStudioView.swift — Keyboat Container App
// Live keyboard preview + theme picker/editor.

import SwiftUI
import KeyboatCore

struct ThemeStudioView: View {

    @EnvironmentObject var themeEngine: ThemeEngine
    @EnvironmentObject var prefs: PreferencesStore

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {

                // Live keyboard preview
                KeyboardPreview(theme: themeEngine.activeTheme)
                    .frame(height: 260)
                    .background(Color(.systemGroupedBackground))

                Divider()

                // Theme grid
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        ForEach(themeEngine.allThemes) { theme in
                            ThemeCard(
                                theme: theme,
                                isActive: theme.id == themeEngine.activeTheme.id,
                                onSelect: {
                                    withAnimation(.spring(response: 0.3)) {
                                        themeEngine.activate(themeID: theme.id)
                                        prefs.themeID = theme.id
                                    }
                                }
                            )
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Theme Studio")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - KeyboardPreview

struct KeyboardPreview: View {
    let theme: Theme

    var body: some View {
        ZStack {
            Color(token: theme.keyboardBackground)

            VStack(spacing: 5) {
                // Top suggestion bar preview
                HStack {
                    HStack(spacing: 5) {
                        Circle()
                            .fill(Color(token: theme.accentColor))
                            .frame(width: 6, height: 6)
                        Text("Keyboat")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(Color(token: theme.suggestionTextColor).opacity(0.6))
                    }
                    Spacer()
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(Color(token: theme.accentColor))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 4)
                .background(Color(token: theme.suggestionBarBackground))

                // Number row preview
                previewRow(keys: Array("1234567890"), theme: theme)
                // Letter row previews
                previewRow(keys: Array("QWERTYUIOP"), theme: theme)
                previewRow(keys: Array("ASDFGHJKL"), theme: theme, inset: 12)
                previewRow(keys: Array("ZXCVBNM"), theme: theme, inset: 24)
            }
            .padding(.bottom, 10)
        }
        .animation(.spring(response: 0.4), value: theme.id)
    }

    private func previewRow(keys: [Character], theme: Theme, inset: CGFloat = 0) -> some View {
        HStack(spacing: CGFloat(theme.keySpacing)) {
            Spacer().frame(width: inset)
            ForEach(keys, id: \.self) { c in
                ZStack {
                    // Depth shadow
                    RoundedRectangle(cornerRadius: theme.keyCornerRadius * 0.7, style: .continuous)
                        .fill(Color(token: theme.keyShadow))
                        .offset(y: 1)

                    // Gradient body
                    RoundedRectangle(cornerRadius: theme.keyCornerRadius * 0.7, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(token: theme.keyBackground),
                                    Color(token: theme.keyBackground).opacity(0.8)
                                ],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: theme.keyCornerRadius * 0.7, style: .continuous)
                                .strokeBorder(Color.white.opacity(0.12), lineWidth: 0.5)
                        )

                    Text(String(c))
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(Color(token: theme.keyForeground))
                }
                .frame(height: CGFloat(theme.keyHeight) * 0.65)
            }
            Spacer().frame(width: inset)
        }
        .padding(.horizontal, 6)
    }
}

// MARK: - ThemeCard

struct ThemeCard: View {
    let theme: Theme
    let isActive: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 8) {
                // Mini preview swatch
                let bg = Color(token: theme.keyboardBackground)
                let keyBg = Color(token: theme.keyBackground)
                let strokeColor = isActive ? Color(token: theme.accentColor) : Color.clear

                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(bg)
                    .frame(height: 80)
                    .overlay {
                        HStack(spacing: 4) {
                            ForEach(0..<5, id: \.self) { _ in
                                RoundedRectangle(cornerRadius: 4, style: .continuous)
                                    .fill(keyBg)
                                    .frame(width: 20, height: 24)
                            }
                        }
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(strokeColor, lineWidth: 3)
                    }

                HStack {
                    Text(theme.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)

                    if theme.isBuiltIn {
                        Text("Built-in")
                            .font(.system(size: 10, weight: .medium))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.secondary.opacity(0.15))
                            .cornerRadius(4)
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - SwiftUI Color from ColorToken

private extension Color {
    init(token: ColorToken) {
        self.init(.sRGB, red: token.r, green: token.g, blue: token.b, opacity: token.a)
    }
}

#Preview {
    ThemeStudioView()
        .environmentObject(ThemeEngine.shared)
        .environmentObject(PreferencesStore.shared)
}
