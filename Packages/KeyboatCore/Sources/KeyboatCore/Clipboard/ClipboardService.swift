// ClipboardService.swift — Keyboat
// Protocol + V1 implementation (UserDefaults bounded store, cap 50 items).
// V1.1: swap ClipboardStore implementation for GRDB without touching this protocol.

import Foundation
import Combine

// MARK: - ClipboardServiceProtocol

public protocol ClipboardServiceProtocol: AnyObject, Sendable {
    func add(text: String)
    func allItems() -> [ClipboardItem]
    func pinnedItems() -> [ClipboardItem]
    func recentItems(limit: Int) -> [ClipboardItem]
    func pin(_ item: ClipboardItem)
    func unpin(_ item: ClipboardItem)
    func delete(id: UUID)
    func deleteAll()
    func markUsed(id: UUID)
    func purgeExpired()
}

// MARK: - ClipboardStore (V1 — UserDefaults)

public final class ClipboardStore: ClipboardServiceProtocol, @unchecked Sendable {

    public static let shared = ClipboardStore()

    private let key = "kbt.clipboardItems"
    private let cap = 50
    private var items: [ClipboardItem] = []
    private let lock = NSLock()

    private init() {
        load()
        purgeExpired()
    }

    // MARK: - Protocol

    public func add(text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        lock.lock(); defer { lock.unlock() }

        // Deduplicate: if same text exists, refresh its timestamp and move to top
        if let idx = items.firstIndex(where: { $0.text == trimmed }) {
            var existing = items.remove(at: idx)
            existing.lastUsedAt = Date()
            items.insert(existing, at: 0)
        } else {
            let type = ClipboardItemType.detect(from: trimmed)
            let retentionDays = AppGroup.defaults.integer(forKey: "kbt.clipboardRetention")
            let expiry: Date? = retentionDays > 0
                ? Calendar.current.date(byAdding: .day, value: retentionDays, to: .now)
                : nil
            let item = ClipboardItem(text: trimmed, type: type, expirationDate: expiry)
            items.insert(item, at: 0)
        }

        // Enforce cap (keep pinned items, evict oldest unpinned)
        enforceCap()
        persist()
    }

    public func allItems() -> [ClipboardItem] {
        lock.lock(); defer { lock.unlock() }
        return items.sorted {
            if $0.isPinned != $1.isPinned { return $0.isPinned }
            return $0.lastUsedAt > $1.lastUsedAt
        }
    }

    public func pinnedItems() -> [ClipboardItem] {
        lock.lock(); defer { lock.unlock() }
        return items.filter(\.isPinned).sorted { $0.createdAt < $1.createdAt }
    }

    public func recentItems(limit: Int) -> [ClipboardItem] {
        lock.lock(); defer { lock.unlock() }
        return Array(
            items.filter { !$0.isPinned }
                .sorted { $0.lastUsedAt > $1.lastUsedAt }
                .prefix(limit)
        )
    }

    public func pin(_ item: ClipboardItem) {
        mutate(id: item.id) { $0.isPinned = true }
    }

    public func unpin(_ item: ClipboardItem) {
        mutate(id: item.id) { $0.isPinned = false }
    }

    public func delete(id: UUID) {
        lock.lock()
        items.removeAll { $0.id == id }
        persist()
        lock.unlock()
    }

    public func deleteAll() {
        lock.lock()
        items.removeAll { !$0.isPinned }
        persist()
        lock.unlock()
    }

    public func markUsed(id: UUID) {
        mutate(id: id) { $0.lastUsedAt = Date() }
    }

    public func purgeExpired() {
        lock.lock()
        items.removeAll { $0.isExpired && !$0.isPinned }
        persist()
        lock.unlock()
    }

    // MARK: - Private

    private func mutate(id: UUID, _ transform: (inout ClipboardItem) -> Void) {
        lock.lock(); defer { lock.unlock() }
        guard let idx = items.firstIndex(where: { $0.id == id }) else { return }
        transform(&items[idx])
        persist()
    }

    private func enforceCap() {
        // items is already sorted (newest first). Protect pinned items.
        let pinned  = items.filter(\.isPinned)
        var unpinned = items.filter { !$0.isPinned }
        let maxUnpinned = cap - pinned.count
        if unpinned.count > maxUnpinned {
            unpinned = Array(unpinned.prefix(maxUnpinned))
        }
        items = pinned + unpinned
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(items) else { return }
        AppGroup.defaults.set(data, forKey: key)
    }

    private func load() {
        guard let data = AppGroup.defaults.data(forKey: key),
              let decoded = try? JSONDecoder().decode([ClipboardItem].self, from: data)
        else { items = []; return }
        items = decoded
    }
}
