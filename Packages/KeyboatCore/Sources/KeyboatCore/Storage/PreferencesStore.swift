// PreferencesStore.swift — Keyboat
// Type-safe, App Group-backed preferences.
// ObservableObject so SwiftUI views update automatically.

import Foundation
import Combine

// MARK: - Keys

private enum PrefKey: String {
    case themeID              = "kbt.themeID"
    case numberRowEnabled     = "kbt.numberRow"
    case hapticsEnabled       = "kbt.haptics"
    case hapticsIntensity     = "kbt.hapticsIntensity"
    case soundEnabled         = "kbt.sound"
    case activeLocale         = "kbt.locale"
    case autocorrectEnabled   = "kbt.autocorrect"
    case clipboardEnabled     = "kbt.clipboard"
    case clipboardRetentionDays = "kbt.clipboardRetention"
    case hasCompletedOnboarding = "kbt.onboardingDone"
}

// MARK: - HapticLevel

public enum HapticLevel: String, Codable, CaseIterable, Sendable {
    case off, light, medium, strong
}

// MARK: - PreferencesStore

@MainActor
public final class PreferencesStore: ObservableObject {

    public static let shared = PreferencesStore()

    // UserDefaults is accessed only on MainActor so no cross-actor race.
    private nonisolated(unsafe) let defaults: UserDefaults

    // MARK: - Published properties

    @Published public var themeID: String              = "midnight"
    @Published public var numberRowEnabled: Bool       = true
    @Published public var hapticsEnabled: Bool         = true
    @Published public var hapticsIntensity: HapticLevel = .medium
    @Published public var soundEnabled: Bool           = false
    @Published public var activeLocale: String         = "en"
    @Published public var autocorrectEnabled: Bool     = true
    @Published public var clipboardEnabled: Bool       = true
    @Published public var clipboardRetentionDays: Int  = 7
    @Published public var hasCompletedOnboarding: Bool = false

    // Observe changes and persist them
    private var cancellables = Set<AnyCancellable>()

    private init() {
        guard let d = UserDefaults(suiteName: AppGroup.suiteName) else {
            self.defaults = UserDefaults.standard
            return
        }
        self.defaults = d
        registerDefaults()
        readFromDefaults()
        setupPersistence()
    }

    // MARK: - Register defaults

    private func registerDefaults() {
        defaults.register(defaults: [
            PrefKey.themeID.rawValue:              "midnight",
            PrefKey.numberRowEnabled.rawValue:     true,
            PrefKey.hapticsEnabled.rawValue:       true,
            PrefKey.hapticsIntensity.rawValue:     HapticLevel.medium.rawValue,
            PrefKey.soundEnabled.rawValue:         false,
            PrefKey.activeLocale.rawValue:         "en",
            PrefKey.autocorrectEnabled.rawValue:   true,
            PrefKey.clipboardEnabled.rawValue:     true,
            PrefKey.clipboardRetentionDays.rawValue: 7,
            PrefKey.hasCompletedOnboarding.rawValue: false
        ])
    }

    // MARK: - Read from storage

    public func reloadFromDefaults() {
        themeID              = defaults.string(forKey: PrefKey.themeID.rawValue) ?? "dark"
        numberRowEnabled     = defaults.object(forKey: PrefKey.numberRowEnabled.rawValue) != nil ? defaults.bool(forKey: PrefKey.numberRowEnabled.rawValue) : true
        hapticsEnabled       = defaults.object(forKey: PrefKey.hapticsEnabled.rawValue) != nil ? defaults.bool(forKey: PrefKey.hapticsEnabled.rawValue) : true
        hapticsIntensity     = HapticLevel(rawValue: defaults.string(forKey: PrefKey.hapticsIntensity.rawValue) ?? "") ?? .medium
        soundEnabled         = defaults.bool(forKey: PrefKey.soundEnabled.rawValue)
        activeLocale         = defaults.string(forKey: PrefKey.activeLocale.rawValue) ?? "en"
        autocorrectEnabled   = defaults.object(forKey: PrefKey.autocorrectEnabled.rawValue) != nil ? defaults.bool(forKey: PrefKey.autocorrectEnabled.rawValue) : true
        clipboardEnabled     = defaults.object(forKey: PrefKey.clipboardEnabled.rawValue) != nil ? defaults.bool(forKey: PrefKey.clipboardEnabled.rawValue) : true
        clipboardRetentionDays = defaults.integer(forKey: PrefKey.clipboardRetentionDays.rawValue) > 0 ? defaults.integer(forKey: PrefKey.clipboardRetentionDays.rawValue) : 7
        hasCompletedOnboarding = defaults.bool(forKey: PrefKey.hasCompletedOnboarding.rawValue)
    }

    private func readFromDefaults() {
        reloadFromDefaults()
    }

    // MARK: - Persist on change

    private func setupPersistence() {
        $themeID.dropFirst().receive(on: DispatchQueue.main).sink { [weak self] v in
            self?.defaults.set(v, forKey: PrefKey.themeID.rawValue)
            self?.defaults.synchronize()
            self?.postDarwinNotification("com.mukeshtiwari.keyboat.themeChanged")
        }.store(in: &cancellables)

        $numberRowEnabled.dropFirst().receive(on: DispatchQueue.main).sink { [weak self] v in
            self?.defaults.set(v, forKey: PrefKey.numberRowEnabled.rawValue)
            self?.defaults.synchronize()
        }.store(in: &cancellables)

        $hapticsEnabled.dropFirst().receive(on: DispatchQueue.main).sink { [weak self] v in
            self?.defaults.set(v, forKey: PrefKey.hapticsEnabled.rawValue)
            self?.defaults.synchronize()
        }.store(in: &cancellables)

        $hapticsIntensity.dropFirst().receive(on: DispatchQueue.main).sink { [weak self] v in
            self?.defaults.set(v.rawValue, forKey: PrefKey.hapticsIntensity.rawValue)
            self?.defaults.synchronize()
        }.store(in: &cancellables)

        $soundEnabled.dropFirst().receive(on: DispatchQueue.main).sink { [weak self] v in
            self?.defaults.set(v, forKey: PrefKey.soundEnabled.rawValue)
            self?.defaults.synchronize()
        }.store(in: &cancellables)

        $activeLocale.dropFirst().receive(on: DispatchQueue.main).sink { [weak self] v in
            self?.defaults.set(v, forKey: PrefKey.activeLocale.rawValue)
            self?.defaults.synchronize()
        }.store(in: &cancellables)

        $autocorrectEnabled.dropFirst().receive(on: DispatchQueue.main).sink { [weak self] v in
            self?.defaults.set(v, forKey: PrefKey.autocorrectEnabled.rawValue)
            self?.defaults.synchronize()
        }.store(in: &cancellables)

        $clipboardEnabled.dropFirst().receive(on: DispatchQueue.main).sink { [weak self] v in
            self?.defaults.set(v, forKey: PrefKey.clipboardEnabled.rawValue)
            self?.defaults.synchronize()
        }.store(in: &cancellables)

        $clipboardRetentionDays.dropFirst().receive(on: DispatchQueue.main).sink { [weak self] v in
            self?.defaults.set(v, forKey: PrefKey.clipboardRetentionDays.rawValue)
            self?.defaults.synchronize()
        }.store(in: &cancellables)

        $hasCompletedOnboarding.dropFirst().receive(on: DispatchQueue.main).sink { [weak self] v in
            self?.defaults.set(v, forKey: PrefKey.hasCompletedOnboarding.rawValue)
            self?.defaults.synchronize()
        }.store(in: &cancellables)
    }

    private func postDarwinNotification(_ name: String) {
        let notificationName = name as CFString
        let center = CFNotificationCenterGetDarwinNotifyCenter()
        CFNotificationCenterPostNotification(center, CFNotificationName(notificationName), nil, nil, true)
    }
}
