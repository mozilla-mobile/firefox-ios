// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

/// A single row in the tracker categories card: a leading icon placeholder with the title beside it, and
/// underneath, a progress bar with the blocked count inline at its trailing edge. The bar and count are hidden
/// in the sheet's empty state, where there is no count to show.
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

    /// Holds the progress bar and the count on one line. Centre alignment sits the short bar against the middle
    /// of the taller count label, and makes the stack's height the count's height.
    private lazy var detailStack: UIStackView = .build { stack in
        stack.axis = .horizontal
        stack.spacing = UX.horizontalSpacing
        stack.alignment = .center
    }

    /// The row's height comes from the detail stack when it is visible and from the title when it is not,
    /// so the two are swapped in `setDetailsVisible(_:)`.
    private var bottomWithDetails: NSLayoutConstraint?
    private var bottomWithoutDetails: NSLayoutConstraint?

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
        detailStack.addArrangedSubview(progressBar)
        detailStack.addArrangedSubview(countLabel)

        addSubview(iconPlaceholder)
        addSubview(titleLabel)
        addSubview(detailStack)

        let bottomWithDetails = bottomAnchor.constraint(equalTo: detailStack.bottomAnchor,
                                                        constant: UX.verticalPadding)
        // Not required: with only the title to measure, a short title would pull the row's bottom above the
        // icon and clash with the icon's padding constraint below.
        let bottomWithoutDetails = bottomAnchor.constraint(equalTo: titleLabel.bottomAnchor,
                                                           constant: UX.verticalPadding).priority(.defaultHigh)
        self.bottomWithDetails = bottomWithDetails
        self.bottomWithoutDetails = bottomWithoutDetails

        NSLayoutConstraint.activate([
            iconPlaceholder.widthAnchor.constraint(equalToConstant: UX.iconSize),
            iconPlaceholder.heightAnchor.constraint(equalToConstant: UX.iconSize),
            iconPlaceholder.leadingAnchor.constraint(equalTo: leadingAnchor),
            // The icon tracks the title's centre rather than the row's, so it stays aligned with the text
            // as the title grows to multiple lines.
            iconPlaceholder.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            // The icon is taller than a single line of text, so keep it inside the row's padding.
            iconPlaceholder.topAnchor.constraint(greaterThanOrEqualTo: topAnchor, constant: UX.verticalPadding),
            bottomAnchor.constraint(greaterThanOrEqualTo: iconPlaceholder.bottomAnchor,
                                    constant: UX.verticalPadding),

            titleLabel.topAnchor.constraint(equalTo: topAnchor,
                                            constant: UX.verticalPadding).priority(.defaultHigh),
            titleLabel.leadingAnchor.constraint(equalTo: iconPlaceholder.trailingAnchor,
                                                constant: UX.horizontalSpacing),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),

            detailStack.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: UX.verticalSpacing),
            detailStack.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            detailStack.trailingAnchor.constraint(equalTo: trailingAnchor),

            bottomWithDetails
        ])
    }

    /// Shows or hides the progress bar and count together; the empty state shows the title on its own.
    /// The detail stack isn't itself in a stack, so hiding it leaves its constraints in place and the row's
    /// bottom has to be moved up to the title explicitly.
    private func setDetailsVisible(_ isVisible: Bool) {
        detailStack.isHidden = !isVisible
        // Deactivate first so the two bottom constraints never conflict mid-swap.
        if isVisible {
            bottomWithoutDetails?.isActive = false
            bottomWithDetails?.isActive = true
        } else {
            bottomWithDetails?.isActive = false
            bottomWithoutDetails?.isActive = true
        }
    }

    /// - Parameter fillRatio: the category's share of the week's blocked trackers, in `0...1`.
    func configure(with category: TrackerBlockerSheetState.Category, fillRatio: CGFloat, theme: Theme) {
        titleLabel.text = category.title

        if let count = category.count {
            countLabel.text = count.formatted(.number)
            setDetailsVisible(true)
            progressBar.setFillRatio(fillRatio)
            accessibilityLabel = "\(category.title), \(count) blocked"
        } else {
            setDetailsVisible(false)
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
