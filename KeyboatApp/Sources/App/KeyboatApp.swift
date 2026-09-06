// KeyboatApp.swift — Keyboat Container App
// SwiftUI entry point for the containing application.

import SwiftUI
import KeyboatCore

@main
struct KeyboatApp: App {

    @StateObject private var prefs = PreferencesStore.shared
    @StateObject private var themeEngine = ThemeEngine.shared

    var body: some Scene {
        WindowGroup {
            if prefs.hasCompletedOnboarding {
                AppRootView()
                    .environmentObject(prefs)
                    .environmentObject(themeEngine)
            } else {
                OnboardingView()
                    .environmentObject(prefs)
                    .environmentObject(themeEngine)
            }
        }
    }
}

// MARK: - AppRootView

struct AppRootView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(0)

            ThemeStudioView()
                .tabItem {
                    Label("Themes", systemImage: "paintpalette.fill")
                }
                .tag(1)

            ClipboardBrowserView()
                .tabItem {
                    Label("Clipboard", systemImage: "doc.on.clipboard.fill")
                }
                .tag(2)
        }
        .accentColor(.blue)
    }
}
