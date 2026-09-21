// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import SwiftUI
import UIKit

/// Homepage cell that holds NotificationCardView.
final class NotificationCardCell: UICollectionViewCell, ReusableCell, ThemeApplicable {
    private var host: UIHostingController<NotificationCardView>?
    private var enableButtonAction: (() -> Void)?
    private var closeButtonAction: (() -> Void)?

    func configure(theme: Theme, enableButtonAction: (() -> Void)?, closeButtonAction: (() -> Void)?) {
        self.enableButtonAction = enableButtonAction
        self.closeButtonAction = closeButtonAction
        embedHostIfNeeded(theme: theme)
        applyTheme(theme: theme)
    }

    // MARK: - Theme
    func applyTheme(theme: Theme) {
        host?.rootView = makeRootView(theme: theme)
    }

    private func embedHostIfNeeded(theme: Theme) {
        guard host == nil else { return }

        let host = UIHostingController(rootView: makeRootView(theme: theme))
        host.view.backgroundColor = .clear
        host.view.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(host.view)
        NSLayoutConstraint.activate([
            host.view.topAnchor.constraint(equalTo: contentView.topAnchor),
            host.view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            host.view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
        self.host = host
    }

    private func makeRootView(theme: Theme) -> NotificationCardView {
        return NotificationCardView(
            theme: theme,
            onEnable: { [weak self] in self?.enableButtonAction?() },
            onClose: { [weak self] in self?.closeButtonAction?() }
        )
    }
}
