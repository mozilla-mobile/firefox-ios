/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Shared
import Storage

struct AlternateSimpleHighlightCellUX {
    static let LabelColor = UIAccessibilityDarkerSystemColorsEnabled() ? UIColor.blackColor() : UIColor(rgb: 0x353535)
    static let BorderWidth: CGFloat = 0.5
    static let CellSideOffset = 20
    static let TitleLabelOffset = 2
    static let CellTopBottomOffset = 12
    static let SiteImageViewSize: CGSize = CGSize(width: 99, height: 76)
    static let StatusIconSize = 12
    static let DescriptionLabelColor = UIColor(colorString: "919191")
    static let TimestampColor = UIColor(colorString: "D4D4D4")
    static let SelectedOverlayColor = UIColor(white: 0.0, alpha: 0.25)
    static let CornerRadius: CGFloat = 3
    static let BorderColor = UIColor(white: 0, alpha: 0.1)
}

class AlternateSimpleHighlightCell: UITableViewCell {

    private lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.font = DynamicFontHelper.defaultHelper.DeviceFontMediumBoldActivityStream
        titleLabel.textColor = AlternateSimpleHighlightCellUX.LabelColor
        titleLabel.textAlignment = .Left
        titleLabel.numberOfLines = 3
        return titleLabel
    }()

    private lazy var descriptionLabel: UILabel = {
        let descriptionLabel = UILabel()
        descriptionLabel.font = DynamicFontHelper.defaultHelper.DeviceFontDescriptionActivityStream
        descriptionLabel.textColor = AlternateSimpleHighlightCellUX.DescriptionLabelColor
        descriptionLabel.textAlignment = .Left
        descriptionLabel.numberOfLines = 1
        return descriptionLabel
    }()

    private lazy var domainLabel: UILabel = {
        let descriptionLabel = UILabel()
        descriptionLabel.font = DynamicFontHelper.defaultHelper.DeviceFontDescriptionActivityStream
        descriptionLabel.textColor = AlternateSimpleHighlightCellUX.DescriptionLabelColor
        descriptionLabel.textAlignment = .Left
        descriptionLabel.numberOfLines = 1
        return descriptionLabel
    }()

    private lazy var timeStamp: UILabel = {
        let timeStamp = UILabel()
        timeStamp.font = DynamicFontHelper.defaultHelper.DeviceFontSmallActivityStream
        timeStamp.textColor = AlternateSimpleHighlightCellUX.TimestampColor
        timeStamp.textAlignment = .Right
        return timeStamp
    }()

    private lazy var siteImageView: UIImageView = {
        let siteImageView = UIImageView()
        siteImageView.contentMode = UIViewContentMode.ScaleAspectFit
        siteImageView.clipsToBounds = true
        siteImageView.contentMode = UIViewContentMode.Center
        siteImageView.layer.cornerRadius = AlternateSimpleHighlightCellUX.CornerRadius
        siteImageView.layer.borderColor = AlternateSimpleHighlightCellUX.BorderColor.CGColor
        siteImageView.layer.borderWidth = AlternateSimpleHighlightCellUX.BorderWidth
        siteImageView.layer.masksToBounds = true
        return siteImageView
    }()

    private lazy var statusIcon: UIImageView = {
        let statusIcon = UIImageView()
        statusIcon.contentMode = UIViewContentMode.ScaleAspectFit
        statusIcon.clipsToBounds = true
        statusIcon.layer.cornerRadius = AlternateSimpleHighlightCellUX.CornerRadius
        return statusIcon
    }()

    private lazy var selectedOverlay: UIView = {
        let selectedOverlay = UIView()
        selectedOverlay.backgroundColor = AlternateSimpleHighlightCellUX.SelectedOverlayColor
        selectedOverlay.hidden = true
        return selectedOverlay
    }()

    override var selected: Bool {
        didSet {
            self.selectedOverlay.hidden = !selected
        }
    }

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        layer.shouldRasterize = true
        layer.rasterizationScale = UIScreen.mainScreen().scale

        isAccessibilityElement = true

        contentView.addSubview(siteImageView)
        contentView.addSubview(descriptionLabel)
        contentView.addSubview(selectedOverlay)
        contentView.addSubview(titleLabel)
        contentView.addSubview(timeStamp)
        contentView.addSubview(statusIcon)
        contentView.addSubview(domainLabel)

        siteImageView.snp_makeConstraints { make in
            make.top.equalTo(contentView).offset(AlternateSimpleHighlightCellUX.CellTopBottomOffset)
            make.bottom.lessThanOrEqualTo(contentView).offset(-AlternateSimpleHighlightCellUX.CellTopBottomOffset)
            make.leading.equalTo(contentView).offset(AlternateSimpleHighlightCellUX.CellSideOffset)
            make.size.equalTo(AlternateSimpleHighlightCellUX.SiteImageViewSize)
        }

        selectedOverlay.snp_makeConstraints { make in
            make.edges.equalTo(contentView)
        }

        domainLabel.snp_makeConstraints { make in
            make.leading.equalTo(siteImageView.snp_trailing).offset(AlternateSimpleHighlightCellUX.CellTopBottomOffset)
            make.top.equalTo(siteImageView).offset(-2)
            make.bottom.equalTo(titleLabel.snp_top).offset(-4)
        }

        titleLabel.snp_makeConstraints { make in
            make.leading.equalTo(siteImageView.snp_trailing).offset(AlternateSimpleHighlightCellUX.CellTopBottomOffset)
            make.trailing.equalTo(contentView).inset(AlternateSimpleHighlightCellUX.CellSideOffset)
        }

        descriptionLabel.snp_makeConstraints { make in
            make.leading.equalTo(statusIcon.snp_trailing).offset(AlternateSimpleHighlightCellUX.TitleLabelOffset)
            make.bottom.equalTo(statusIcon)
        }

        timeStamp.snp_makeConstraints { make in
            make.trailing.equalTo(contentView).inset(AlternateSimpleHighlightCellUX.CellSideOffset)
            make.bottom.equalTo(descriptionLabel)
        }

        statusIcon.snp_makeConstraints { make in
            make.size.equalTo(SimpleHighlightCellUX.StatusIconSize)
            make.leading.equalTo(titleLabel)
            make.bottom.equalTo(siteImageView).priorityLow()
            make.top.greaterThanOrEqualTo(titleLabel.snp_bottom).offset(6).priorityHigh()
            make.bottom.lessThanOrEqualTo(contentView).offset(-AlternateSimpleHighlightCellUX.CellTopBottomOffset).priorityHigh()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setImageWithURL(url: NSURL) {
        siteImageView.sd_setImageWithURL(url) { (img, err, type, url) -> Void in
            guard let img = img else {
                return
            }
            // Resize an Image to a specfic size to make sure that it doesnt appear bigger than it needs to (32px) inside a larger frame (48px).
            self.siteImageView.image = img.createScaled(CGSize(width: 32, height: 32))
            self.siteImageView.image?.getColors(CGSizeMake(25, 25)) { colors in
                self.siteImageView.backgroundColor = colors.backgroundColor ?? UIColor.lightGrayColor()
            }
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        self.siteImageView.image = nil
        self.timeStamp.text = nil
    }

    func configureWithSite(site: Site) {
        if let icon = site.icon, let url = NSURL(string:icon.url) {
            self.setImageWithURL(url)
        } else {
            let url = site.url.asURL!
            self.siteImageView.image = FaviconFetcher.getDefaultFavicon(url)
            self.siteImageView.backgroundColor = FaviconFetcher.getDefaultColor(url)
        }
        self.domainLabel.text = site.tileURL.hostSLD
        self.titleLabel.text = site.title.characters.count <= 1 ? site.url : site.title

        if let bookmarked = site.bookmarked where bookmarked {
            self.descriptionLabel.text = "Bookmarked"
            self.statusIcon.image = UIImage(named: "context_bookmark")
        } else {
            self.descriptionLabel.text = "Visited"
            self.statusIcon.image = UIImage(named: "context_viewed")
        }

        if let date = site.latestVisit?.date {
            self.timeStamp.text = NSDate.fromMicrosecondTimestamp(date).toRelativeTimeString()
        }
    }
}
