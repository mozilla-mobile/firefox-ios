// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import ComponentLibrary
import UIKit
import Shared
import Redux

class SearchEngineSelectionViewController: UIViewController,
                                           BottomSheetChild,
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
    // FXIOS-10192 This button is a temporary placeholder for setting up the navigation / coordinators
    private lazy var placeholderOpenSettingsButton: UIButton = .build { view in
        view.setTitle(.UnifiedSearch.SearchEngineSelection.SearchSettings, for: .normal)
        view.setTitleColor(.blue, for: .normal)
        view.titleLabel?.numberOfLines = 0
        view.titleLabel?.textAlignment = .center
        view.addTarget(self, action: #selector(self.didTapOpenSettings), for: .touchUpInside)
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

        NSLayoutConstraint.activate([
            placeholderOpenSettingsButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 80),
            placeholderOpenSettingsButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            placeholderOpenSettingsButton.widthAnchor.constraint(equalToConstant: 200)
        ])
    }

    // MARK: - Theme

    func applyTheme() {
        let theme = themeManager.getCurrentTheme(for: windowUUID)
        view.backgroundColor = theme.colors.layer3
    }

    // MARK: - Navigation

    @objc
    func didTapOpenSettings(sender: UIButton) {
        coordinator?.navigateToSearchSettings(animated: true)
    }

    func willDismiss() {
        // TODO
    }
}
