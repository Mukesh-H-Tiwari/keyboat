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
    /// Returns nil if the group isn't configured (shouldn't happen in production).
    public nonisolated(unsafe) static let defaults: UserDefaults = {
        guard let d = UserDefaults(suiteName: suiteName) else {
            // Fallback to standard in test/simulator environments without App Group
            return UserDefaults.standard
        }
        return d
    }()

    // MARK: - Shared container URL

    /// URL of the shared container directory. Use for SQLite, large files etc.
    public static var containerURL: URL {
        guard let url = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: suiteName) else {
            fatalError("App Group container URL unavailable for '\(suiteName)'.")
        }
        return url
    }

    /// Convenience: a sub-directory in the container.
    public static func containerURL(subdirectory: String) -> URL {
        let url = containerURL.appendingPathComponent(subdirectory, isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}
