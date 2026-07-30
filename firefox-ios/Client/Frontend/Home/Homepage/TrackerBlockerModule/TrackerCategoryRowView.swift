// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

/// A single row in the tracker categories card: a leading icon placeholder, a title, an optional progress bar
/// and an optional trailing count. The bar and count are hidden in the sheet's empty state.
final class TrackerCategoryRowView: UIView, ThemeApplicable {
    private struct UX {
        static let iconSize: CGFloat = 24
        static let horizontalSpacing: CGFloat = 12
        static let verticalSpacing: CGFloat = 6
        static let verticalPadding: CGFloat = 12
        static let iconCornerRadius: CGFloat = 6
    }

    // Placeholder for the per-category icon (real icons are added separately).
    private let iconPlaceholder: UIView = .build { view in
        view.layer.cornerRadius = UX.iconCornerRadius
        view.isAccessibilityElement = false
    }

    private let titleLabel: UILabel = .build { label in
        label.font = FXFontStyles.Regular.subheadline.scaledFont()
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
    }

    private let countLabel: UILabel = .build { label in
        label.font = FXFontStyles.Regular.subheadline.scaledFont()
        label.adjustsFontForContentSizeCategory = true
        label.textAlignment = .right
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    private let progressBar = TrackerBlockerProgressBarView()

    private lazy var textStack: UIStackView = .build { stack in
        stack.axis = .vertical
        stack.spacing = UX.verticalSpacing
        stack.alignment = .fill
    }

    private lazy var contentStack: UIStackView = .build { stack in
        stack.axis = .horizontal
        stack.spacing = UX.horizontalSpacing
        stack.alignment = .center
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        isAccessibilityElement = true
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLayout() {
        progressBar.translatesAutoresizingMaskIntoConstraints = false
        textStack.addArrangedSubview(titleLabel)
        textStack.addArrangedSubview(progressBar)
        textStack.setContentHuggingPriority(.defaultLow, for: .horizontal)

        contentStack.addArrangedSubview(iconPlaceholder)
        contentStack.addArrangedSubview(textStack)
        contentStack.addArrangedSubview(countLabel)
        addSubview(contentStack)

        NSLayoutConstraint.activate([
            iconPlaceholder.widthAnchor.constraint(equalToConstant: UX.iconSize),
            iconPlaceholder.heightAnchor.constraint(equalToConstant: UX.iconSize),

            contentStack.topAnchor.constraint(equalTo: topAnchor, constant: UX.verticalPadding),
            contentStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -UX.verticalPadding),
            contentStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }

    /// - Parameter fillRatio: the category's share of the week's blocked trackers, in `0...1`.
    func configure(with category: TrackerBlockerSheetState.Category, fillRatio: CGFloat, theme: Theme) {
        titleLabel.text = category.title

        if let count = category.count {
            countLabel.text = count.formatted(.number)
            countLabel.isHidden = false
            progressBar.isHidden = false
            progressBar.setFillRatio(fillRatio)
            accessibilityLabel = "\(category.title), \(count) blocked"
        } else {
            countLabel.isHidden = true
            progressBar.isHidden = true
            accessibilityLabel = category.title
        }

        applyTheme(theme: theme)
    }

    func applyTheme(theme: Theme) {
        iconPlaceholder.backgroundColor = theme.colors.layer3
        titleLabel.textColor = theme.colors.textPrimary
        countLabel.textColor = theme.colors.textSecondary
        progressBar.applyTheme(theme: theme)
    }
}
