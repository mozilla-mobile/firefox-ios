// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

class TabDisplayViewController: UIViewController,
                                   Themeable {
    struct UX {}

    var notificationCenter: NotificationProtocol
    var themeManager: ThemeManager
    var themeObserver: NSObjectProtocol?

    // MARK: UI elements
    private var backgroundPrivacyOverlay: UIView = .build { _ in }
    private var tabDisplayView: TabDisplayView = .build { _ in }

    // Redux state
    var isPrivateMode: Bool

    init(isPrivateMode: Bool,
         notificationCenter: NotificationProtocol = NotificationCenter.default,
         themeManager: ThemeManager = AppContainer.shared.resolve()) {
        self.isPrivateMode = isPrivateMode
        self.notificationCenter = notificationCenter
        self.themeManager = themeManager
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupView()
        listenForThemeChange(view)
        applyTheme()
    }

    private func setupView() {
        view.addSubview(tabDisplayView)
        view.addSubview(backgroundPrivacyOverlay)

        NSLayoutConstraint.activate([
            tabDisplayView.topAnchor.constraint(equalTo: view.topAnchor),
            tabDisplayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tabDisplayView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tabDisplayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            backgroundPrivacyOverlay.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundPrivacyOverlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundPrivacyOverlay.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            backgroundPrivacyOverlay.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        backgroundPrivacyOverlay.isHidden = !isPrivateMode
        // TODO: Empty private tabs view FXIOS-6925
    }

    func applyTheme() {
        backgroundPrivacyOverlay.backgroundColor = themeManager.currentTheme.colors.layerScrim
    }
}
