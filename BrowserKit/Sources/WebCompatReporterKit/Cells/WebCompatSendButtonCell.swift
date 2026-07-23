// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import ComponentLibrary
import UIKit

final class WebCompatSendButtonCell: UICollectionViewListCell, ThemeApplicable, ReusableCell {
    private var tapHandler: (() -> Void)?

    private lazy var button: PrimaryRoundedButton = .build { button in
        button.addTarget(self, action: #selector(self.didTap), for: .touchUpInside)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLayout() {
        backgroundConfiguration = UIBackgroundConfiguration.clear()
        contentView.addSubview(button)
        NSLayoutConstraint.activate([
            button.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            button.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            button.topAnchor.constraint(equalTo: contentView.topAnchor),
            button.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }

    func configure(title: String, isEnabled: Bool, a11yIdentifier: String, onTap: @escaping () -> Void) {
        tapHandler = onTap
        button.configure(
            viewModel: PrimaryRoundedButtonViewModel(title: title, a11yIdentifier: a11yIdentifier)
        )
        button.isEnabled = isEnabled
    }

    // MARK: - ThemeApplicable

    func applyTheme(theme: Theme) {
        button.applyTheme(theme: theme)
    }

    @objc
    private func didTap() {
        tapHandler?()
    }
}
