// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common
import ComponentLibrary
import Shared

@MainActor
protocol NativeErrorRegularContentViewDelegate: AnyObject {
    func regularContentViewDidTapReload()
}

/// Encapsulates the "no internet / generic error" action area: a single reload button.
/// The parent view controller swaps this view in when the error is *not* a bad-cert error.
final class NativeErrorRegularContentView: UIView, ThemeApplicable {
    weak var delegate: NativeErrorRegularContentViewDelegate?

    private lazy var reloadButton: PrimaryRoundedButton = .build { button in
        button.addTarget(self, action: #selector(self.didTapReload), for: .touchUpInside)
        button.isEnabled = true
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        addSubview(reloadButton)
        NSLayoutConstraint.activate([
            reloadButton.topAnchor.constraint(equalTo: topAnchor),
            reloadButton.leadingAnchor.constraint(equalTo: leadingAnchor),
            reloadButton.trailingAnchor.constraint(equalTo: trailingAnchor),
            reloadButton.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    func configure() {
        let viewModel = PrimaryRoundedButtonViewModel(
            title: .NativeErrorPage.ButtonLabel,
            a11yIdentifier: AccessibilityIdentifiers.NativeErrorPage.reloadButton
        )
        reloadButton.configure(viewModel: viewModel)
    }

    @objc
    private func didTapReload() {
        delegate?.regularContentViewDidTapReload()
    }

    // MARK: - ThemeApplicable

    func applyTheme(theme: any Theme) {
        reloadButton.applyTheme(theme: theme)
    }
}
