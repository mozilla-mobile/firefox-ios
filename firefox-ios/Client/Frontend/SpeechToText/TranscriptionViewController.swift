// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common
import ComponentLibrary

final class TranscriptionViewController: UIViewController, Themeable, SpeechRecognizerDelegate {
    private struct UX {
        static let minHeight: CGFloat = 100
        static let spacing: CGFloat = 16
    }

    // MARK: Theme
    var themeManager: ThemeManager
    var themeListenerCancellable: Any?
    var notificationCenter: NotificationProtocol

    // UI
    private var statusLabel: UILabel = .build { view in
        view.font = FXFontStyles.Regular.body.scaledFont()
        view.adjustsFontForContentSizeCategory = true
        view.textAlignment = .center
        view.text = "Transcribing..."
    }
    private lazy var doneButton: PrimaryRoundedButton = .build { button in
        let viewModel = PrimaryRoundedButtonViewModel(
            title: "Done",
            a11yIdentifier: "" // todo
        )
        button.configure(viewModel: viewModel)
        button.addTarget(self, action: #selector(self.buttonPressed), for: .touchUpInside)
    }

    private lazy var speechRecognizer = SpeechRecognizer(delegate: self)

    let windowUUID: WindowUUID
    var currentWindowUUID: UUID? { windowUUID }

    init(themeManager: ThemeManager = AppContainer.shared.resolve(),
         windowUUID: WindowUUID,
         and notificationCenter: NotificationProtocol = NotificationCenter.default) {
        self.themeManager = themeManager
        self.notificationCenter = notificationCenter
        self.windowUUID = windowUUID

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()

        listenForThemeChanges(withNotificationCenter: notificationCenter)
        applyTheme()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        speechRecognizer.resetTranscript()
        speechRecognizer.startTranscribing()
    }

    private func setupView() {
        view.addSubview(statusLabel)
        view.addSubview(doneButton)

        let heightConstraint = statusLabel.heightAnchor.constraint(equalToConstant: UX.minHeight)
        heightConstraint.priority = .required
        heightConstraint.isActive = true

        NSLayoutConstraint.activate([
            statusLabel.topAnchor.constraint(equalTo: view.topAnchor),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            statusLabel.bottomAnchor.constraint(equalTo: doneButton.topAnchor, constant: UX.spacing),

            doneButton.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            doneButton.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            doneButton.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    @objc
    func buttonPressed() {
        speechRecognizer.stopTranscribing()
        dismissVC()
    }

    // MARK: - Themeable

    func applyTheme() {
        let theme = themeManager.getCurrentTheme(for: windowUUID)
        view.backgroundColor = theme.colors.layer1.withAlphaComponent(0.5)
        statusLabel.textColor = theme.colors.textPrimary
    }

    // MARK: - SpeechRecognizerDelegate
    func transcriptDidChange(_ transcript: String) {
        let toolbarAction = ToolbarAction(
            searchTerm: transcript,
            windowUUID: windowUUID,
            actionType: ToolbarActionType.didSetTextInLocationView
        )
        store.dispatchLegacy(toolbarAction)
    }
}
