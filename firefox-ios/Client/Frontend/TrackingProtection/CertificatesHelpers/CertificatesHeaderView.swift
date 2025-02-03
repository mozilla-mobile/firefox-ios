// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

class CertificatesHeaderView: UITableViewHeaderFooterView, ReusableCell {
    private struct UX {
        static let headerStackViewSpacing = 16.0
        static let separatorHeight = 1.0
    }

    let headerStackView: UIStackView = .build { stack in
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.alignment = .fill
        stack.spacing = UX.headerStackViewSpacing
    }

    let separatorBottomView: UIView = .build()
    let separatorTopView: UIView = .build()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        setupHeaderView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    private func setupHeaderView() {
        addSubview(headerStackView)
        addSubview(separatorTopView)
        addSubview(separatorBottomView)
        NSLayoutConstraint.activate([
            separatorTopView.leadingAnchor.constraint(equalTo: headerStackView.leadingAnchor),
            separatorTopView.trailingAnchor.constraint(equalTo: headerStackView.trailingAnchor),
            separatorTopView.bottomAnchor.constraint(equalTo: headerStackView.topAnchor,
                                                     constant: -UX.headerStackViewSpacing),
            separatorTopView.heightAnchor.constraint(equalToConstant: UX.separatorHeight),

            self.leadingAnchor.constraint(equalTo: headerStackView.leadingAnchor),
            self.trailingAnchor.constraint(equalTo: headerStackView.trailingAnchor),
            self.topAnchor.constraint(equalTo: separatorTopView.topAnchor, constant: -16),
            self.bottomAnchor.constraint(equalTo: headerStackView.bottomAnchor),

            separatorBottomView.leadingAnchor.constraint(equalTo: headerStackView.leadingAnchor),
            separatorBottomView.trailingAnchor.constraint(equalTo: headerStackView.trailingAnchor),
            separatorBottomView.topAnchor.constraint(equalTo: headerStackView.bottomAnchor),
            separatorBottomView.heightAnchor.constraint(equalToConstant: UX.separatorHeight)
        ])
    }

    func configure(withItems items: [CertificatesHeaderItem], theme: Theme) {
        // Reset the view for reuse
        for view in headerStackView.arrangedSubviews {
            view.removeFromSuperview()
        }

        for item in items {
            headerStackView.addArrangedSubview(item)
        }

        contentView.backgroundColor = theme.colors.layer5
        headerStackView.backgroundColor = theme.colors.layer5
        separatorBottomView.backgroundColor = theme.colors.borderPrimary
        separatorTopView.backgroundColor = theme.colors.borderPrimary
    }

    // MARK: Accessibility
    func setupAccessibilityIdentifiers() {
        typealias A11y = AccessibilityIdentifiers.EnhancedTrackingProtection.DetailsScreen
        headerStackView.accessibilityIdentifier = A11y.tableViewHeader
    }
}
