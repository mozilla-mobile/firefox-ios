// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import ComponentLibrary
import UIKit
import Shared
import Redux

class SearchEngineSelectionViewController: UIViewController,
                                           UISheetPresentationControllerDelegate,
                                           UIPopoverPresentationControllerDelegate,
                                           Themeable {
    // MARK: - Properties
    var notificationCenter: NotificationProtocol
    var themeManager: ThemeManager
    var themeObserver: NSObjectProtocol?
    var currentWindowUUID: UUID? { return windowUUID }

    weak var coordinator: SearchEngineSelectionCoordinator?
    private let windowUUID: WindowUUID
    private let logger: Logger

    // MARK: - UI/UX elements
    // FXIOS-10192 This button is a temporary placeholder used to set up the navigation / coordinators. Will be removed.
    private lazy var placeholderOpenSettingsButton: UIButton = .build { view in
        view.setTitle(.UnifiedSearch.SearchEngineSelection.SearchSettings, for: .normal)
        view.setTitleColor(.blue, for: .normal)
        view.titleLabel?.numberOfLines = 0
        view.titleLabel?.textAlignment = .center

        view.addTarget(self, action: #selector(self.didTapOpenSettings), for: .touchUpInside)
    }
    // FIXME FXIOS-10189 This will be deleted later.
    private lazy var placeholderSwitchSearchEngineButton: UIButton = .build { view in
        view.setTitle("Test changing search engine", for: .normal)
        view.setTitleColor(.systemPink, for: .normal)
        view.titleLabel?.numberOfLines = 0
        view.titleLabel?.textAlignment = .center

        view.addTarget(self, action: #selector(self.testDidChangeSearchEngine), for: .touchUpInside)
    }

    // MARK: - Initializers and Lifecycle

    init(
        windowUUID: WindowUUID,
        notificationCenter: NotificationProtocol = NotificationCenter.default,
        themeManager: ThemeManager = AppContainer.shared.resolve(),
        logger: Logger = DefaultLogger.shared
    ) {
        self.windowUUID = windowUUID
        self.notificationCenter = notificationCenter
        self.themeManager = themeManager
        self.logger = logger
        super.init(nibName: nil, bundle: nil)

        // TODO Additional setup to come
        // ...
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        sheetPresentationController?.delegate = self // For non-iPad setup
        popoverPresentationController?.delegate = self // For iPad setup

        setupView()
        listenForThemeChange(view)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        applyTheme()
    }

    // MARK: - UI / UX

    private func setupView() {
        view.addSubview(placeholderOpenSettingsButton)
        view.addSubviews(placeholderSwitchSearchEngineButton)

        NSLayoutConstraint.activate([
            placeholderOpenSettingsButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 80),
            placeholderOpenSettingsButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            placeholderOpenSettingsButton.widthAnchor.constraint(equalToConstant: 200),

            placeholderSwitchSearchEngineButton.topAnchor.constraint(equalTo: placeholderOpenSettingsButton.bottomAnchor),
            placeholderSwitchSearchEngineButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
    }

    // MARK: - Theme

    func applyTheme() {
        let theme = themeManager.getCurrentTheme(for: windowUUID)

        view.backgroundColor = theme.colors.layer3
    }

    // MARK: - UISheetPresentationControllerDelegate inheriting UIAdaptivePresentationControllerDelegate

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        coordinator?.dismissModal(animated: true)
    }

    // MARK: - Navigation

    @objc
    func didTapOpenSettings(sender: UIButton) {
        coordinator?.navigateToSearchSettings(animated: true)
    }

    // FIXME FXIOS-10189 This will be deleted later.
    @objc
    func testDidChangeSearchEngine(sender: UIButton) {
        // TODO
    }
}
