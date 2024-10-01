// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

class CertificatesHeaderView: UITableViewHeaderFooterView, ReusableCell {
    private struct UX {
        static let headerStackViewSpacing = 16.0
    }

    let headerStackView: UIStackView = .build { stack in
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.alignment = .fill
        stack.spacing = UX.headerStackViewSpacing
    }

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        setupHeaderView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    private func setupHeaderView() {
        addSubview(headerStackView)
        NSLayoutConstraint.activate([
            self.leadingAnchor.constraint(equalTo: headerStackView.leadingAnchor),
            self.trailingAnchor.constraint(equalTo: headerStackView.trailingAnchor),
            self.topAnchor.constraint(equalTo: headerStackView.topAnchor),
            self.bottomAnchor.constraint(equalTo: headerStackView.bottomAnchor)
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

        headerStackView.backgroundColor = theme.colors.layer5
    }
}
