// AppGroup.swift — Keyboat
// Central registry for the App Group identifier and shared container.
// Both the main app and keyboard extension import this.

import Foundation

public enum AppGroup {

    // MARK: - Identifiers

    /// App Group suite name — must match the entitlement in both targets.
    public static let suiteName = "group.com.mukeshtiwari.keyboat"

    // MARK: - Shared UserDefaults

    /// UserDefaults backed by the shared App Group container.
    /// Safely falls back to UserDefaults.standard if App Group provisioning isn't enabled yet on device.
    public nonisolated(unsafe) static let defaults: UserDefaults = {
        if containerURL != nil, let d = UserDefaults(suiteName: suiteName) {
            return d
        }
        return UserDefaults.standard
    }()

    // MARK: - Shared container URL

    /// URL of the shared container directory. Safe optional check for extension sandbox limits.
    public static var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: suiteName)
    }

    /// Convenience: a sub-directory in the container.
    public static func containerURL(subdirectory: String) -> URL? {
        guard let container = containerURL else { return nil }
        let url = container.appendingPathComponent(subdirectory, isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}
