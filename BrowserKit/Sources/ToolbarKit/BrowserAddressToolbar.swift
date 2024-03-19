// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

/// Simple address toolbar implementation.
/// +-------------+------------+-----------------------+----------+------+
/// | navigation  | indicators | url       [ page    ] | browser  | menu |
/// |   actions   |            |           [ actions ] | actions  |      |
/// +-------------+------------+-----------------------+----------+------+
/// +------------------------progress------------------------------------+
public class BrowserAddressToolbar: UIView, AddressToolbar, ThemeApplicable {
    private enum UX {
        static let horizontalSpace: CGFloat = 16
        static let cornerRadius: CGFloat = 8
        static let dividerWidth: CGFloat = 4
        static let actionSpacing: CGFloat = 0
    }

    private lazy var navigationActionStack: UIStackView = .build()

    private lazy var locationContainer: UIView = .build { view in
        view.layer.cornerRadius = UX.cornerRadius
    }

    private lazy var locationView: UIView = .build()
    private lazy var locationDividerView: UIView = .build()

    private lazy var pageActionStack: UIStackView = .build { view in
        view.spacing = UX.actionSpacing
    }
    private lazy var browserActionStack: UIStackView = .build()

    private var leadingBrowserActionConstraint: NSLayoutConstraint?
    private var leadingLocationContainerConstraint: NSLayoutConstraint?

    override init(frame: CGRect) {
        super.init(frame: .zero)
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func configure(state: AddressToolbarState) {
        updateBrowserActionSpacing()
        updateNavigationActionSpacing()
    }

    // MARK: - ThemeApplicable
    public func applyTheme(theme: Theme) {
        locationContainer.backgroundColor = theme.colors.layer3
        locationDividerView.backgroundColor = theme.colors.layer1
    }

    // MARK: - Private
    private func setupLayout() {
        addSubview(navigationActionStack)

        locationContainer.addSubview(locationView)
        locationContainer.addSubview(locationDividerView)
        locationContainer.addSubview(pageActionStack)

        addSubview(locationContainer)
        addSubview(browserActionStack)

        leadingLocationContainerConstraint = navigationActionStack.trailingAnchor.constraint(
            equalTo: locationContainer.leadingAnchor,
            constant: -UX.horizontalSpace)
        leadingLocationContainerConstraint?.isActive = true

        leadingBrowserActionConstraint = browserActionStack.leadingAnchor.constraint(
            equalTo: locationContainer.trailingAnchor,
            constant: UX.horizontalSpace)
        leadingBrowserActionConstraint?.isActive = true

        NSLayoutConstraint.activate([
            navigationActionStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            navigationActionStack.topAnchor.constraint(equalTo: topAnchor),
            navigationActionStack.bottomAnchor.constraint(equalTo: bottomAnchor),

            locationContainer.topAnchor.constraint(equalTo: topAnchor),
            locationContainer.bottomAnchor.constraint(equalTo: bottomAnchor),
            locationContainer.heightAnchor.constraint(equalToConstant: 40),

            locationView.leadingAnchor.constraint(equalTo: locationContainer.leadingAnchor),
            locationView.topAnchor.constraint(equalTo: locationContainer.topAnchor),
            locationView.trailingAnchor.constraint(equalTo: locationDividerView.leadingAnchor),
            locationView.bottomAnchor.constraint(equalTo: locationContainer.bottomAnchor),

            locationDividerView.topAnchor.constraint(equalTo: locationContainer.topAnchor),
            locationDividerView.trailingAnchor.constraint(equalTo: pageActionStack.leadingAnchor),
            locationDividerView.bottomAnchor.constraint(equalTo: locationContainer.bottomAnchor),
            locationDividerView.widthAnchor.constraint(equalToConstant: UX.dividerWidth),

            pageActionStack.topAnchor.constraint(equalTo: locationContainer.topAnchor),
            pageActionStack.trailingAnchor.constraint(equalTo: locationContainer.trailingAnchor),
            pageActionStack.bottomAnchor.constraint(equalTo: locationContainer.bottomAnchor),

            browserActionStack.topAnchor.constraint(equalTo: topAnchor),
            browserActionStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            browserActionStack.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])

        navigationActionStack.setContentHuggingPriority(.required, for: .horizontal)
        locationContainer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        browserActionStack.setContentHuggingPriority(.required, for: .horizontal)
        updateNavigationActionSpacing()
        updateBrowserActionSpacing()
    }

    private func updateBrowserActionSpacing() {
        let hasActions = !browserActionStack.arrangedSubviews.isEmpty
        leadingBrowserActionConstraint?.constant = hasActions ? UX.horizontalSpace : 0
    }

    private func updateNavigationActionSpacing() {
        let hasActions = !navigationActionStack.arrangedSubviews.isEmpty
        leadingLocationContainerConstraint?.constant = hasActions ? -UX.horizontalSpace : 0
    }
}
