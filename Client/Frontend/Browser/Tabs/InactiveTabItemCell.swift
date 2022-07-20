// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

class InactiveTabItemCell: UITableViewCell, NotificationThemeable, ReusableCell {

    private var viewModel: InactiveTabItemCellModel?

    private var selectedView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.theme.tableView.selectedBackground
        return view
    }()

    private lazy var leftImageView: UIImageView = .build { imageView in
        imageView.contentMode = .scaleAspectFit
        imageView.layer.cornerRadius = 5.0
        imageView.clipsToBounds = true
    }

    private lazy var titleLabel: UILabel = .build { label in
        label.textColor = .black
        label.textAlignment = .natural
        label.numberOfLines = 1
        label.contentMode = .center
    }

    private lazy var bottomSeparatorView: UIView = .build { separatorLine in
        separatorLine.backgroundColor = UIColor.Photon.LightGrey30
    }

    private var containerViewLeadingConstraint: NSLayoutConstraint!

    private lazy var containerView: UIView = .build { _ in }
    private lazy var midView: UIView = .build { _ in }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initialViewSetup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configureCell(viewModel: InactiveTabItemCellModel) {
        self.viewModel = viewModel

        titleLabel.text = viewModel.title
        titleLabel.font = viewModel.fontForLabel
        leftImageView.setImageAndBackground(forIcon: viewModel.icon,
                                            website: viewModel.website) {}
        separatorInset = UIEdgeInsets(top: 0,
                                      left: InactiveTabItemCellModel.UX.ImageSize + 2 *
                                      InactiveTabItemCellModel.UX.BorderViewMargin,
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

            leftImageView.heightAnchor.constraint(equalToConstant: InactiveTabItemCellModel.UX.ImageSize),
            leftImageView.widthAnchor.constraint(equalToConstant: InactiveTabItemCellModel.UX.ImageSize),
            leftImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor,
                                                   constant: InactiveTabItemCellModel.UX.ImageViewLeadingConstant),
            leftImageView.centerYAnchor.constraint(equalTo: midView.centerYAnchor),
            leftImageView.topAnchor.constraint(greaterThanOrEqualTo: containerView.topAnchor,
                                               constant: InactiveTabItemCellModel.UX.ImageTopBottomMargin),
            leftImageView.bottomAnchor.constraint(lessThanOrEqualTo: containerView.bottomAnchor,
                                                  constant: InactiveTabItemCellModel.UX.ImageTopBottomMargin),

            midView.topAnchor.constraint(equalTo: containerView.topAnchor),
            midView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            midView.leadingAnchor.constraint(equalTo: leftImageView.trailingAnchor,
                                             constant: InactiveTabItemCellModel.UX.MidViewLeadingConstant),
            midView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor,
                                              constant: InactiveTabItemCellModel.UX.MidViewTrailingConstant),

            titleLabel.topAnchor.constraint(equalTo: midView.topAnchor,
                                            constant: InactiveTabItemCellModel.UX.LabelTopBottomMargin),
            titleLabel.bottomAnchor.constraint(equalTo: midView.bottomAnchor,
                                               constant: -InactiveTabItemCellModel.UX.LabelTopBottomMargin),
            titleLabel.leadingAnchor.constraint(equalTo: midView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: midView.trailingAnchor),

            bottomSeparatorView.heightAnchor.constraint(equalToConstant: InactiveTabItemCellModel.UX.SeparatorHeight),
            bottomSeparatorView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            bottomSeparatorView.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            bottomSeparatorView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
        ])

        leftImageView.setContentHuggingPriority(.required, for: .vertical)

        selectedBackgroundView = selectedView
        applyTheme()
    }

    func applyTheme() {
        let theme = BuiltinThemeName(rawValue: LegacyThemeManager.instance.current.name) ?? .normal
        selectedView.backgroundColor = UIColor.theme.tableView.selectedBackground
        if theme == .dark {
            backgroundColor = UIColor.Photon.Grey80
            titleLabel.textColor = .white
        } else {
            backgroundColor = .white
            titleLabel.textColor = .black
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        selectionStyle = .default
        applyTheme()
    }
}
