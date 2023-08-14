// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared
import SiteImageView

enum OneLineTableViewCustomization {
    case regular
    case inactiveCell
}

struct OneLineTableViewCellViewModel {
    let title: String?
    var leftImageView: UIImage?
    let accessoryView: UIImageView?
    let accessoryType: UITableViewCell.AccessoryType
}

class OneLineTableViewCell: UITableViewCell,
                            ReusableCell,
                            ThemeApplicable {
    // Tableview cell items

    struct UX {
        static let imageSize: CGFloat = 29
        static let borderViewMargin: CGFloat = 16
        static let labelFontSize: CGFloat = 17
        static let verticalMargin: CGFloat = 8
        static let leftImageViewSize: CGFloat = 28
        static let separatorViewHeight: CGFloat = 0.7
        static let labelMargin: CGFloat = 4
        static let shortLeadingMargin: CGFloat = 5
        static let longLeadingMargin: CGFloat = 13
        static let cornerRadius: CGFloat = 5
    }

    var shouldLeftAlignTitle = false
    var customization: OneLineTableViewCustomization = .regular

    private lazy var selectedView: UIView = .build { _ in }
    private lazy var containerView: UIView = .build { _ in }

    lazy var leftImageView: FaviconImageView = .build { _ in }

    lazy var titleLabel: UILabel = .build { label in
        label.font = DefaultDynamicFontHelper.preferredFont(withTextStyle: .body,
                                                            size: UX.labelFontSize)
        label.textAlignment = .natural
    }

    private lazy var bottomSeparatorView: UIView = .build { separatorLine in
        // separator hidden by default
        separatorLine.isHidden = true
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var defaultSeparatorInset: UIEdgeInsets {
        return UIEdgeInsets(top: 0,
                            left: UX.imageSize + 2 * UX.borderViewMargin,
                            bottom: 0,
                            right: 0)
    }

    private func setupLayout() {
        separatorInset = defaultSeparatorInset
        selectionStyle = .default

        containerView.addSubviews(leftImageView,
                                  titleLabel,
                                  bottomSeparatorView)

        contentView.addSubview(containerView)
        bringSubviewToFront(containerView)

        let containerViewTrailingAnchor = accessoryView?.leadingAnchor ?? contentView.trailingAnchor
        let midViewLeadingMargin: CGFloat = shouldLeftAlignTitle ? UX.shortLeadingMargin : UX.longLeadingMargin

        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor,
                                               constant: UX.verticalMargin),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor,
                                                  constant: -UX.verticalMargin),
            containerView.trailingAnchor.constraint(equalTo: containerViewTrailingAnchor),

            leftImageView.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            leftImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor,
                                                   constant: UX.borderViewMargin),
            leftImageView.widthAnchor.constraint(equalToConstant: UX.leftImageViewSize),
            leftImageView.heightAnchor.constraint(equalToConstant: UX.leftImageViewSize),
            leftImageView.trailingAnchor.constraint(equalTo: titleLabel.leadingAnchor,
                                                    constant: -midViewLeadingMargin),

            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor,
                                            constant: UX.labelMargin),
            titleLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor,
                                               constant: -UX.labelMargin),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor,
                                                 constant: -UX.verticalMargin),

            bottomSeparatorView.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            bottomSeparatorView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            bottomSeparatorView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            bottomSeparatorView.heightAnchor.constraint(equalToConstant: UX.separatorViewHeight)
        ])

        selectedBackgroundView = selectedView
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        selectionStyle = .default
        separatorInset = defaultSeparatorInset
        titleLabel.text = nil
        leftImageView.image = nil
    }

    // To simplify setup, OneLineTableViewCell now has a viewModel
    // Use it for new code, replace when possible in old code
    func configure(viewModel: OneLineTableViewCellViewModel) {
        titleLabel.text = viewModel.title
        accessoryView = viewModel.accessoryView
        accessoryType = viewModel.accessoryType

        if let image = viewModel.leftImageView {
            leftImageView.image = image
        }
    }

    func configureTapState(isEnabled: Bool) {
        titleLabel.alpha = isEnabled ? 1.0 : 0.5
        leftImageView.alpha = isEnabled ? 1.0 : 0.5
    }

    func applyTheme(theme: Theme) {
        selectedView.backgroundColor = theme.colors.layer5Hover
        backgroundColor = theme.colors.layer5
        titleLabel.textColor = theme.colors.textPrimary
        bottomSeparatorView.backgroundColor = theme.colors.borderPrimary
        accessoryView?.tintColor = theme.colors.actionSecondary
    }
}
