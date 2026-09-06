// ClipboardItem.swift — Keyboat
// Data model for a single clipboard history entry.

import Foundation

// MARK: - ClipboardItemType

public enum ClipboardItemType: String, Codable, Sendable, CaseIterable {
    case plainText
    case url
    case email
    case phone
    case number
    case address
    case unknown

    // MARK: - SF Symbol name for display
    public var symbolName: String {
        switch self {
        case .plainText: return "doc.text"
        case .url:       return "link"
        case .email:     return "envelope"
        case .phone:     return "phone"
        case .number:    return "number"
        case .address:   return "mappin"
        case .unknown:   return "doc"
        }
    }
}

// MARK: - ClipboardItem

public struct ClipboardItem: Codable, Sendable, Identifiable, Equatable {
    public let id: UUID
    public let text: String
    public let type: ClipboardItemType
    public let createdAt: Date
    public var lastUsedAt: Date
    public var isPinned: Bool
    public var expirationDate: Date?

    public init(
        id: UUID = UUID(),
        text: String,
        type: ClipboardItemType = .unknown,
        createdAt: Date = Date(),
        lastUsedAt: Date = Date(),
        isPinned: Bool = false,
        expirationDate: Date? = nil
    ) {
        self.id = id
        self.text = text
        self.type = type
        self.createdAt = createdAt
        self.lastUsedAt = lastUsedAt
        self.isPinned = isPinned
        self.expirationDate = expirationDate
    }

    // MARK: - Helpers

    /// Trimmed display text (max 120 chars) for list cells.
    public var displayText: String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.count > 120 ? String(trimmed.prefix(117)) + "…" : trimmed
    }

    /// True if the item has expired and should be culled.
    public var isExpired: Bool {
        guard let exp = expirationDate else { return false }
        return Date() > exp
    }
}

// MARK: - ClipboardItemType detection

public extension ClipboardItemType {
    /// Heuristically detect the type of a plain-text string.
    static func detect(from text: String) -> ClipboardItemType {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        // URL
        if let url = URL(string: trimmed), url.scheme != nil, url.host != nil {
            return .url
        }
        // Email
        let emailRegex = #"^[^@\s]+@[^@\s]+\.[^@\s]+$"#
        if trimmed.range(of: emailRegex, options: .regularExpression) != nil {
            return .email
        }
        // Phone (loose match)
        let phoneRegex = #"^[\+]?[(]?[0-9]{3}[)]?[-\s\.]?[0-9]{3}[-\s\.]?[0-9]{4,6}$"#
        if trimmed.range(of: phoneRegex, options: .regularExpression) != nil {
            return .phone
        }
        // Pure number
        if Double(trimmed) != nil {
            return .number
        }
        // Plain text
        if !trimmed.isEmpty {
            return .plainText
        }
        return .unknown
    }
}
