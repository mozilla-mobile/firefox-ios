// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import ComponentLibrary
import UIKit

final class SummaryAnswerCell: UITableViewCell, ReusableCell, ThemeApplicable {
    private enum UX {
        static let horizontalPadding: CGFloat = 24.0
        static let fadeDuration: TimeInterval = 0.3
    }

    private let answerCardView: AIAnswerCardView = .build()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupSubviews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupSubviews() {
        contentView.addSubview(answerCardView)
        NSLayoutConstraint.activate([
            answerCardView.topAnchor.constraint(equalTo: contentView.topAnchor),
            answerCardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor,
                                                    constant: UX.horizontalPadding),
            answerCardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor,
                                                     constant: -UX.horizontalPadding),
            answerCardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }

    func configure(header: String, body: NSAttributedString, headerA11yId: String, bodyA11yId: String) {
        answerCardView.configure(header: header, body: body, headerA11yId: headerA11yId, bodyA11yId: bodyA11yId)
        answerCardView.fadeBodyChange(duration: UX.fadeDuration)
    }

    // MARK: - ThemeApplicable
    func applyTheme(theme: any Theme) {
        answerCardView.applyTheme(theme: theme)
        backgroundColor = .clear
    }
}
