// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit
import Shared

// Accessory that accompanies the title on the header
enum SiteTableHeaderAccessory {
    case collapsible(state: ExpandButtonState)
    case clear(action: () -> Void)
    case none
}

struct SiteTableViewHeaderModel {
    let title: String
    let accessory: SiteTableHeaderAccessory
    init(title: String, accessory: SiteTableHeaderAccessory = .none) {
        self.title = title
        self.accessory = accessory
    }
}

// Section header view that contains title, but also has an accessory view
// (i.e. collapsible arrow for synced tabs, clear button for recent searches list)
class SiteTableViewHeader: UITableViewHeaderFooterView, ThemeApplicable, ReusableCell {
    struct UX {
        static let titleTrailingLeadingMargin: CGFloat = 16
        static let titleTopBottomMargin: CGFloat = 12
        static let spacing: CGFloat = 12
        static let imageWidthHeight: CGFloat = 24
    }

    private var accessoryState: SiteTableHeaderAccessory = .none
    private var clearAction: (() -> Void)?
    private var collapsibleState: ExpandButtonState?

    private var existingAccessoryView: UIView?

    private let titleLabel: UILabel = .build { label in
        label.numberOfLines = 0
        label.font = FXFontStyles.Bold.callout.scaledFont()
        label.adjustsFontForContentSizeCategory = true
    }

    private lazy var headerStack: UIStackView = .build { stack in
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = UX.spacing
        stack.distribution = .fill
    }

    private let collapsibleImageView: UIImageView = .build { _ in }

    private lazy var clearButton: UIButton = .build { button in
        button.setTitle(.SearchZero.ClearButtonTitle, for: .normal)
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.titleLabel?.font = FXFontStyles.Regular.callout.scaledFont()
        button.addTarget(self, action: #selector(self.clearButtonTapped), for: .touchUpInside)
    }

    fileprivate let bordersHelper = ThemedHeaderFooterViewBordersHelper()

    override var textLabel: UILabel? {
        return titleLabel
    }

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)

        setupLayout()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        setDefaultBordersValues()
        removeAccessory()
    }

    func configure(_ model: SiteTableViewHeaderModel) {
        titleLabel.text = model.title

        removeAccessory()

        switch model.accessory {
        case .collapsible(let state):
            collapsibleState = state
            collapsibleImageView.image = collapsibleState?.image
            setupAccessoryView(collapsibleImageView)

        case .clear(let action):
            clearAction = action
            setupAccessoryView(clearButton)

        case .none:
            break
        }
    }

    private func setupLayout() {
        headerStack.addArrangedSubview(titleLabel)
        contentView.addSubviews(headerStack)

        bordersHelper.initBorders(view: self.contentView)
        setDefaultBordersValues()

        backgroundView = UIView()
        let scaledImageViewSize = UIFontMetrics.default.scaledValue(for: UX.imageWidthHeight)

        NSLayoutConstraint.activate(
            [
                headerStack.leadingAnchor.constraint(
                    equalTo: contentView.leadingAnchor,
                    constant: UX.titleTrailingLeadingMargin
                ),
                headerStack.trailingAnchor.constraint(
                    equalTo: contentView.trailingAnchor,
                    constant: -UX.spacing
                ),
                headerStack.topAnchor.constraint(
                    equalTo: contentView.topAnchor,
                    constant: UX.titleTopBottomMargin
                ),
                headerStack.bottomAnchor.constraint(
                    equalTo: contentView.bottomAnchor,
                    constant: -UX.titleTopBottomMargin
                ),
                collapsibleImageView.widthAnchor.constraint(equalToConstant: scaledImageViewSize),
                collapsibleImageView.heightAnchor.constraint(equalToConstant: scaledImageViewSize)
            ]
        )
    }

    private func removeAccessory() {
        accessoryState = .none
        if let accessoryView = existingAccessoryView {
            headerStack.removeArrangedSubview(accessoryView)
            accessoryView.removeFromSuperview()
        }
        existingAccessoryView = nil
    }

    private func setupAccessoryView(_ view: UIView) {
        existingAccessoryView = view
        headerStack.addArrangedSubview(view)
        view.setContentHuggingPriority(.required, for: .horizontal)
        view.setContentCompressionResistancePriority(.required, for: .horizontal)

        setNeedsLayout()
        layoutIfNeeded()
    }

    func applyTheme(theme: Theme) {
        titleLabel.textColor = theme.colors.textPrimary
        clearButton.setTitleColor(theme.colors.textSecondary, for: .normal)
        backgroundView?.backgroundColor = theme.colors.layer1
        collapsibleImageView.image = collapsibleState?.image?.tinted(withColor: theme.colors.iconAccent)
        bordersHelper.applyTheme(theme: theme)
    }

    func showBorder(for location: ThemedHeaderFooterViewBordersHelper.BorderLocation, _ show: Bool) {
        bordersHelper.showBorder(for: location, show)
    }

    func setDefaultBordersValues() {
        bordersHelper.showBorder(for: .top, true)
        bordersHelper.showBorder(for: .bottom, true)
    }

    @objc
    private func clearButtonTapped() {
        clearAction?()
    }
}
