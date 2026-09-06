// ClipboardBrowserView.swift — Keyboat Container App
// Full-screen clipboard history browser.

import SwiftUI
import KeyboatCore

struct ClipboardBrowserView: View {

    @StateObject private var vm = ClipboardBrowserViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if vm.items.isEmpty {
                    ContentUnavailableView(
                        "No Clipboard History",
                        systemImage: "doc.on.clipboard",
                        description: Text("Items you copy will appear here when Full Access is enabled.")
                    )
                } else {
                    List {
                        if !vm.pinned.isEmpty {
                            Section("Pinned") {
                                ForEach(vm.pinned) { item in
                                    ClipboardBrowserRow(item: item, vm: vm)
                                }
                            }
                        }
                        Section("Recent") {
                            ForEach(vm.recent) { item in
                                ClipboardBrowserRow(item: item, vm: vm)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Clipboard")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Clear All", role: .destructive) {
                        vm.deleteAll()
                    }
                    .disabled(vm.items.isEmpty)
                }
            }
            .onAppear { vm.reload() }
        }
    }
}

// MARK: - ClipboardBrowserRow

struct ClipboardBrowserRow: View {
    let item: ClipboardItem
    @ObservedObject var vm: ClipboardBrowserViewModel

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.type.symbolName)
                .font(.system(size: 16))
                .foregroundColor(.accentColor)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.displayText)
                    .font(.system(size: 15))
                    .lineLimit(2)

                Text(item.createdAt, style: .relative)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            if item.isPinned {
                Image(systemName: "pin.fill")
                    .font(.system(size: 11))
                    .foregroundColor(.accentColor)
            }
        }
        .contextMenu {
            Button("Copy", systemImage: "doc.on.doc") {
                UIPasteboard.general.string = item.text
            }
            Button(item.isPinned ? "Unpin" : "Pin",
                   systemImage: item.isPinned ? "pin.slash" : "pin") {
                vm.togglePin(item)
            }
            Divider()
            Button("Delete", systemImage: "trash", role: .destructive) {
                vm.delete(item)
            }
        }
    }
}

// MARK: - ViewModel

@MainActor
final class ClipboardBrowserViewModel: ObservableObject {
    @Published private(set) var items: [ClipboardItem] = []

    var pinned: [ClipboardItem] { items.filter(\.isPinned) }
    var recent: [ClipboardItem] { items.filter { !$0.isPinned } }

    private let store = ClipboardStore.shared

    func reload() { items = store.allItems() }
    func togglePin(_ item: ClipboardItem) {
        item.isPinned ? store.unpin(item) : store.pin(item)
        reload()
    }
    func delete(_ item: ClipboardItem) { store.delete(id: item.id); reload() }
    func deleteAll() { store.deleteAll(); reload() }
}

#Preview {
    ClipboardBrowserView()
}
