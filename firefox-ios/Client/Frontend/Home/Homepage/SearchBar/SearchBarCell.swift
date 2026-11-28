// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

class SearchBarCell: UICollectionViewCell, ReusableCell, ThemeApplicable {
    private let sizingView: EmbeddedAddressBarView = .build { view in
        view.isHidden = true
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupAccessibility()
        setupView()
    }

    private func setupAccessibility() {
        isAccessibilityElement = true
        accessibilityIdentifier = AccessibilityIdentifiers.FirefoxHomepage.SearchBar.itemCell
        accessibilityTraits.insert(.button)
        accessibilityLabel = .FirefoxHomepage.SearchBar.PlaceholderTitle
    }

    private func setupView() {
        contentView.addSubview(sizingView)

        NSLayoutConstraint.activate([
            sizingView.topAnchor.constraint(equalTo: contentView.topAnchor),
            sizingView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            sizingView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            sizingView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - ThemeApplicable
    func applyTheme(theme: Theme) {}
}
