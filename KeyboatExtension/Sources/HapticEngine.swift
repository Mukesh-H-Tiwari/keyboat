// HapticEngine.swift — Keyboat (KeyboatExtension target)
// Lives here (not in KeyboatCore) because UIKit is required.
// Imported by KeyboardViewController and KeyView.

import UIKit
import KeyboatCore

// MARK: - HapticEngine

@MainActor
final class HapticEngine {

    static let shared = HapticEngine()

    private var lightGenerator: UIImpactFeedbackGenerator?
    private var mediumGenerator: UIImpactFeedbackGenerator?
    private var heavyGenerator: UIImpactFeedbackGenerator?

    private var prefs: PreferencesStore { .shared }

    private init() {}

    func prepare() {
        guard prefs.hapticsEnabled else { return }
        if lightGenerator == nil {
            lightGenerator = UIImpactFeedbackGenerator(style: .light)
            mediumGenerator = UIImpactFeedbackGenerator(style: .medium)
            heavyGenerator = UIImpactFeedbackGenerator(style: .heavy)
        }
        generator(for: prefs.hapticsIntensity)?.prepare()
    }

    func keyTap()        { fire(generator: generator(for: prefs.hapticsIntensity)) }
    func specialKeyTap() { fire(generator: generator(for: prefs.hapticsIntensity)) }
    func returnKeyTap()  { guard prefs.hapticsEnabled, let g = mediumGenerator else { return }; g.impactOccurred() }
    func deleteKeyTap()  { fire(generator: lightGenerator) }

    // MARK: - Private

    private func fire(generator: UIImpactFeedbackGenerator?) {
        guard prefs.hapticsEnabled, let generator = generator else { return }
        generator.impactOccurred()
    }

    private func generator(for level: HapticLevel) -> UIImpactFeedbackGenerator? {
        switch level {
        case .off, .light: return lightGenerator
        case .medium:      return mediumGenerator
        case .strong:      return heavyGenerator
        }
    }
}
