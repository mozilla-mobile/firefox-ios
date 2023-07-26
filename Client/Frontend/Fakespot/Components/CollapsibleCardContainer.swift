// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

class CollapsibleCardContainer: CardContainer, UIGestureRecognizerDelegate {
    private struct UX {
        static let verticalPadding: CGFloat = 8
        static let horizontalPadding: CGFloat = 8
        static let titleHorizontalPadding: CGFloat = 16
        static let titleTopPadding: CGFloat = 16
        static let chevronSize = CGSize(width: 20, height: 20)
    }

    private enum ExpandButtonState {
        case collapsed
        case expanded

        var image: UIImage? {
            switch self {
            case .expanded:
                return UIImage(named: StandardImageIdentifiers.Large.chevronUp)?.withRenderingMode(.alwaysTemplate)
            case .collapsed:
                return UIImage(named: StandardImageIdentifiers.Large.chevronDown)?.withRenderingMode(.alwaysTemplate)
            }
        }
    }

    // MARK: - Properties
    private var state: ExpandButtonState = .expanded

    // UI
    private lazy var rootView: UIView = .build { _ in }
    private lazy var headerView: UIView = .build { _ in }
    private lazy var containerView: UIView = .build { _ in }
    private var containerHeightConstraint: NSLayoutConstraint?
    private var tapRecognizer: UITapGestureRecognizer!

    lazy var titleLabel: UILabel = .build { label in
        label.adjustsFontForContentSizeCategory = true
        label.font = DynamicFontHelper.defaultHelper.preferredFont(withTextStyle: .headline, size: 17.0)
        label.numberOfLines = 0
    }

    private lazy var chevronButton: ResizableButton = .build { view in
        view.setImage(self.state.image, for: .normal)
        view.buttonEdgeSpacing = 0
        view.addTarget(self, action: #selector(self.toggleExpand), for: .touchUpInside)
    }

    // MARK: - Inits
    override init(frame: CGRect) {
        super.init(frame: frame)

        setupLayout()

        tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapHeader))
        tapRecognizer.delegate = self
        headerView.addGestureRecognizer(tapRecognizer)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func configure(_ view: UIView) {
        configure(title: "", contentView: view, baseA11yId: "", isCollapsed: false)
    }

    func configure(title: String, contentView: UIView, baseA11yId: String, isCollapsed: Bool) {
        state = isCollapsed ? .collapsed : .expanded
        containerView.subviews.forEach { $0.removeFromSuperview() }
        containerView.addSubview(contentView)

        titleLabel.text = title

        NSLayoutConstraint.activate([
            contentView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            contentView.topAnchor.constraint(equalTo: containerView.topAnchor),
            contentView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
        ])

        updateCardState(isCollapsed: isCollapsed)

        super.configure(rootView)
    }

    override func applyTheme(theme: Theme) {
        super.applyTheme(theme: theme)

        titleLabel.textColor = theme.colors.textPrimary
        chevronButton.tintColor = theme.colors.iconPrimary
    }

    private func setupLayout() {
        configure(rootView)

        headerView.addSubview(titleLabel)
        headerView.addSubview(chevronButton)
        rootView.addSubview(headerView)
        rootView.addSubview(containerView)

        containerHeightConstraint = containerView.heightAnchor.constraint(equalToConstant: 0)

        NSLayoutConstraint.activate([
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
            titleLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: UX.chevronSize.height),

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

    private func updateCardState(isCollapsed: Bool) {
        state = isCollapsed ? .collapsed : .expanded
        chevronButton.setImage(state.image, for: .normal)
        containerHeightConstraint?.isActive = isCollapsed
    }

    @objc
    private func toggleExpand(_ sender: UIButton) {
        updateCardState(isCollapsed: state == .expanded)
    }

    @objc
    func tapHeader(_ recognizer: UITapGestureRecognizer) {
        updateCardState(isCollapsed: state == .expanded)
    }
}
