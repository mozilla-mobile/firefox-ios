// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit
import Storage
import Shared

struct SiteTableViewHeaderModel {
    let title: String
    let isCollapsible: Bool
    let collapsibleState: ExpandButtonState?
}

class SiteTableViewHeader: UITableViewHeaderFooterView, ThemeApplicable, ReusableCell {
    struct UX {
        static let titleTrailingLeadingMargin: CGFloat = 16
        static let titleTopBottomMargin: CGFloat = 12
        static let imageTrailingSpace: CGFloat = 12
        static let imageWidthHeight: CGFloat = 24
    }

    var collapsibleState: ExpandButtonState?

    private let titleLabel: UILabel = .build { label in
        label.numberOfLines = 0
        label.font = FXFontStyles.Bold.callout.scaledFont()
        label.adjustsFontForContentSizeCategory = true
    }

    private let collapsibleImageView: UIImageView = .build { _ in }

    private var titleTrailingConstraint: NSLayoutConstraint!
    private var imageViewLeadingConstraint: NSLayoutConstraint!
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
    }

    func configure(_ model: SiteTableViewHeaderModel) {
        titleLabel.text = model.title

        showImage(model.isCollapsible)
        collapsibleState = model.collapsibleState
    }

    private func setupLayout() {
        translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubviews(titleLabel, collapsibleImageView)

        bordersHelper.initBorders(view: self.contentView)
        setDefaultBordersValues()

        backgroundView = UIView()

        imageViewLeadingConstraint = titleLabel.trailingAnchor.constraint(
            equalTo: collapsibleImageView.leadingAnchor,
            constant: -UX.titleTrailingLeadingMargin)

        titleTrailingConstraint = titleLabel.trailingAnchor.constraint(
            equalTo: contentView.trailingAnchor,
            constant: -UX.titleTrailingLeadingMargin)

        let scaledImageViewSize = UIFontMetrics.default.scaledValue(for: UX.imageWidthHeight)
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor,
                                                constant: UX.titleTrailingLeadingMargin),
            titleTrailingConstraint,
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor,
                                            constant: UX.titleTopBottomMargin),
            titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor,
                                               constant: -UX.titleTopBottomMargin),

            collapsibleImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            collapsibleImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor,
                                                           constant: -UX.imageTrailingSpace),
            collapsibleImageView.widthAnchor.constraint(equalToConstant: scaledImageViewSize),
            collapsibleImageView.heightAnchor.constraint(equalToConstant: scaledImageViewSize)
        ])

        showImage(false)
    }

    func applyTheme(theme: Theme) {
        titleLabel.textColor = theme.colors.textPrimary
        backgroundView?.backgroundColor = theme.colors.layer1
        collapsibleImageView.image = collapsibleState?.image?.tinted(withColor: theme.colors.iconAction)
        bordersHelper.applyTheme(theme: theme)
    }

    func showBorder(for location: ThemedHeaderFooterViewBordersHelper.BorderLocation, _ show: Bool) {
        bordersHelper.showBorder(for: location, show)
    }

    private func showImage(_ show: Bool) {
        collapsibleImageView.isHidden = !show
        titleTrailingConstraint.isActive = !show
        imageViewLeadingConstraint.isActive = show
    }

    func setDefaultBordersValues() {
        bordersHelper.showBorder(for: .top, true)
        bordersHelper.showBorder(for: .bottom, true)
    }
}
