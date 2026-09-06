// EmojiPanelView.swift — Keyboat
// Emoji selection grid displayed inside the keyboard frame.

import SwiftUI
import KeyboatCore

struct EmojiPanelView: View {

    let theme: Theme
    let onSelectEmoji: (String) -> Void
    let onClose: () -> Void

    @State private var selectedCategory = 0

    private let categories: [(name: String, icon: String, emojis: [String])] = [
        ("Smileys", "face.smiling", [
            "😀", "😃", "😄", "😁", "😆", "😅", "😂", "🤣", "🥹", "😊",
            "😇", "🙂", "🙃", "😉", "😌", "😍", "🥰", "😘", "😗", "😙",
            "😚", "😋", "😛", "😝", "😜", "🤪", "🤨", "🧐", "🤓", "😎",
            "🥸", "🤩", "🥳", "😏", "😒", "😞", "😔", "😟", "😕", "🙁",
            "☹️", "😣", "😖", "😫", "😩", "🥺", "😢", "😭", "😮‍💨", "😤",
            "😠", "😡", "🤬", "🤯", "😳", "🥵", "🥶", "😱", "😨", "😰"
        ]),
        ("Gestures", "hand.thumbsup", [
            "👍", "👎", "👏", "🙌", "👐", "🤲", "🤝", "🙏", "✍️", "💅",
            "🤳", "💪", "🦾", "🦿", "🦵", "🦶", "👂", "🦻", "👃", "🫀",
            "🫁", "🧠", "🗣️", "👤", "👥", "🫂", "👶", "👧", "🧒", "👦",
            "👩", "🧑", "👨", "👩‍🦱", "🧑‍🦱", "👨‍🦱", "👩‍🦰", "🧑‍🦰", "👨‍🦰", "👱‍♀️"
        ]),
        ("Animals", "leaf", [
            "🐶", "🐱", "🐭", "🐹", "🐰", "🦊", "🐻", "🐼", "🐻‍❄️", "🐨",
            "🐯", "🦁", "🐮", "🐷", "🐽", "🐸", "🐵", "🙈", "🙉", "🙊",
            "🐒", "🐔", "🐧", "🐦", "🐤", "🐣", "🐥", "🦆", "🦅", "🦉",
            "🦇", "🐺", "🐗", "🐴", "🦄", "🐝", "🪱", "🐛", "🦋", "🐌"
        ]),
        ("Food", "cup.and.saucer", [
            "🍏", "🍎", "🍐", "🍊", "🍋", "🍌", "🍉", "🍇", "🍓", "🫐",
            "🍈", "🍒", "🍑", "🥭", "🍍", "🥥", "🥝", "🍅", "🍆", "🥑",
            "🥦", "🥬", "🥒", "🌶️", "🫑", "🌽", "🥕", "🫒", "🧄", "🧅",
            "🥔", "🍠", "🥐", "🥯", "🍞", "🥖", "🥨", "🧀", "🥚", "🍳"
        ]),
        ("Activities", "basketball", [
            "⚽️", "🏀", "🏈", "⚾️", "🥎", "🎾", "🏐", "🏉", "🥏", "🎱",
            "🪀", "🏓", "🏸", "🏒", "🏑", "🥍", "🏏", "🪃", "🥅", "⛳️",
            "🪁", "🏹", "🎣", "🤿", "🥊", "🥋", "🎽", "🛹", "🛼", "🛷",
            "⛸️", "🥌", "🎿", "⛷️", "🏂", "🪂", "🏋️‍♀️", "🏋️", "🏋️‍♂️", "🤼‍♀️"
        ]),
        ("Objects", "lightbulb", [
            "💡", "flashlight.on.fill", "candle.fill", "fire.hydrant", "barrel.fill", "dollarsign.circle", "banknote", "creditcard", "gem", "scales",
            "hammer", "wrench", "screwdriver", "gear", "link", "magnet", "key", "lock", "scissors", "bell"
        ]),
        ("Symbols", "heart", [
            "❤️", "🧡", "💛", "💚", "💙", "💜", "🖤", "🤍", "🤎", "💔",
            "❣️", "💕", "💞", "💓", "💗", "💖", "💘", "💝", "💟", "☮️",
            "✝️", "☪️", "🕉️", "☸️", "✡️", "🔯", "🕎", "☯️", "☦️", "🛐"
        ])
    ]

    private let columns = [
        GridItem(.adaptive(minimum: 38, maximum: 46), spacing: 4)
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Category Selector Header
            HStack(spacing: 12) {
                ForEach(0..<categories.count, id: \.self) { idx in
                    Button {
                        selectedCategory = idx
                    } label: {
                        Image(systemName: categories[idx].icon)
                            .font(.system(size: 16, weight: selectedCategory == idx ? .bold : .regular))
                            .foregroundColor(selectedCategory == idx ? Color(token: theme.accentColor) : Color(token: theme.specialKeyForeground).opacity(0.6))
                    }
                    .buttonStyle(.plain)
                }

                Spacer()

                Button {
                    onClose()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Color(token: theme.specialKeyForeground))
                        .font(.system(size: 18))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(token: theme.clipboardBackground))

            Divider().background(Color(token: theme.suggestionDividerColor))

            // Emoji Grid
            ScrollView(.vertical, showsIndicators: false) {
                LazyVGrid(columns: columns, spacing: 6) {
                    ForEach(categories[selectedCategory].emojis, id: \.self) { emoji in
                        Button {
                            onSelectEmoji(emoji)
                        } label: {
                            Text(emoji)
                                .font(.system(size: 24))
                                .frame(width: 40, height: 40)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(8)
            }
        }
        .background(Color(token: theme.keyboardBackground))
    }
}
