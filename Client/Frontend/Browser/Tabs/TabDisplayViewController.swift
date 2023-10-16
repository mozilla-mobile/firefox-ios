// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

class TabDisplayViewController: UIViewController,
                                Themeable,
                                EmptyPrivateTabsViewDelegate {
    var notificationCenter: NotificationProtocol
    var themeManager: ThemeManager
    var themeObserver: NSObjectProtocol?

    // MARK: UI elements
    private var tabDisplayView: TabDisplayView = .build { _ in }
    private var backgroundPrivacyOverlay: UIView = .build { _ in }
    private lazy var emptyPrivateTabsView: EmptyPrivateTabsView = .build { _ in }

    // MARK: Redux state
    var state: TabTrayState

    init(isPrivateMode: Bool,
         notificationCenter: NotificationProtocol = NotificationCenter.default,
         themeManager: ThemeManager = AppContainer.shared.resolve()) {
        // TODO: FXIOS-6936 Integrate Redux state
        self.state = TabTrayState(isPrivateMode: isPrivateMode,
                                  isPrivateTabsEmpty: true,
                                  isInactiveTabEmpty: false)
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

    func setupView() {
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

        backgroundPrivacyOverlay.isHidden = !state.isPrivateMode
        setupEmptyView()
    }

    func setupEmptyView() {
        guard state.isPrivateMode, state.isPrivateTabsEmpty else { return }

        view.insertSubview(emptyPrivateTabsView, aboveSubview: tabDisplayView)
        NSLayoutConstraint.activate([
            emptyPrivateTabsView.topAnchor.constraint(equalTo: view.topAnchor),
            emptyPrivateTabsView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            emptyPrivateTabsView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            emptyPrivateTabsView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        emptyPrivateTabsView.isHidden = false
        tabDisplayView.isHidden = true
        backgroundPrivacyOverlay.isHidden = true
    }

    func applyTheme() {
        backgroundPrivacyOverlay.backgroundColor = themeManager.currentTheme.colors.layerScrim
        tabDisplayView.applyTheme(theme: themeManager.currentTheme)
    }

    // MARK: EmptyPrivateTabsViewDelegate
    func didTapLearnMore(urlRequest: URLRequest) {}
}
