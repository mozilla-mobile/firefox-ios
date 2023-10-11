// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit
import SiteImageView
import Shared

class LegacyInactiveTabItemCell: UITableViewCell, ReusableCell, ThemeApplicable {
    private var viewModel: LegacyInactiveTabItemCellModel?

    private lazy var selectedView: UIView = .build { _ in }
    private lazy var leftImageView: FaviconImageView = .build { _ in }
    private lazy var bottomSeparatorView: UIView = .build { _ in }
    private lazy var containerView: UIView = .build { _ in }
    private lazy var midView: UIView = .build { _ in }
    private var containerViewLeadingConstraint: NSLayoutConstraint!

    private lazy var titleLabel: UILabel = .build { label in
        label.textAlignment = .natural
        label.numberOfLines = 1
        label.contentMode = .center
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initialViewSetup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configureCell(viewModel: LegacyInactiveTabItemCellModel) {
        self.viewModel = viewModel

        titleLabel.text = viewModel.title
        titleLabel.font = viewModel.fontForLabel

        if let urlString = viewModel.website?.absoluteString {
            let cornerRadius = LegacyInactiveTabItemCellModel.UX.FaviconCornerRadius
            leftImageView.setFavicon(FaviconImageViewModel(siteURLString: urlString,
                                                           faviconCornerRadius: cornerRadius))
        }
        separatorInset = UIEdgeInsets(top: 0,
                                      left: LegacyInactiveTabItemCellModel.UX.ImageSize + 2 *
                                      LegacyInactiveTabItemCellModel.UX.BorderViewMargin,
                                      bottom: 0,
                                      right: 0)
        backgroundColor = .clear
    }

    func initialViewSetup() {
        self.selectionStyle = .default
        midView.addSubview(titleLabel)
        containerView.addSubviews(bottomSeparatorView)
        containerView.addSubview(leftImageView)
        containerView.addSubview(midView)

        contentView.addSubview(containerView)
        bringSubviewToFront(containerView)

        containerViewLeadingConstraint = containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor)

        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            containerViewLeadingConstraint,
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            leftImageView.heightAnchor.constraint(equalToConstant: LegacyInactiveTabItemCellModel.UX.ImageSize),
            leftImageView.widthAnchor.constraint(equalToConstant: LegacyInactiveTabItemCellModel.UX.ImageSize),
            leftImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor,
                                                   constant: LegacyInactiveTabItemCellModel.UX.ImageViewLeadingConstant),
            leftImageView.centerYAnchor.constraint(equalTo: midView.centerYAnchor),
            leftImageView.topAnchor.constraint(greaterThanOrEqualTo: containerView.topAnchor,
                                               constant: LegacyInactiveTabItemCellModel.UX.ImageTopBottomMargin),
            leftImageView.bottomAnchor.constraint(lessThanOrEqualTo: containerView.bottomAnchor,
                                                  constant: LegacyInactiveTabItemCellModel.UX.ImageTopBottomMargin),

            midView.topAnchor.constraint(equalTo: containerView.topAnchor),
            midView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            midView.leadingAnchor.constraint(equalTo: leftImageView.trailingAnchor,
                                             constant: LegacyInactiveTabItemCellModel.UX.MidViewLeadingConstant),
            midView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor,
                                              constant: LegacyInactiveTabItemCellModel.UX.MidViewTrailingConstant),

            titleLabel.topAnchor.constraint(equalTo: midView.topAnchor,
                                            constant: LegacyInactiveTabItemCellModel.UX.LabelTopBottomMargin),
            titleLabel.bottomAnchor.constraint(equalTo: midView.bottomAnchor,
                                               constant: -LegacyInactiveTabItemCellModel.UX.LabelTopBottomMargin),
            titleLabel.leadingAnchor.constraint(equalTo: midView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: midView.trailingAnchor),

            bottomSeparatorView.heightAnchor.constraint(equalToConstant: LegacyInactiveTabItemCellModel.UX.SeparatorHeight),
            bottomSeparatorView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            bottomSeparatorView.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            bottomSeparatorView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
        ])

        leftImageView.setContentHuggingPriority(.required, for: .vertical)

        selectedBackgroundView = selectedView
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        selectionStyle = .default
    }

    // MARK: ThemeApplicable

    func applyTheme(theme: Theme) {
        selectedView.backgroundColor = theme.colors.layer5Hover
        titleLabel.textColor = theme.colors.textPrimary
        backgroundColor = theme.colors.layer2
        bottomSeparatorView.backgroundColor = theme.colors.borderPrimary
    }
}
