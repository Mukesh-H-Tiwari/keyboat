// KeyboardRowView.swift — Keyboat
// Renders a single RowDefinition — a horizontal line of KeyViews.

import SwiftUI
import KeyboatCore

struct KeyboardRowView: View {

    let row: RowDefinition
    let theme: Theme
    let shiftState: ShiftState
    let containerWidth: CGFloat
    let onAction: (KeyAction) -> Void

    var body: some View {
        let spacing: CGFloat = 6
        let totalWidth = max(100, containerWidth)

        // Exact standard 10-key unit width (QWERTY top row)
        // e.g. on 393pt screen with 6pt side margins & 6pt key spacing: (381 - 54) / 10 = 32.7pt
        let sideMargin: CGFloat = 6
        let usableWidth = totalWidth - (sideMargin * 2)
        let stdKeyWidth = (usableWidth - (9 * spacing)) / 10.0

        let keyWidths: [CGFloat] = row.keys.map { key in
            key.widthFactor * stdKeyWidth
        }

        let edgeInset = row.edgeSpacingFactor * stdKeyWidth

        HStack(spacing: spacing) {
            if edgeInset > 0.5 {
                Color.clear.frame(width: edgeInset, height: max(1, theme.keyHeight))
            }

            ForEach(Array(row.keys.enumerated()), id: \.element.id) { idx, key in
                KeyView(
                    definition: key,
                    theme: theme,
                    shiftState: shiftState,
                    onAction: onAction
                )
                .frame(width: keyWidths[idx], height: max(1, theme.keyHeight))
            }

            if edgeInset > 0.5 {
                Color.clear.frame(width: edgeInset, height: max(1, theme.keyHeight))
            }
        }
        .frame(width: totalWidth, height: max(1, theme.keyHeight))
    }
}

// MARK: - BottomRowView

struct BottomRowView: View {

    let bottom: BottomRowDefinition
    let theme: Theme
    let shiftState: ShiftState
    let containerWidth: CGFloat
    let onAction: (KeyAction) -> Void

    var body: some View {
        let spacing: CGFloat = 6
        let totalWidth = max(100, containerWidth)

        let sideMargin: CGFloat = 6
        let usableWidth = totalWidth - (sideMargin * 2)
        let stdKeyWidth = (usableWidth - (9 * spacing)) / 10.0

        let allKeys = bottom.leftKeys + [bottom.spaceKey] + bottom.rightKeys

        let keyWidths: [CGFloat] = allKeys.map { key in
            key.widthFactor * stdKeyWidth
        }

        HStack(spacing: spacing) {
            ForEach(Array(allKeys.enumerated()), id: \.element.id) { idx, key in
                KeyView(definition: key, theme: theme, shiftState: shiftState, onAction: onAction)
                    .frame(width: keyWidths[idx], height: max(1, theme.keyHeight))
            }
        }
        .frame(width: totalWidth, height: max(1, theme.keyHeight))
    }
}
