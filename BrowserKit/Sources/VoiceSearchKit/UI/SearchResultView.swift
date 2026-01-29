// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

final class SearchResultView: UIView, ThemeApplicable {
    private struct UX {
        static let bodyLabelTopPadding: CGFloat = 12.0
    }

    private let titleLabel: UILabel = .build {
        $0.font = FXFontStyles.Bold.title2.scaledFont()
        $0.numberOfLines = 0
    }
    private let bodyLabel: UILabel = .build {
        $0.font = FXFontStyles.Regular.title2.scaledFont()
        $0.numberOfLines = 0
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupSubviews() {
        addSubviews(titleLabel, bodyLabel)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),

            bodyLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: UX.bodyLabelTopPadding),
            bodyLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            bodyLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
    }

    func configure(title: String, body: String, url: URL? = nil) {
        titleLabel.text = title
        bodyLabel.text = body
    }
    
    // MARK: - ThemeApplicable
    func applyTheme(theme: any Theme) {
        titleLabel.textColor = theme.colors.textPrimary
        bodyLabel.textColor = theme.colors.textSecondary
    }
}
