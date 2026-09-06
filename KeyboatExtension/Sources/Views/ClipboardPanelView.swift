// ClipboardPanelView.swift — Keyboat
// Clipboard history panel displayed inside the keyboard frame.

import SwiftUI
import KeyboatCore

struct ClipboardPanelView: View {

    let store: any ClipboardServiceProtocol
    let theme: Theme
    let onPaste: (ClipboardItem) -> Void
    let onClose: () -> Void

    @State private var items: [ClipboardItem] = []

    var body: some View {
        VStack(spacing: 0) {

            // Header
            HStack {
                Label("Clipboard", systemImage: "doc.on.clipboard")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color(token: theme.suggestionTextColor))

                Spacer()

                Button {
                    store.deleteAll()
                    loadItems()
                } label: {
                    Text("Clear")
                        .font(.system(size: 13))
                        .foregroundColor(Color(token: theme.accentColor))
                }

                Button {
                    onClose()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Color(token: theme.specialKeyForeground))
                        .font(.system(size: 18))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(token: theme.clipboardBackground))

            Divider().background(Color(token: theme.suggestionDividerColor))

            // Item list
            if items.isEmpty {
                emptyState
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 6) {
                        // Pinned section
                        let pinned = items.filter(\.isPinned)
                        if !pinned.isEmpty {
                            sectionHeader("Pinned")
                            ForEach(pinned) { item in
                                ClipboardItemCell(
                                    item: item, theme: theme,
                                    onPaste:  { onPaste(item) },
                                    onPin:    { togglePin(item) },
                                    onDelete: { deleteItem(item) }
                                )
                            }
                        }

                        // Recent section
                        let recent = items.filter { !$0.isPinned }
                        if !recent.isEmpty {
                            sectionHeader("Recent")
                            ForEach(recent) { item in
                                ClipboardItemCell(
                                    item: item, theme: theme,
                                    onPaste:  { onPaste(item) },
                                    onPin:    { togglePin(item) },
                                    onDelete: { deleteItem(item) }
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.top, 6)
                }
            }
        }
        .background(Color(token: theme.clipboardBackground))
        .onAppear { loadItems() }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "doc.on.clipboard")
                .font(.system(size: 36))
                .foregroundColor(Color(token: theme.specialKeyForeground))
            Text("Nothing copied yet")
                .font(.system(size: 14))
                .foregroundColor(Color(token: theme.suggestionTextColor).opacity(0.6))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Section header

    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Color(token: theme.suggestionTextColor).opacity(0.5))
                .textCase(.uppercase)
            Spacer()
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Actions

    private func loadItems() { items = store.allItems() }
    private func togglePin(_ item: ClipboardItem) {
        item.isPinned ? store.unpin(item) : store.pin(item)
        loadItems()
    }
    private func deleteItem(_ item: ClipboardItem) {
        store.delete(id: item.id)
        loadItems()
    }
}

// MARK: - ClipboardItemCell

struct ClipboardItemCell: View {

    let item: ClipboardItem
    let theme: Theme
    let onPaste: () -> Void
    let onPin: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 8) {

            // Type icon
            Image(systemName: item.type.symbolName)
                .font(.system(size: 14))
                .foregroundColor(Color(token: theme.accentColor))
                .frame(width: 20)

            // Text
            Text(item.displayText)
                .font(.system(size: 14))
                .foregroundColor(Color(token: theme.clipboardItemText))
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Pin badge
            if item.isPinned {
                Image(systemName: "pin.fill")
                    .font(.system(size: 10))
                    .foregroundColor(Color(token: theme.clipboardPinnedBadge))
            }

            // Actions
            Menu {
                Button("Paste", systemImage: "doc.on.clipboard") { onPaste() }
                Button(item.isPinned ? "Unpin" : "Pin",
                       systemImage: item.isPinned ? "pin.slash" : "pin") { onPin() }
                Divider()
                Button("Delete", systemImage: "trash", role: .destructive) { onDelete() }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 14))
                    .foregroundColor(Color(token: theme.specialKeyForeground))
                    .frame(width: 28, height: 28)
                    .contentShape(Rectangle())
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color(token: theme.clipboardItemBackground))
        )
        .contentShape(Rectangle())
        .onTapGesture { onPaste() }
    }
}
