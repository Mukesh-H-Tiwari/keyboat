// OnboardingView.swift — Keyboat
// Three-step onboarding: install keyboard → enable full access → start typing.

import SwiftUI
import KeyboatCore

struct OnboardingView: View {

    @EnvironmentObject var prefs: PreferencesStore
    @EnvironmentObject var themeEngine: ThemeEngine
    @State private var step = 0

    private let steps: [OnboardingStep] = [
        OnboardingStep(
            systemImage: "keyboard.fill",
            title: "Welcome to Keyboat",
            subtitle: "A keyboard designed for speed, privacy, and full customisation.",
            buttonTitle: "Let's go"
        ),
        OnboardingStep(
            systemImage: "gearshape.2.fill",
            title: "Install the Keyboard",
            subtitle: "Go to Settings → General → Keyboard → Keyboards → Add New Keyboard → Keyboat.",
            buttonTitle: "I've added it"
        ),
        OnboardingStep(
            systemImage: "lock.open.fill",
            title: "Enable Full Access",
            subtitle: "Full Access allows clipboard history and theme sync between the app and keyboard. You can always revoke it in Settings.",
            buttonTitle: "All set →"
        )
    ]

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "#0D1B2A"), Color(hex: "#1B3A5C")],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Step indicator
                HStack(spacing: 8) {
                    ForEach(0..<steps.count, id: \.self) { i in
                        Circle()
                            .fill(i == step ? Color.white : Color.white.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .scaleEffect(i == step ? 1.2 : 1.0)
                            .animation(.spring(), value: step)
                    }
                }
                .padding(.bottom, 48)

                // Icon
                Image(systemName: steps[step].systemImage)
                    .font(.system(size: 72, weight: .thin))
                    .foregroundColor(.white)
                    .padding(.bottom, 32)
                    .transition(.scale.combined(with: .opacity))
                    .id(step)  // force transition

                // Title
                Text(steps[step].title)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 16)

                // Subtitle
                Text(steps[step].subtitle)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 60)

                Spacer()

                // CTA button
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        if step < steps.count - 1 {
                            step += 1
                        } else {
                            prefs.hasCompletedOnboarding = true
                        }
                    }
                } label: {
                    Text(steps[step].buttonTitle)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color(hex: "#0D1B2A"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color.white)
                        )
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
            }
        }
    }
}

// MARK: - OnboardingStep

private struct OnboardingStep {
    let systemImage: String
    let title: String
    let subtitle: String
    let buttonTitle: String
}

// MARK: - Color from hex string (App target utility)

extension Color {
    init(hex: String) {
        let str = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        let scanner = Scanner(string: str)
        var value: UInt64 = 0
        scanner.scanHexInt64(&value)
        let r = Double((value & 0xFF0000) >> 16) / 255
        let g = Double((value & 0x00FF00) >> 8)  / 255
        let b = Double(value & 0x0000FF)          / 255
        self.init(red: r, green: g, blue: b)
    }
}

#Preview {
    OnboardingView()
        .environmentObject(PreferencesStore.shared)
        .environmentObject(ThemeEngine.shared)
}
