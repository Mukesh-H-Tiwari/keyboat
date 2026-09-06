// SettingsView.swift — Keyboat Container App

import SwiftUI
import KeyboatCore

struct SettingsView: View {

    @EnvironmentObject var prefs: PreferencesStore
    @EnvironmentObject var themeEngine: ThemeEngine

    var body: some View {
        NavigationStack {
            List {

                // MARK: Appearance
                Section("Appearance") {
                    Picker("Theme", selection: $prefs.themeID) {
                        ForEach(themeEngine.allThemes) { theme in
                            Text(theme.name).tag(theme.id)
                        }
                    }
                    .onChange(of: prefs.themeID) { _, newID in
                        themeEngine.activate(themeID: newID)
                    }
                }

                // MARK: Typing
                Section("Typing") {
                    Toggle("Number Row", isOn: $prefs.numberRowEnabled)
                    Toggle("Autocorrect", isOn: $prefs.autocorrectEnabled)
                }

                // MARK: Feedback
                Section("Feedback") {
                    Toggle("Haptic Feedback", isOn: $prefs.hapticsEnabled)

                    if prefs.hapticsEnabled {
                        Picker("Intensity", selection: $prefs.hapticsIntensity) {
                            ForEach(HapticLevel.allCases, id: \.self) { level in
                                Text(level.rawValue.capitalized).tag(level)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    Toggle("Key Sounds", isOn: $prefs.soundEnabled)
                }

                // MARK: Clipboard
                Section("Clipboard") {
                    Toggle("Clipboard History", isOn: $prefs.clipboardEnabled)

                    if prefs.clipboardEnabled {
                        Stepper(
                            "Keep for \(prefs.clipboardRetentionDays) day\(prefs.clipboardRetentionDays == 1 ? "" : "s")",
                            value: $prefs.clipboardRetentionDays,
                            in: 1...30
                        )
                    }
                }

                // MARK: Language
                Section("Language") {
                    LabeledContent("Active Language", value: prefs.activeLocale.uppercased())
                        .foregroundColor(.secondary)
                }

                // MARK: About
                Section("About") {
                    LabeledContent("Version", value: appVersion)
                    Link("Privacy Policy", destination: URL(string: "https://keyboat.app/privacy")!)
                    Link("Open Source Licences", destination: URL(string: "https://keyboat.app/licences")!)
                }
            }
            .navigationTitle("Keyboat")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private var appVersion: String {
        (Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String) ?? "1.0"
    }
}

#Preview {
    SettingsView()
        .environmentObject(PreferencesStore.shared)
        .environmentObject(ThemeEngine.shared)
}
