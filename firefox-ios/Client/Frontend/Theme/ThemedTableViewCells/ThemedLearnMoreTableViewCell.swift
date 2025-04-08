// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit
import ComponentLibrary

class ThemedLearnMoreTableViewCell: ThemedTableViewCell {
    private struct UX {
        static let horizontalMargin: CGFloat = 15
        static let verticalMargin: CGFloat = 10
        static let labelsSpacing: CGFloat = 3
        static let learnMoreInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
    }

    private lazy var labelsStackView: UIStackView = .build { stackView in
        stackView.spacing = UX.labelsSpacing
        stackView.axis = .vertical
    }

    private lazy var titleLabel: UILabel = .build { label in
        label.numberOfLines = 0
        label.textAlignment = .left
        label.font = FXFontStyles.Regular.body.scaledFont()
    }

    private lazy var subtitleLabel: UILabel = .build { label in
        label.numberOfLines = 0
        label.textAlignment = .left
        label.font = FXFontStyles.Regular.caption1.scaledFont()
    }

    public lazy var learnMoreButton: LinkButton = .build { [weak self] button in
        button.addTarget(self, action: #selector(self?.learnMoreTapped), for: .touchUpInside)
    }

    var learnMoreDidTap: (() -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupLayout()
    }

    func configure(title: String, subtitle: String, learnMoreText: String, a11yId: String?, theme: Theme) {
        titleLabel.text = title
        subtitleLabel.text = subtitle
        let learnMoreButtonViewModel = LinkButtonViewModel(
            title: learnMoreText,
            a11yIdentifier: a11yId ?? "",
            font: FXFontStyles.Regular.caption1.scaledFont(),
            contentInsets: UX.learnMoreInsets
        )
        learnMoreButton.configure(viewModel: learnMoreButtonViewModel)
    }

    func setAccessibilities(traits: UIAccessibilityTraits, identifier: String) {
        accessibilityTraits = traits
        accessibilityIdentifier = identifier
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLayout() {
        separatorInset = .zero
        selectionStyle = .none
        contentView.addSubview(labelsStackView)
        contentView.addSubview(learnMoreButton)
        labelsStackView.addArrangedSubview(titleLabel)
        labelsStackView.addArrangedSubview(subtitleLabel)

        let bottomConstraint = learnMoreButton.bottomAnchor.constraint(
            equalTo: contentView.bottomAnchor,
            constant: -UX.verticalMargin
        )
        bottomConstraint.priority = .defaultLow

        NSLayoutConstraint.activate([
            labelsStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: UX.verticalMargin),
            labelsStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: UX.horizontalMargin),
            labelsStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -UX.horizontalMargin),

            learnMoreButton.topAnchor.constraint(equalTo: labelsStackView.bottomAnchor, constant: UX.labelsSpacing),
            learnMoreButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: UX.horizontalMargin),
            bottomConstraint,
            learnMoreButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -UX.horizontalMargin)
        ])
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = nil
        subtitleLabel.text = nil
        learnMoreButton.titleLabel?.text = nil
        setupLayout()
    }

    @objc
    private func learnMoreTapped() {
        learnMoreDidTap?()
    }

    override func applyTheme(theme: Theme) {
        super.applyTheme(theme: theme)
        titleLabel.textColor = theme.colors.textPrimary
        subtitleLabel.textColor = theme.colors.textSecondary
        learnMoreButton.applyTheme(theme: theme)
    }
}
