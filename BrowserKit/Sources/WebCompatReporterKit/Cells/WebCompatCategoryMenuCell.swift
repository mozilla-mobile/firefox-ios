// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

/// Category pull-down row: a full-width button opening a `UIMenu` of categories.
/// Selection is reported through the handler, not stored, so it re-renders on configure.
/// The title sits on a sibling label so the menu morph has nothing visible to animate.
final class WebCompatCategoryMenuCell: UICollectionViewListCell, Notifiable {
    private var selectionHandler: ((String) -> Void)?
    private var chevronSizeConstraints: [NSLayoutConstraint] = []
    private var chevronUpBottomConstraint: NSLayoutConstraint?
    private var chevronDownTopConstraint: NSLayoutConstraint?

    private var scaledChevronSize: CGFloat {
        return UIFontMetrics.default.scaledValue(for: WebCompatReporterUX.Chevron.size)
    }

    private var scaledChevronVerticalOverlap: CGFloat {
        return UIFontMetrics.default.scaledValue(for: WebCompatReporterUX.Chevron.verticalOverlap)
    }

    private let categoryLabel: UILabel = .build { label in
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        label.font = FXFontStyles.Regular.body.scaledFont()
        label.isAccessibilityElement = false
    }

    private let menuButton: WebCompatTrailingMenuButton = .build { button in
        button.showsMenuAsPrimaryAction = true
    }

    private lazy var chevronUpView: UIImageView = {
        let image = UIImage(named: StandardImageIdentifiers.Large.chevronUp)?.withRenderingMode(.alwaysTemplate)
        let imageView = UIImageView(image: image)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = false
        return imageView
    }()

    private lazy var chevronDownView: UIImageView = {
        let image = UIImage(named: StandardImageIdentifiers.Large.chevronDown)?.withRenderingMode(.alwaysTemplate)
        let imageView = UIImageView(image: image)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = false
        return imageView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
        startObservingNotifications(
            withNotificationCenter: NotificationCenter.default,
            forObserver: self,
            observing: [UIContentSizeCategory.didChangeNotification]
        )
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLayout() {
        // The button sits beneath the non-interactive title and chevrons, so any tap opens the menu.
        contentView.addSubviews(menuButton, categoryLabel, chevronUpView, chevronDownView)
        let margins = contentView.layoutMarginsGuide
        chevronSizeConstraints = [
            chevronUpView.widthAnchor.constraint(equalToConstant: scaledChevronSize),
            chevronUpView.heightAnchor.constraint(equalToConstant: scaledChevronSize),
            chevronDownView.widthAnchor.constraint(equalToConstant: scaledChevronSize),
            chevronDownView.heightAnchor.constraint(equalToConstant: scaledChevronSize)
        ]
        // .defaultHigh (not required) avoids the self-sizing vs. min-height constraint conflict.
        let verticalConstraints = [
            menuButton.topAnchor.constraint(equalTo: margins.topAnchor),
            menuButton.bottomAnchor.constraint(equalTo: margins.bottomAnchor),
            categoryLabel.topAnchor.constraint(equalTo: margins.topAnchor),
            categoryLabel.bottomAnchor.constraint(equalTo: margins.bottomAnchor)
        ]
        verticalConstraints.forEach { $0.priority = .defaultHigh }
        let chevronUpBottom = chevronUpView.bottomAnchor.constraint(equalTo: contentView.centerYAnchor)
        let chevronDownTop = chevronDownView.topAnchor.constraint(equalTo: contentView.centerYAnchor)
        chevronUpBottomConstraint = chevronUpBottom
        chevronDownTopConstraint = chevronDownTop
        NSLayoutConstraint.activate(chevronSizeConstraints + verticalConstraints + [
            menuButton.leadingAnchor.constraint(equalTo: margins.leadingAnchor),
            menuButton.trailingAnchor.constraint(equalTo: margins.trailingAnchor),
            menuButton.heightAnchor.constraint(
                greaterThanOrEqualToConstant: WebCompatReporterUX.Control.minimumTapTarget
            ),

            categoryLabel.leadingAnchor.constraint(equalTo: margins.leadingAnchor),
            categoryLabel.trailingAnchor.constraint(
                lessThanOrEqualTo: chevronUpView.leadingAnchor,
                constant: -WebCompatReporterUX.Spacing.interItem
            ),

            chevronUpView.trailingAnchor.constraint(equalTo: margins.trailingAnchor),
            chevronUpBottom,

            chevronDownView.trailingAnchor.constraint(equalTo: margins.trailingAnchor),
            chevronDownTop
        ])
        applyScaledMetrics()
    }

    // MARK: - Notifiable

    nonisolated func handleNotifications(_ notification: Notification) {
        guard notification.name == UIContentSizeCategory.didChangeNotification else { return }
        ensureMainThread { [weak self] in
            self?.applyScaledMetrics()
        }
    }

    /// Keeps the chevron metrics in step with the current Dynamic Type size.
    private func applyScaledMetrics() {
        chevronSizeConstraints.forEach { $0.constant = scaledChevronSize }
        let halfOverlap = scaledChevronVerticalOverlap / 2
        chevronUpBottomConstraint?.constant = halfOverlap
        chevronDownTopConstraint?.constant = -halfOverlap
    }

    func configure(
        title: String,
        isPlaceholder: Bool,
        options: [WebCompatReportViewModel.Row.MenuOption],
        theme: Theme,
        a11yIdentifier: String,
        onSelect: @escaping (String) -> Void
    ) {
        selectionHandler = onSelect
        menuButton.accessibilityIdentifier = a11yIdentifier
        menuButton.accessibilityLabel = title
        backgroundConfiguration = .listGroupedCell()
        backgroundConfiguration?.backgroundColor = theme.colors.layer5
        categoryLabel.text = title
        categoryLabel.textColor = isPlaceholder ? theme.colors.textSecondary : theme.colors.textPrimary
        chevronUpView.tintColor = theme.colors.textSecondary
        chevronDownView.tintColor = theme.colors.textSecondary
        menuButton.menu = UIMenu(children: options.map { option in
            UIAction(title: option.title, state: option.isSelected ? .on : .off) { [weak self] _ in
                self?.selectionHandler?(option.id)
            }
        })
    }
}
