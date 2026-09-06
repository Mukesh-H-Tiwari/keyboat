// ThemeStudioView.swift — Keyboat Container App
// Live keyboard preview + categorized theme picker & custom theme editor.

import SwiftUI
import KeyboatCore

struct ThemeStudioView: View {

    @EnvironmentObject var themeEngine: ThemeEngine
    @EnvironmentObject var prefs: PreferencesStore

    @State private var selectedCategoryFilter: ThemeCategoryFilter = .all
    @State private var editingTheme: Theme? = nil
    @State private var isCreatingCustom: Bool = false

    enum ThemeCategoryFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case iosSystem = "iOS System"
        case oledDark = "Dark & OLED"
        case minimalPastel = "Minimal"
        case vibrantNeon = "Vibrant"
        case custom = "Custom"

        var id: String { rawValue }

        var iconName: String {
            switch self {
            case .all: return "square.grid.2x2.fill"
            case .iosSystem: return "apple.logo"
            case .oledDark: return "moon.stars.fill"
            case .minimalPastel: return "sparkles"
            case .vibrantNeon: return "bolt.fill"
            case .custom: return "paintpalette.fill"
            }
        }
    }

    var filteredThemes: [Theme] {
        switch selectedCategoryFilter {
        case .all:
            return themeEngine.allThemes
        case .iosSystem:
            return themeEngine.allThemes.filter { $0.category == .iosSystem }
        case .oledDark:
            return themeEngine.allThemes.filter { $0.category == .oledDark }
        case .minimalPastel:
            return themeEngine.allThemes.filter { $0.category == .minimalPastel }
        case .vibrantNeon:
            return themeEngine.allThemes.filter { $0.category == .vibrantNeon }
        case .custom:
            return themeEngine.allThemes.filter { $0.category == .custom || !$0.isBuiltIn }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {

                // Live keyboard preview
                VStack(spacing: 6) {
                    KeyboardPreview(theme: editingTheme ?? themeEngine.activeTheme)
                        .frame(height: 250)
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                        .padding(.horizontal)
                        .padding(.top, 8)
                }
                .padding(.bottom, 8)
                .background(Color(.systemGroupedBackground))

                Divider()

                // Category selector bar
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(ThemeCategoryFilter.allCases) { filter in
                            Button {
                                withAnimation(.spring(response: 0.3)) {
                                    selectedCategoryFilter = filter
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: filter.iconName)
                                        .font(.system(size: 12, weight: .semibold))
                                    Text(filter.rawValue)
                                        .font(.system(size: 13, weight: .medium))
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(selectedCategoryFilter == filter ? Color.accentColor : Color(.tertiarySystemFill))
                                .foregroundColor(selectedCategoryFilter == filter ? .white : .primary)
                                .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                }
                .background(Color(.secondarySystemGroupedBackground))

                Divider()

                // Theme grid
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 16),
                        GridItem(.flexible(), spacing: 16)
                    ], spacing: 16) {

                        // Add Custom Theme card
                        Button {
                            let newCustom = createNewCustomThemeTemplate()
                            editingTheme = newCustom
                            isCreatingCustom = true
                        } label: {
                            VStack(spacing: 8) {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [6]))
                                    .foregroundColor(.accentColor)
                                    .frame(height: 84)
                                    .overlay {
                                        VStack(spacing: 4) {
                                            Image(systemName: "plus.circle.fill")
                                                .font(.system(size: 24))
                                                .foregroundColor(.accentColor)
                                            Text("Create Custom")
                                                .font(.system(size: 12, weight: .semibold))
                                                .foregroundColor(.accentColor)
                                        }
                                    }

                                Text("Custom Theme")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .buttonStyle(.plain)

                        ForEach(filteredThemes) { theme in
                            ThemeCard(
                                theme: theme,
                                isActive: theme.id == themeEngine.activeTheme.id,
                                onSelect: {
                                    withAnimation(.spring(response: 0.3)) {
                                        themeEngine.activate(themeID: theme.id)
                                        prefs.themeID = theme.id
                                    }
                                },
                                onEdit: theme.isBuiltIn ? nil : {
                                    editingTheme = theme
                                    isCreatingCustom = false
                                }
                            )
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Theme Studio")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $editingTheme) { themeToEdit in
                ThemeEditorSheet(
                    theme: themeToEdit,
                    isNew: isCreatingCustom,
                    onSave: { updatedTheme in
                        themeEngine.save(theme: updatedTheme)
                        themeEngine.activate(themeID: updatedTheme.id)
                        prefs.themeID = updatedTheme.id
                        editingTheme = nil
                    },
                    onDelete: themeToEdit.isBuiltIn ? nil : {
                        themeEngine.delete(themeID: themeToEdit.id)
                        editingTheme = nil
                    }
                )
            }
        }
    }

    private func createNewCustomThemeTemplate() -> Theme {
        Theme(
            id: UUID().uuidString,
            name: "My Theme \(themeEngine.allThemes.filter { !$0.isBuiltIn }.count + 1)",
            category: .custom,
            isBuiltIn: false,
            keyboardBackground: .hex("#1C1C1E"),
            numberRowBackground: .hex("#141416"),
            keyBackground: .hex("#2C2C2E"),
            keyForeground: .hex("#FFFFFF"),
            keyShadow: ColorToken(r: 0, g: 0, b: 0, a: 0.5),
            keyCornerRadius: 10,
            specialKeyBackground: .hex("#3A3A3C"),
            specialKeyForeground: .hex("#007AFF"),
            spaceKeyBackground: .hex("#2C2C2E"),
            spaceKeyForeground: .hex("#FFFFFF"),
            suggestionBarBackground: .hex("#161618"),
            suggestionTextColor: .hex("#FFFFFF"),
            suggestionDividerColor: .hex("#3A3A3C"),
            clipboardBackground: .hex("#1C1C1E"),
            clipboardItemBackground: .hex("#2C2C2E"),
            clipboardItemText: .hex("#FFFFFF"),
            clipboardPinnedBadge: .hex("#007AFF"),
            accentColor: .hex("#007AFF"),
            keyFont: .init(size: 17, weight: .regular),
            specialKeyFont: .init(size: 13, weight: .medium),
            keySpacing: 6, keyHeight: 44, shadowOpacity: 0.5
        )
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
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color(token: theme.accentColor))
                            .frame(width: 7, height: 7)
                        Text(theme.name)
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color(token: theme.suggestionTextColor).opacity(0.8))
                    }
                    Spacer()
                    Text("PREVIEW")
                        .font(.system(size: 9, weight: .bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(token: theme.accentColor).opacity(0.2))
                        .foregroundStyle(Color(token: theme.accentColor))
                        .cornerRadius(4)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
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

                    // Key body
                    RoundedRectangle(cornerRadius: theme.keyCornerRadius * 0.7, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(token: theme.keyBackground),
                                    Color(token: theme.keyBackground).opacity(0.85)
                                ],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: theme.keyCornerRadius * 0.7, style: .continuous)
                                .strokeBorder(Color.white.opacity(0.12), lineWidth: 0.5)
                        )

                    Text(String(c))
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
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
    var onEdit: (() -> Void)? = nil

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 8) {
                // Mini preview swatch
                let bg = Color(token: theme.keyboardBackground)
                let keyBg = Color(token: theme.keyBackground)
                let strokeColor = isActive ? Color(token: theme.accentColor) : Color.clear

                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(bg)
                    .frame(height: 84)
                    .overlay {
                        VStack(spacing: 4) {
                            HStack(spacing: 3) {
                                ForEach(0..<5, id: \.self) { _ in
                                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                                        .fill(keyBg)
                                        .frame(width: 18, height: 22)
                                }
                            }
                            RoundedRectangle(cornerRadius: 3, style: .continuous)
                                .fill(Color(token: theme.spaceKeyBackground))
                                .frame(width: 60, height: 10)
                        }
                    }
                    .overlay(alignment: .topTrailing) {
                        if isActive {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(Color(token: theme.accentColor))
                                .background(Circle().fill(Color.white))
                                .padding(6)
                        }
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(strokeColor, lineWidth: 3)
                    }

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(theme.name)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.primary)
                            .lineLimit(1)

                        Text(theme.category.rawValue)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.secondary)
                    }

                    Spacer(minLength: 0)

                    if let onEdit {
                        Button(action: onEdit) {
                            Image(systemName: "slider.horizontal.3")
                                .font(.system(size: 12, weight: .bold))
                                .padding(6)
                                .background(Color(.tertiarySystemFill))
                                .clipShape(Circle())
                        }
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - ThemeEditorSheet

struct ThemeEditorSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State var theme: Theme
    let isNew: Bool
    let onSave: (Theme) -> Void
    var onDelete: (() -> Void)? = nil

    // Color pickers binding wrappers
    @State private var keyboardBgColor: Color = .black
    @State private var keyBgColor: Color = .gray
    @State private var keyFgColor: Color = .white
    @State private var specialKeyBgColor: Color = .gray
    @State private var accentColor: Color = .blue
    @State private var cornerRadius: Double = 10

    var body: some View {
        NavigationStack {
            Form {
                Section("Theme Profile") {
                    TextField("Theme Name", text: $theme.name)
                    Picker("Category", selection: $theme.category) {
                        ForEach(ThemeCategory.allCases) { cat in
                            Text(cat.rawValue).tag(cat)
                        }
                    }
                }

                Section("Live Preview") {
                    KeyboardPreview(theme: currentDraftTheme)
                        .frame(height: 220)
                        .cornerRadius(12)
                        .listRowInsets(EdgeInsets())
                }

                Section("Color Palette") {
                    ColorPicker("Keyboard Background", selection: $keyboardBgColor)
                    ColorPicker("Standard Key Background", selection: $keyBgColor)
                    ColorPicker("Key Text Color", selection: $keyFgColor)
                    ColorPicker("Special Key Background", selection: $specialKeyBgColor)
                    ColorPicker("Accent Color", selection: $accentColor)
                }

                Section("Key Shape") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Corner Radius")
                            Spacer()
                            Text("\(Int(cornerRadius)) pt")
                                .foregroundStyle(.secondary)
                        }
                        Slider(value: $cornerRadius, in: 4...20, step: 1)
                    }
                }

                if !isNew && onDelete != nil {
                    Section {
                        Button(role: .destructive) {
                            onDelete?()
                        } label: {
                            HStack {
                                Spacer()
                                Text("Delete Custom Theme")
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle(isNew ? "New Theme" : "Edit Theme")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(currentDraftTheme)
                    }
                    .font(.system(size: 16, weight: .bold))
                }
            }
            .onAppear {
                keyboardBgColor = Color(token: theme.keyboardBackground)
                keyBgColor = Color(token: theme.keyBackground)
                keyFgColor = Color(token: theme.keyForeground)
                specialKeyBgColor = Color(token: theme.specialKeyBackground)
                accentColor = Color(token: theme.accentColor)
                cornerRadius = theme.keyCornerRadius
            }
        }
    }

    private var currentDraftTheme: Theme {
        var copy = theme
        copy.keyboardBackground = ColorToken(color: keyboardBgColor)
        copy.numberRowBackground = ColorToken(color: keyboardBgColor)
        copy.keyBackground = ColorToken(color: keyBgColor)
        copy.keyForeground = ColorToken(color: keyFgColor)
        copy.specialKeyBackground = ColorToken(color: specialKeyBgColor)
        copy.spaceKeyBackground = ColorToken(color: keyBgColor)
        copy.suggestionBarBackground = ColorToken(color: keyboardBgColor)
        copy.accentColor = ColorToken(color: accentColor)
        copy.keyCornerRadius = cornerRadius
        return copy
    }
}

// MARK: - Color Extensions for ColorToken

private extension Color {
    init(token: ColorToken) {
        self.init(.sRGB, red: token.r, green: token.g, blue: token.b, opacity: token.a)
    }
}

private extension ColorToken {
    init(color: Color) {
        let uiColor = UIColor(color)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        self.init(r: Double(r), g: Double(g), b: Double(b), a: Double(a))
    }
}

#Preview {
    ThemeStudioView()
        .environmentObject(ThemeEngine.shared)
        .environmentObject(PreferencesStore.shared)
}
