// KeyboardViewController.swift — Keyboat
// The root UIInputViewController for the keyboard extension.
// UIKit integration layer only — all business logic lives in KeyboatCore.

import UIKit
import SwiftUI
import KeyboatCore
import os

// MARK: - KeyboardViewController

@MainActor
final class KeyboardViewController: UIInputViewController {

    // MARK: Core services
    private var inputEngine: InputEngine!
    private var themeEngine: ThemeEngine!
    private var prefs: PreferencesStore!
    private var clipboardStore: ClipboardStore!
    private var lexiconService: LexiconService!
    private var predictionEngine: (any PredictionEngineProtocol)!

    // MARK: Hosting
    private var hostingController: UIHostingController<KeyboardRootView>?

    // MARK: Logging
    private let logger = Logger(subsystem: "com.mukeshtiwari.keyboat", category: "KeyboardVC")

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        logger.debug("viewDidLoad")

        _ = AppGroup.defaults
        inputEngine = InputEngine()
        themeEngine = ThemeEngine.shared
        prefs = PreferencesStore.shared
        clipboardStore = ClipboardStore.shared
        lexiconService = LexiconService.shared
        predictionEngine = LexiconPredictionEngine()

        setupInputProxy()
        mountKeyboardView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        prefs.reloadFromDefaults()
        themeEngine.reloadCustomThemes()
        themeEngine.activate(themeID: prefs.themeID)
        HapticEngine.shared.prepare()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    private var heightConstraint: NSLayoutConstraint?

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        hostingController?.view.frame = view.bounds
    }

    override func updateViewConstraints() {
        super.updateViewConstraints()
        if heightConstraint == nil {
            let constraint = view.heightAnchor.constraint(equalToConstant: 260)
            constraint.priority = UILayoutPriority(999)
            constraint.isActive = true
            heightConstraint = constraint
        }
    }

    override func textDidChange(_ textInput: (any UITextInput)?) {
        super.textDidChange(textInput)
        prefs.reloadFromDefaults()
        themeEngine.activate(themeID: prefs.themeID)
        // Auto-capitalise: if the proxy says we're at sentence start, engage shift
        updateShiftForContext()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        prefs.reloadFromDefaults()
        themeEngine.activate(themeID: prefs.themeID)
    }

    // MARK: - Setup

    private func setupInputProxy() {}

    private func mountKeyboardView() {
        let proxy = UITextDocumentProxyWrapper(proxy: textDocumentProxy)

        let rootView = KeyboardRootView(
            inputEngine:     inputEngine,
            themeEngine:     themeEngine,
            prefs:           prefs,
            clipboardStore:  clipboardStore,
            predictionEngine: predictionEngine,
            proxy:           proxy,
            onAction:        { [weak self] action in self?.handle(action: action, proxy: proxy) }
        )

        let hosting = UIHostingController(rootView: rootView)
        hosting.view.backgroundColor = .clear
        hosting.view.translatesAutoresizingMaskIntoConstraints = false

        addChild(hosting)
        view.addSubview(hosting.view)
        NSLayoutConstraint.activate([
            hosting.view.topAnchor.constraint(equalTo: view.topAnchor),
            hosting.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hosting.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hosting.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        hosting.didMove(toParent: self)
        hostingController = hosting
    }

    // MARK: - Action dispatch

    private func handle(action: KeyAction, proxy: UITextDocumentProxyWrapper) {
        switch action {
        case .nextKeyboard:
            advanceToNextInputMode()

        case .dismissKeyboard:
            dismissKeyboard()

        case .openSettings:
            openApp()

        default:
            inputEngine.handle(action, proxy: proxy)
            updateShiftForContext()
        }
    }

    // MARK: - Open Container App

    private func openApp() {
        guard let url = URL(string: "keyboat://settings") else { return }
        var responder: UIResponder? = self
        while responder != nil {
            if let application = responder as? UIApplication {
                application.open(url)
                return
            }
            responder = responder?.next
        }
    }

    // MARK: - Auto-capitalisation

    private func updateShiftForContext() {
        guard inputEngine.shiftState != .locked else { return }
        let before = textDocumentProxy.documentContextBeforeInput ?? ""
        let isAtSentenceStart = before.isEmpty
            || before.hasSuffix(". ")
            || before.hasSuffix("! ")
            || before.hasSuffix("? ")
            || before.hasSuffix("\n")
        if isAtSentenceStart && inputEngine.shiftState == .off {
            inputEngine.handle(.shift, proxy: UITextDocumentProxyWrapper(proxy: textDocumentProxy))
        }
    }
}

// MARK: - UITextDocumentProxyWrapper

/// Bridges UIKit's UITextDocumentProxy to our KeyboatCore TextProxyProtocol.
/// Lives in the extension target (UIKit available here).
@MainActor
final class UITextDocumentProxyWrapper: TextProxyProtocol {

    private let proxy: UITextDocumentProxy

    init(proxy: UITextDocumentProxy) {
        self.proxy = proxy
    }

    var documentContextBeforeInput: String? { proxy.documentContextBeforeInput }
    var documentContextAfterInput: String?  { proxy.documentContextAfterInput  }
    var selectedText: String?               { proxy.selectedText               }
    var hasText: Bool                       { proxy.hasText                    }

    var documentInputMode: DocumentInputMode? {
        switch proxy.keyboardType {
        case .emailAddress: return .email
        case .URL:          return .url
        case .numberPad, .decimalPad: return .number
        case .phonePad:     return .phone
        case .webSearch:    return .search
        default:            return .text
        }
    }

    var keyboardType: KeyboardTypeHint {
        switch proxy.keyboardType {
        case .default:       return .default
        case .emailAddress:  return .emailAddress
        case .URL:           return .url
        case .numberPad:     return .numberPad
        case .phonePad:      return .phonePad
        case .decimalPad:    return .decimalPad
        case .webSearch:     return .webSearch
        default:             return .default
        }
    }

    var returnKeyType: ReturnKeyHint { .default }
    var autocorrectionType: AutocorrectionHint { .default }

    func insertText(_ text: String)                    { proxy.insertText(text)                          }
    func deleteBackward()                              { proxy.deleteBackward()                          }
    func adjustTextPosition(byCharacterOffset offset: Int) {
        proxy.adjustTextPosition(byCharacterOffset: offset)
    }
}
