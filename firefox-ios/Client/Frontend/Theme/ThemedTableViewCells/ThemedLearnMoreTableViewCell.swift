// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

class ThemedLearnMoreTableViewCell: ThemedTableViewCell {
    private struct UX {
        static let horizontalMargin: CGFloat = 15
        static let verticalMargin: CGFloat = 10
        static let labelsSpacing: CGFloat = 3
        static let negativeLabelsSpacing: CGFloat = -5
        static let minimumHeight: CGFloat = 44
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

    public lazy var learnMoreButton: UIButton = .build { [weak self] button in
        button.addTarget(self, action: #selector(self?.learnMoreTapped), for: .touchUpInside)
        button.titleLabel?.font = FXFontStyles.Regular.caption1.scaledFont()
        button.contentHorizontalAlignment = .leading
        button.titleLabel?.numberOfLines = 0
        button.titleLabel?.translatesAutoresizingMaskIntoConstraints = false
        button.titleLabel?.lineBreakMode = .byWordWrapping
    }

    var learnMoreDidTap: (() -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupLayout()
    }

    func configure(title: String, subtitle: String, learnMoreText: String, theme: Theme) {
        titleLabel.text = title
        subtitleLabel.text = subtitle
        learnMoreButton.setTitle(learnMoreText, for: .normal)
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
        let isAccessibilityCategory = UIApplication.shared.preferredContentSizeCategory.isAccessibilityCategory
        let learnMoreButtonBottomMargin = isAccessibilityCategory ? -UX.verticalMargin : 0
        NSLayoutConstraint.activate([
            labelsStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: UX.verticalMargin),
            labelsStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: UX.horizontalMargin),
            labelsStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -UX.horizontalMargin),

            learnMoreButton.topAnchor.constraint(equalTo: labelsStackView.bottomAnchor, constant: UX.labelsSpacing),
            learnMoreButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: UX.horizontalMargin),
            learnMoreButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor,
                                                    constant: learnMoreButtonBottomMargin),
            learnMoreButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -UX.horizontalMargin),
            learnMoreButton.heightAnchor.constraint(greaterThanOrEqualToConstant: UX.minimumHeight)
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
        learnMoreButton.setTitleColor(theme.colors.textAccent, for: .normal)
    }
}
