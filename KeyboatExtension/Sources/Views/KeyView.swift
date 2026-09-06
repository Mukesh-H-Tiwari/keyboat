// KeyView.swift — Keyboat
// Individual key button. Handles press/long-press, haptics, shift display.
// Premium visual design: gradient fills, inner-glow, depth shadow, spring animation.

import SwiftUI
import KeyboatCore

// MARK: - KeyView

struct KeyView: View {

    let definition: KeyDefinition
    let theme: Theme
    let shiftState: ShiftState
    let onAction: (KeyAction) -> Void

    @State private var isPressed = false

    // MARK: - Body

    var body: some View {
        let isSpecial = definition.isSpecialKey
        let isSpace   = definition.action == .space

        ZStack {
            // ── Depth shadow (key bottom edge) ──────────────────────────
            RoundedRectangle(cornerRadius: theme.keyCornerRadius + 1, style: .continuous)
                .fill(Color(token: theme.keyShadow))
                .offset(y: isPressed ? 0 : 1)

            // ── Key body with gradient ───────────────────────────────────
            RoundedRectangle(cornerRadius: theme.keyCornerRadius, style: .continuous)
                .fill(keyGradient(isSpecial: isSpecial, isSpace: isSpace))
                .overlay {
                    // Subtle top-gloss highlight
                    RoundedRectangle(cornerRadius: theme.keyCornerRadius, style: .continuous)
                        .fill(glossOverlay)
                }
                .overlay {
                    // Thin border for premium definition
                    RoundedRectangle(cornerRadius: theme.keyCornerRadius, style: .continuous)
                        .strokeBorder(borderColor(isSpecial: isSpecial), lineWidth: 0.5)
                }

            // ── Label / icon ─────────────────────────────────────────────
            keyContent(isSpecial: isSpecial)
                .foregroundStyle(keyForeground(isSpecial: isSpecial, isSpace: isSpace))
        }
        .scaleEffect(isPressed ? 0.92 : 1.0)
        .offset(y: isPressed ? 1 : 0)
        .animation(.spring(response: 0.13, dampingFraction: 0.65), value: isPressed)
        .contentShape(Rectangle())
        .accessibilityLabel(definition.accessibilityLabel)
        .accessibilityHint(definition.accessibilityHint ?? "")
        .gesture(keyGesture)
    }

    // MARK: - Key Content

    @ViewBuilder
    private func keyContent(isSpecial: Bool) -> some View {
        switch definition.action {
        case .backspace:
            Image(systemName: "delete.backward")
                .font(.system(size: 17, weight: .regular))
        case .shift:
            shiftIcon
        case .capsLock:
            Image(systemName: "capslock.fill")
                .font(.system(size: 16, weight: .medium))
        case .return:
            Image(systemName: "return")
                .font(.system(size: 16, weight: .regular))
        case .nextKeyboard:
            Image(systemName: "globe")
                .font(.system(size: 18, weight: .regular))
        case .numbers:
            Text("123")
                .font(Font.system(size: 15, weight: .medium, design: .rounded))
        case .symbols:
            Text("#+")
                .font(Font.system(size: 15, weight: .medium, design: .rounded))
        case .alphabet:
            Text("ABC")
                .font(Font.system(size: 15, weight: .medium, design: .rounded))
        case .dismissKeyboard:
            Image(systemName: "keyboard.chevron.compact.down")
                .font(.system(size: 16, weight: .regular))
        case .emoji:
            Image(systemName: "face.smiling")
                .font(.system(size: 18, weight: .regular))
        case .clipboard:
            Image(systemName: "doc.on.clipboard")
                .font(.system(size: 16, weight: .regular))
        case .dictation:
            Image(systemName: "mic")
                .font(.system(size: 18, weight: .regular))
        case .openSettings:
            Image(systemName: "gearshape.fill")
                .font(.system(size: 17, weight: .medium))
        case .space:
            // Keyboat brand name on spacebar
            Text("keyboat")
                .font(Font.system(size: 14, weight: .medium, design: .rounded))
                .tracking(1.5)
        default:
            Text(displayLabel)
                .font(keyFont)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
        }
    }

    // MARK: - Shift Icon

    @ViewBuilder
    private var shiftIcon: some View {
        let locked = shiftState == .locked
        let active = shiftState != .off
        Image(systemName: locked ? "capslock.fill" : (active ? "shift.fill" : "shift"))
            .font(.system(size: 17, weight: active ? .semibold : .regular))
            .foregroundStyle(
                active
                ? AnyShapeStyle(Color(token: theme.accentColor))
                : AnyShapeStyle(Color(token: theme.specialKeyForeground))
            )
    }

    // MARK: - Gradients & Colors

    private func keyGradient(isSpecial: Bool, isSpace: Bool) -> LinearGradient {
        if isSpecial && !isSpace {
            return LinearGradient(
                colors: [
                    Color(token: theme.specialKeyBackground).opacity(1.0),
                    Color(token: theme.specialKeyBackground).opacity(0.82)
                ],
                startPoint: .top, endPoint: .bottom
            )
        }
        return LinearGradient(
            colors: [
                Color(token: theme.keyBackground).opacity(1.0),
                Color(token: theme.keyBackground).opacity(0.78)
            ],
            startPoint: .top, endPoint: .bottom
        )
    }

    private var glossOverlay: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(0.18),
                Color.white.opacity(0.0)
            ],
            startPoint: .top, endPoint: .center
        )
    }

    private func keyForeground(isSpecial: Bool, isSpace: Bool) -> AnyShapeStyle {
        if isSpace {
            return AnyShapeStyle(Color(token: theme.spaceKeyForeground).opacity(0.8))
        }
        if isSpecial {
            return AnyShapeStyle(Color(token: theme.specialKeyForeground))
        }
        return AnyShapeStyle(Color(token: theme.keyForeground))
    }

    private func borderColor(isSpecial: Bool) -> Color {
        if isSpecial {
            return Color.white.opacity(0.07)
        }
        return Color.white.opacity(0.12)
    }

    // MARK: - Label

    private var displayLabel: String {
        guard case .character(let s) = definition.action else {
            return definition.label
        }
        switch shiftState {
        case .once, .locked: return s.uppercased()
        case .off:           return s.lowercased()
        }
    }

    private var keyFont: Font {
        let ft = definition.isSpecialKey ? theme.specialKeyFont : theme.keyFont
        return Font.system(size: ft.size, weight: ft.weight.swiftUIWeight, design: .rounded)
    }

    // MARK: - Gesture

    private var keyGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { _ in
                if !isPressed {
                    isPressed = true
                    fireHaptic()
                }
            }
            .onEnded { _ in
                isPressed = false
                onAction(definition.action.toKeyAction())
            }
    }

    // MARK: - Haptics

    @MainActor
    private func fireHaptic() {
        let engine = HapticEngine.shared
        switch definition.action {
        case .backspace:         engine.deleteKeyTap()
        case .return:            engine.returnKeyTap()
        case .shift, .capsLock,
             .numbers, .symbols,
             .alphabet:          engine.specialKeyTap()
        default:                 engine.keyTap()
        }
    }
}

// MARK: - KeyDefinition helpers

extension KeyDefinition {
    var isSpecialKey: Bool {
        switch action {
        case .character: return false
        case .space:     return false
        default:         return true
        }
    }
}

// MARK: - FontWeightToken → SwiftUI.Font.Weight

extension FontWeightToken {
    var swiftUIWeight: Font.Weight {
        switch self {
        case .ultraLight: return .ultraLight
        case .thin:       return .thin
        case .light:      return .light
        case .regular:    return .regular
        case .medium:     return .medium
        case .semibold:   return .semibold
        case .bold:       return .bold
        case .heavy:      return .heavy
        case .black:      return .black
        }
    }
}

// MARK: - EncodableKeyAction Equatable helper

extension EncodableKeyAction: @retroactive Equatable {
    public static func == (lhs: EncodableKeyAction, rhs: EncodableKeyAction) -> Bool {
        switch (lhs, rhs) {
        case (.space, .space), (.return, .return), (.tab, .tab),
             (.backspace, .backspace), (.shift, .shift), (.capsLock, .capsLock),
             (.numbers, .numbers), (.symbols, .symbols), (.alphabet, .alphabet),
             (.nextKeyboard, .nextKeyboard), (.dismissKeyboard, .dismissKeyboard),
             (.clipboard, .clipboard), (.emoji, .emoji), (.dictation, .dictation),
             (.openSettings, .openSettings):
            return true
        case (.character(let a), .character(let b)): return a == b
        default: return false
        }
    }
}
