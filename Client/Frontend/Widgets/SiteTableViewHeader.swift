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
        static let HeaderFont = UIFont.systemFont(ofSize: 12, weight: UIFont.Weight.medium)
        static let HeaderTextMargin: CGFloat = 16
        static let TrailingSpace: CGFloat = 12
        static let ImageWidthHeight: CGFloat = 24
    }

    var collapsibleState: ExpandButtonState? {
        willSet(state) {
            collapsibleImageView.image = state?.image?.tinted(withColor: UIColor.Photon.Blue50)
        }
    }

    private let titleLabel: UILabel = .build { label in
        label.font = DynamicFontHelper.defaultHelper.DeviceFontMediumBold
        label.textColor = UIColor.theme.tableView.headerTextDark
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

        translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubviews(titleLabel, collapsibleImageView)

        bordersHelper.initBorders(view: self.contentView)
        setDefaultBordersValues()

        backgroundView = UIView()
        imageViewLeadingConstraint = titleLabel.trailingAnchor.constraint(
            equalTo: collapsibleImageView.leadingAnchor,
            constant: -UX.HeaderTextMargin)
        titleTrailingConstraint = titleLabel.trailingAnchor.constraint(
            equalTo: contentView.trailingAnchor,
            constant: -UX.HeaderTextMargin)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor,
                                                constant: UX.HeaderTextMargin),
            titleTrailingConstraint,
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            collapsibleImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            imageViewLeadingConstraint,
            collapsibleImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor,
                                                           constant: -UX.TrailingSpace),
            collapsibleImageView.widthAnchor.constraint(equalToConstant: UX.ImageWidthHeight),
            collapsibleImageView.heightAnchor.constraint(equalToConstant: UX.ImageWidthHeight)
        ])

        showImage(false)
        applyTheme()
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

    func applyTheme() {
        titleLabel.textColor = UIColor.theme.tableView.headerTextDark
        backgroundView?.backgroundColor = UIColor.theme.tableView.selectedBackground
        bordersHelper.applyTheme()
    }

    func showBorder(for location: ThemedHeaderFooterViewBordersHelper.BorderLocation, _ show: Bool) {
        bordersHelper.showBorder(for: location, show)
    }

    func showImage(_ show: Bool) {
        collapsibleImageView.isHidden = !show
        titleTrailingConstraint.isActive = !show
        imageViewLeadingConstraint.isActive = show
    }

    func setDefaultBordersValues() {
        bordersHelper.showBorder(for: .top, true)
        bordersHelper.showBorder(for: .bottom, true)
    }
}
