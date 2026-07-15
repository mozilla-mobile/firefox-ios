// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

/// Category pull-down row: a full-width button opening a `UIMenu` of categories.
/// Selection is reported through the handler, not stored, so it re-renders on configure.
final class WebCompatCategoryMenuCell: UICollectionViewListCell, Notifiable {
    private var selectionHandler: ((String) -> Void)?
    private var chevronSizeConstraints: [NSLayoutConstraint] = []

    private var scaledChevronSize: CGFloat {
        return UIFontMetrics.default.scaledValue(for: WebCompatReporterUX.Chevron.size)
    }

    private lazy var menuButton: UIButton = {
        let button = UIButton(configuration: UIButton.Configuration.plain())
        button.translatesAutoresizingMaskIntoConstraints = false
        button.contentHorizontalAlignment = .leading
        button.showsMenuAsPrimaryAction = true
        return button
    }()

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
        // The button spans the whole row so tapping anywhere — including over the
        // non-interactive chevrons layered on top — opens the pull-down.
        contentView.addSubview(menuButton)
        contentView.addSubview(chevronUpView)
        contentView.addSubview(chevronDownView)
        let margins = contentView.layoutMarginsGuide
        chevronSizeConstraints = [
            chevronUpView.widthAnchor.constraint(equalToConstant: scaledChevronSize),
            chevronUpView.heightAnchor.constraint(equalToConstant: scaledChevronSize),
            chevronDownView.widthAnchor.constraint(equalToConstant: scaledChevronSize),
            chevronDownView.heightAnchor.constraint(equalToConstant: scaledChevronSize)
        ]
        NSLayoutConstraint.activate(chevronSizeConstraints + [
            menuButton.leadingAnchor.constraint(equalTo: margins.leadingAnchor),
            menuButton.topAnchor.constraint(equalTo: margins.topAnchor),
            menuButton.bottomAnchor.constraint(equalTo: margins.bottomAnchor),
            menuButton.trailingAnchor.constraint(equalTo: margins.trailingAnchor),
            menuButton.heightAnchor.constraint(
                greaterThanOrEqualToConstant: WebCompatReporterUX.Control.minimumTapTarget
            ),

            chevronUpView.trailingAnchor.constraint(equalTo: margins.trailingAnchor),
            chevronUpView.bottomAnchor.constraint(equalTo: contentView.centerYAnchor),

            chevronDownView.trailingAnchor.constraint(equalTo: margins.trailingAnchor),
            chevronDownView.topAnchor.constraint(equalTo: contentView.centerYAnchor)
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

    /// Keeps the chevron and the button's reserved trailing space in step with
    /// the current Dynamic Type size.
    private func applyScaledMetrics() {
        chevronSizeConstraints.forEach { $0.constant = scaledChevronSize }
        menuButton.configuration?.contentInsets.trailing = scaledChevronSize + WebCompatReporterUX.Spacing.interItem
    }

    func configure(
        title: String,
        isPlaceholder: Bool,
        options: [WebCompatReportViewModel.Row.MenuOption],
        theme: Theme,
        onSelect: @escaping (String) -> Void
    ) {
        selectionHandler = onSelect
        backgroundConfiguration = .listGroupedCell()
        backgroundConfiguration?.backgroundColor = theme.colors.layer5
        var configuration = menuButton.configuration ?? UIButton.Configuration.plain()
        configuration.title = title
        configuration.baseForegroundColor = isPlaceholder ? theme.colors.textSecondary : theme.colors.textPrimary
        menuButton.configuration = configuration
        chevronUpView.tintColor = theme.colors.textSecondary
        chevronDownView.tintColor = theme.colors.textSecondary
        menuButton.menu = UIMenu(children: options.map { option in
            UIAction(title: option.title, state: option.isSelected ? .on : .off) { [weak self] _ in
                self?.selectionHandler?(option.id)
            }
        })
    }
}
