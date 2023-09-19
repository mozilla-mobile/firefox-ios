// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import ComponentLibrary
import Common
import UIKit

class ActionFooterViewController: UIViewController, Themeable {
    var themeManager: ThemeManager
    var themeObserver: NSObjectProtocol?
    var notificationCenter: NotificationProtocol = NotificationCenter.default

    private lazy var actionFooterView: ActionFooterView = .build()
    private var viewModel: ActionFooterViewModel

    init(viewModel: ActionFooterViewModel,
         themeManager: ThemeManager = AppContainer.shared.resolve()) {
        self.viewModel = viewModel
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
        actionFooterView.applyTheme(theme: themeManager.currentTheme)
    }

    private func setupView() {
        actionFooterView.configure(viewModel: viewModel)
        view.addSubview(actionFooterView)

        NSLayoutConstraint.activate([
            actionFooterView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            actionFooterView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
            actionFooterView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            actionFooterView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    // MARK: Themeable

    func applyTheme() {
        view.backgroundColor = themeManager.currentTheme.colors.layer1
    }
}
