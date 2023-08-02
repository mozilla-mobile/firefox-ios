// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import ComponentLibrary
import UIKit

class FakespotBottomSheetChildViewController: UIViewController, BottomSheetChild, Themeable {
    private struct UX {
        static let topPadding: CGFloat = 16
        static let bottomPadding: CGFloat = 40
        static let horizontalPadding: CGFloat = 16
    }

    var notificationCenter: NotificationProtocol
    var themeManager: ThemeManager
    var themeObserver: NSObjectProtocol?

    private lazy var contentView: UIView = .build { _ in }

    // MARK: - Initializers
    init(notificationCenter: NotificationProtocol = NotificationCenter.default,
         themeManager: ThemeManager = AppContainer.shared.resolve()) {
        self.notificationCenter = notificationCenter
        self.themeManager = themeManager
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View setup & lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        listenForThemeChange(view)
        applyTheme()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        applyTheme()
    }

    func applyTheme() {
    }

    private func setupView() {
        view.addSubview(contentView)

        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: view.topAnchor, constant: UX.topPadding),
            contentView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: UX.horizontalPadding),
            contentView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -UX.bottomPadding),
            contentView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -UX.horizontalPadding),
        ])
    }

    private func recordTelemetry() {
        TelemetryWrapper.recordEvent(category: .action,
                                     method: .close,
                                     object: .shoppingBottomSheet)
    }

    // MARK: BottomSheetChild
    func willDismiss() {
        recordTelemetry()
    }
}
