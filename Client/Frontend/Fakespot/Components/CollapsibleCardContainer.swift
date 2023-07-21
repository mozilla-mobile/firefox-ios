// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

class CollapsibleCardContainer: UIView, ThemeApplicable {
    private struct UX {
        static let verticalPadding: CGFloat = 8
        static let horizontalPadding: CGFloat = 8
        static let titleHorizontalPadding: CGFloat = 16
        static let titleTopPadding: CGFloat = 16
        static let cornerRadius: CGFloat = 8
        static let shadowRadius: CGFloat = 14
        static let shadowOpacity: Float = 1
        static let shadowOffset = CGSize(width: 0, height: 2)
        static let chevronSize = CGSize(width: 20, height: 20)
    }

    // MARK: - Properties

    // UI
    private lazy var rootView: UIView = .build { _ in }
    private lazy var headerView: UIView = .build { _ in }
    lazy var containerView: UIView = .build { _ in }

    lazy var titleLabel: UILabel = .build { label in
        label.adjustsFontForContentSizeCategory = true
        label.font = DynamicFontHelper.defaultHelper.preferredFont(withTextStyle: .headline, size: 17.0)
        label.numberOfLines = 0
        label.text = "I am a header"
    }

    private lazy var chevronButton: ResizableButton = .build { view in
        view.setImage(UIImage(named: ImageIdentifiers.Large.chevronDown)?.withRenderingMode(.alwaysTemplate),
                      for: .normal)
        view.buttonEdgeSpacing = 0
        view.accessibilityIdentifier = AccessibilityIdentifiers.Components.collapseButton
    }

    // MARK: - Inits
    override init(frame: CGRect) {
        super.init(frame: frame)

        setupLayout()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        rootView.layer.shadowPath = UIBezierPath(roundedRect: rootView.bounds,
                                                 cornerRadius: UX.cornerRadius).cgPath
    }

    func applyTheme(theme: Theme) {
        rootView.backgroundColor = theme.colors.layer2
        titleLabel.textColor = theme.colors.textPrimary
        chevronButton.tintColor = theme.colors.actionPrimary
        setupShadow(theme: theme)
    }

    private func setupLayout() {
        headerView.addSubview(titleLabel)
        headerView.addSubview(chevronButton)
        rootView.addSubview(headerView)
        rootView.addSubview(containerView)
        addSubview(rootView)

        NSLayoutConstraint.activate([
            rootView.leadingAnchor.constraint(equalTo: leadingAnchor),
            rootView.topAnchor.constraint(equalTo: topAnchor),
            rootView.trailingAnchor.constraint(equalTo: trailingAnchor),
            rootView.bottomAnchor.constraint(equalTo: bottomAnchor),

            headerView.leadingAnchor.constraint(equalTo: rootView.leadingAnchor,
                                                constant: UX.titleHorizontalPadding),
            headerView.topAnchor.constraint(equalTo: rootView.topAnchor,
                                            constant: UX.titleTopPadding),
            headerView.trailingAnchor.constraint(equalTo: rootView.trailingAnchor,
                                                 constant: -UX.titleHorizontalPadding),
            headerView.bottomAnchor.constraint(equalTo: containerView.topAnchor,
                                               constant: -UX.verticalPadding),

            titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            titleLabel.topAnchor.constraint(equalTo: headerView.topAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: chevronButton.leadingAnchor,
                                                 constant: -UX.horizontalPadding),
            titleLabel.bottomAnchor.constraint(equalTo: headerView.bottomAnchor),

            chevronButton.topAnchor.constraint(greaterThanOrEqualTo: headerView.topAnchor),
            chevronButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            chevronButton.bottomAnchor.constraint(lessThanOrEqualTo: headerView.bottomAnchor),
            chevronButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            chevronButton.widthAnchor.constraint(equalToConstant: UX.chevronSize.width),
            chevronButton.heightAnchor.constraint(equalToConstant: UX.chevronSize.height),

            containerView.leadingAnchor.constraint(equalTo: rootView.leadingAnchor,
                                                   constant: UX.horizontalPadding),
            containerView.trailingAnchor.constraint(equalTo: rootView.trailingAnchor,
                                                    constant: -UX.horizontalPadding),
            containerView.bottomAnchor.constraint(equalTo: rootView.bottomAnchor,
                                                  constant: -UX.verticalPadding),
        ])
    }

    private func setupShadow(theme: Theme) {
        rootView.layer.cornerRadius = UX.cornerRadius
        rootView.layer.shadowPath = UIBezierPath(roundedRect: rootView.bounds,
                                                 cornerRadius: UX.cornerRadius).cgPath
        rootView.layer.shadowRadius = UX.shadowRadius
        rootView.layer.shadowOffset = UX.shadowOffset
        rootView.layer.shadowColor = theme.colors.shadowDefault.cgColor
        rootView.layer.shadowOpacity = UX.shadowOpacity
    }
}
