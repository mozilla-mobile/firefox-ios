// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Storage

struct SiteTableViewHeaderModel {
    let title: String
    let isCollapsible: Bool
    let collapsibleState: ExpandButtonState?
}

class SiteTableViewHeader: UITableViewHeaderFooterView, NotificationThemeable, ReusableCell {

    struct UX {
        static let titleTrailingLeadingMargin: CGFloat = 16
        static let titleTopBottomMargin: CGFloat = 12
        static let imageTrailingSpace: CGFloat = 12
        static let imageWidthHeight: CGFloat = 24
    }

    var collapsibleState: ExpandButtonState? {
        willSet(state) {
            collapsibleImageView.image = state?.image?.tinted(withColor: UIColor.Photon.Blue50)
        }
    }

    private let titleLabel: UILabel = .build { label in
        label.textColor = UIColor.theme.tableView.headerTextDark
        label.numberOfLines = 0
        label.font = DynamicFontHelper.defaultHelper.preferredFont(withTextStyle: .headline,
                                                                   size: 16)
        label.adjustsFontForContentSizeCategory = true
    }

    private let collapsibleImageView: UIImageView = .build { imageView in
        imageView.image = ExpandButtonState.down.image?.tinted(withColor: UIColor.Photon.Blue50)
    }

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
        applyTheme()
    }

    func configure(_ model: SiteTableViewHeaderModel) {
        titleLabel.text = model.title

        showImage(model.isCollapsible)
        collapsibleState = model.collapsibleState
    }

    func setupLayout() {
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
            collapsibleImageView.widthAnchor.constraint(equalToConstant: UX.imageWidthHeight),
            collapsibleImageView.heightAnchor.constraint(equalToConstant: UX.imageWidthHeight)
        ])

        showImage(false)
        applyTheme()
    }

    func applyTheme() {
        titleLabel.textColor = UIColor.theme.tableView.headerTextDark
        backgroundView?.backgroundColor = UIColor.theme.tableView.selectedBackground
        bordersHelper.applyTheme()
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
