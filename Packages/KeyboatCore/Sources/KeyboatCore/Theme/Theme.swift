// Theme.swift — Keyboat
// Complete theme data model. Codable for JSON, Sendable for safe concurrency.

import Foundation

// MARK: - ColorToken

/// A platform-agnostic RGBA color token.
/// Converted to SwiftUI Color or UIColor by the UI layer.
public struct ColorToken: Codable, Sendable, Equatable {
    public let r: Double    // 0–1
    public let g: Double    // 0–1
    public let b: Double    // 0–1
    public let a: Double    // 0–1 (opacity)

    public init(r: Double, g: Double, b: Double, a: Double = 1.0) {
        self.r = r; self.g = g; self.b = b; self.a = a
    }

    public static func hex(_ hex: String) -> ColorToken {
        var str = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        str = str.hasPrefix("#") ? String(str.dropFirst()) : str
        let scanner = Scanner(string: str)
        var value: UInt64 = 0
        scanner.scanHexInt64(&value)
        let r = Double((value & 0xFF0000) >> 16) / 255
        let g = Double((value & 0x00FF00) >> 8)  / 255
        let b = Double((value & 0x0000FF))        / 255
        return ColorToken(r: r, g: g, b: b)
    }
}

// MARK: - FontToken

public struct FontToken: Codable, Sendable, Equatable {
    public let family: String   // e.g. "SF Pro", "System"
    public let size: Double
    public let weight: FontWeightToken

    public init(family: String = "System", size: Double = 16, weight: FontWeightToken = .regular) {
        self.family = family; self.size = size; self.weight = weight
    }
}

public enum FontWeightToken: String, Codable, Sendable, CaseIterable {
    case ultraLight, thin, light, regular, medium, semibold, bold, heavy, black
}

// MARK: - ThemeCategory

public enum ThemeCategory: String, Codable, Sendable, CaseIterable, Identifiable {
    case iosSystem = "iOS System"
    case oledDark = "Dark & OLED"
    case minimalPastel = "Minimal & Pastel"
    case vibrantNeon = "Vibrant & Neon"
    case custom = "Custom"

    public var id: String { rawValue }
    public var iconName: String {
        switch self {
        case .iosSystem: return "apple.logo"
        case .oledDark: return "moon.stars.fill"
        case .minimalPastel: return "sparkles"
        case .vibrantNeon: return "bolt.fill"
        case .custom: return "paintpalette.fill"
        }
    }
}

// MARK: - Theme

public struct Theme: Codable, Sendable, Identifiable, Equatable {
    public let id: String                       // e.g. "dark", "ocean", user UUID
    public var name: String
    public var category: ThemeCategory
    public var isBuiltIn: Bool

    // Background
    public var keyboardBackground: ColorToken
    public var numberRowBackground: ColorToken

    // Standard keys
    public var keyBackground: ColorToken
    public var keyForeground: ColorToken
    public var keyShadow: ColorToken
    public var keyCornerRadius: Double

    // Special keys (Shift, Backspace, Return, Globe, Numbers)
    public var specialKeyBackground: ColorToken
    public var specialKeyForeground: ColorToken

    // Space bar
    public var spaceKeyBackground: ColorToken
    public var spaceKeyForeground: ColorToken

    // Suggestion bar
    public var suggestionBarBackground: ColorToken
    public var suggestionTextColor: ColorToken
    public var suggestionDividerColor: ColorToken

    // Clipboard panel
    public var clipboardBackground: ColorToken
    public var clipboardItemBackground: ColorToken
    public var clipboardItemText: ColorToken
    public var clipboardPinnedBadge: ColorToken

    // Accent
    public var accentColor: ColorToken

    // Typography
    public var keyFont: FontToken
    public var specialKeyFont: FontToken

    // Misc
    public var keySpacing: Double           // points between keys
    public var keyHeight: Double            // points (standard row height)
    public var shadowOpacity: Double        // 0–1

    public init(
        id: String, name: String, category: ThemeCategory = .custom, isBuiltIn: Bool = false,
        keyboardBackground: ColorToken, numberRowBackground: ColorToken,
        keyBackground: ColorToken, keyForeground: ColorToken,
        keyShadow: ColorToken, keyCornerRadius: Double,
        specialKeyBackground: ColorToken, specialKeyForeground: ColorToken,
        spaceKeyBackground: ColorToken, spaceKeyForeground: ColorToken,
        suggestionBarBackground: ColorToken, suggestionTextColor: ColorToken,
        suggestionDividerColor: ColorToken,
        clipboardBackground: ColorToken, clipboardItemBackground: ColorToken,
        clipboardItemText: ColorToken, clipboardPinnedBadge: ColorToken,
        accentColor: ColorToken,
        keyFont: FontToken = .init(), specialKeyFont: FontToken = .init(size: 13),
        keySpacing: Double = 6, keyHeight: Double = 44, shadowOpacity: Double = 0.3
    ) {
        self.id = id; self.name = name; self.category = category; self.isBuiltIn = isBuiltIn
        self.keyboardBackground = keyboardBackground
        self.numberRowBackground = numberRowBackground
        self.keyBackground = keyBackground
        self.keyForeground = keyForeground
        self.keyShadow = keyShadow
        self.keyCornerRadius = keyCornerRadius
        self.specialKeyBackground = specialKeyBackground
        self.specialKeyForeground = specialKeyForeground
        self.spaceKeyBackground = spaceKeyBackground
        self.spaceKeyForeground = spaceKeyForeground
        self.suggestionBarBackground = suggestionBarBackground
        self.suggestionTextColor = suggestionTextColor
        self.suggestionDividerColor = suggestionDividerColor
        self.clipboardBackground = clipboardBackground
        self.clipboardItemBackground = clipboardItemBackground
        self.clipboardItemText = clipboardItemText
        self.clipboardPinnedBadge = clipboardPinnedBadge
        self.accentColor = accentColor
        self.keyFont = keyFont
        self.specialKeyFont = specialKeyFont
        self.keySpacing = keySpacing
        self.keyHeight = keyHeight
        self.shadowOpacity = shadowOpacity
    }
}
