/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Shared
import Storage

struct SimpleHighlightCellUX {
    static let LabelColor = UIAccessibilityDarkerSystemColorsEnabled() ? UIColor.black : UIColor(rgb: 0x353535)
    static let BorderWidth: CGFloat = 0.5
    static let CellSideOffset = 20
    static let AlternateBottomOffset = 16
    static let TitleLabelOffset = 10
    static let CellTopBottomOffset = 12
    static let SiteImageViewSize = 48
    static let IconSize = CGSize(width: 32, height: 32)
    static let StatusIconSize = 12
    static let DescriptionLabelColor = UIColor(colorString: "919191")
    static let TimestampColor = UIColor(colorString: "D4D4D4")
    static let SelectedOverlayColor = UIColor(white: 0.0, alpha: 0.25)
    static let PlaceholderImage = UIImage(named: "defaultTopSiteIcon")
    static let CornerRadius: CGFloat = 3
    static let NearestNeighbordScalingThreshold: CGFloat = 24
    static let BorderColor = UIColor(white: 0, alpha: 0.1)
}

class SimpleHighlightCell: UITableViewCell {

    fileprivate lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.font = DynamicFontHelper.defaultHelper.DeviceFontMediumBold
        titleLabel.textColor = SimpleHighlightCellUX.LabelColor
        titleLabel.textAlignment = .left
        titleLabel.numberOfLines = 3
        return titleLabel
    }()

    fileprivate lazy var descriptionLabel: UILabel = {
        let descriptionLabel = UILabel()
        descriptionLabel.font = DynamicFontHelper.defaultHelper.DeviceFontDescriptionActivityStream
        descriptionLabel.textColor = SimpleHighlightCellUX.DescriptionLabelColor
        descriptionLabel.textAlignment = .left
        descriptionLabel.numberOfLines = 1
        return descriptionLabel
    }()

    fileprivate lazy var timeStamp: UILabel = {
        let timeStamp = UILabel()
        timeStamp.font = DynamicFontHelper.defaultHelper.DeviceFontSmallActivityStream
        timeStamp.textColor = SimpleHighlightCellUX.TimestampColor
        timeStamp.textAlignment = .right
        return timeStamp
    }()

    lazy var siteImageView: UIImageView = {
        let siteImageView = UIImageView()
        siteImageView.contentMode = UIViewContentMode.scaleAspectFit
        siteImageView.clipsToBounds = true
        siteImageView.contentMode = UIViewContentMode.center
        siteImageView.layer.cornerRadius = SimpleHighlightCellUX.CornerRadius
        siteImageView.layer.borderColor = SimpleHighlightCellUX.BorderColor.cgColor
        siteImageView.layer.borderWidth = SimpleHighlightCellUX.BorderWidth
        siteImageView.layer.masksToBounds = true
        return siteImageView
    }()

    fileprivate lazy var statusIcon: UIImageView = {
        let statusIcon = UIImageView()
        statusIcon.contentMode = UIViewContentMode.scaleAspectFit
        statusIcon.clipsToBounds = true
        statusIcon.layer.cornerRadius = SimpleHighlightCellUX.CornerRadius
        return statusIcon
    }()

    fileprivate lazy var selectedOverlay: UIView = {
        let selectedOverlay = UIView()
        selectedOverlay.backgroundColor = SimpleHighlightCellUX.SelectedOverlayColor
        selectedOverlay.isHidden = true
        return selectedOverlay
    }()

    override var isSelected: Bool {
        didSet {
            self.selectedOverlay.isHidden = !isSelected
        }
    }

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        layer.shouldRasterize = true
        layer.rasterizationScale = UIScreen.main.scale

        isAccessibilityElement = true

        contentView.addSubview(siteImageView)
        contentView.addSubview(descriptionLabel)
        contentView.addSubview(selectedOverlay)
        contentView.addSubview(titleLabel)
        contentView.addSubview(timeStamp)
        contentView.addSubview(statusIcon)

        siteImageView.snp.remakeConstraints { make in
            make.top.equalTo(contentView).offset(SimpleHighlightCellUX.CellTopBottomOffset)
            make.bottom.equalTo(contentView).offset(-SimpleHighlightCellUX.CellTopBottomOffset).priority(10)
            make.leading.equalTo(contentView).offset(SimpleHighlightCellUX.CellSideOffset)
            make.size.equalTo(SimpleHighlightCellUX.SiteImageViewSize)
        }

        selectedOverlay.snp.remakeConstraints { make in
            make.edges.equalTo(contentView)
        }

        titleLabel.snp.remakeConstraints { make in
            make.leading.equalTo(siteImageView.snp.trailing).offset(SimpleHighlightCellUX.CellTopBottomOffset)
            make.trailing.equalTo(contentView).inset(SimpleHighlightCellUX.CellSideOffset)
            make.top.equalTo(siteImageView)
        }

        descriptionLabel.snp.remakeConstraints { make in
            make.leading.equalTo(statusIcon.snp.trailing).offset(SimpleHighlightCellUX.TitleLabelOffset)
            make.bottom.equalTo(statusIcon)
        }

        timeStamp.snp.remakeConstraints { make in
            make.trailing.equalTo(contentView).inset(SimpleHighlightCellUX.CellSideOffset)
            make.bottom.equalTo(descriptionLabel)
        }

        statusIcon.snp.remakeConstraints { make in
            make.leading.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp.bottom).offset(SimpleHighlightCellUX.CellTopBottomOffset)
            make.size.equalTo(SimpleHighlightCellUX.StatusIconSize)
            make.bottom.equalTo(contentView).offset(-SimpleHighlightCellUX.AlternateBottomOffset).priority(1000)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setImageWithURL(_ url: URL) {
        siteImageView.sd_setImage(with: url) { (img, err, type, url) -> Void in
            guard let img = img else {
                return
            }
            // Resize an Image to a specfic size to make sure that it doesnt appear bigger than it needs to (32px) inside a larger frame (48px).
            self.siteImageView.image = img.createScaled(SimpleHighlightCellUX.IconSize)
            self.siteImageView.image?.getColors(scaleDownSize: CGSize(width: 25, height: 25)) { colors in
                self.siteImageView.backgroundColor = colors.backgroundColor ?? UIColor.lightGray
            }
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        self.siteImageView.image = nil
        self.timeStamp.text = nil
    }

    func configureWithSite(_ site: Site) {

        if let icon = site.icon, let url = URL(string:icon.url) {
            self.setImageWithURL(url)
        } else {
            let url = URL(string: site.url)!
            self.siteImageView.image = FaviconFetcher.getDefaultFavicon(url)
            self.siteImageView.backgroundColor = FaviconFetcher.getDefaultColor(url)
        }

        self.titleLabel.text = site.title.characters.count <= 1 ? site.url : site.title
        configureCellStatus(site)
        if let date = site.latestVisit?.date {
            self.timeStamp.text = Date.fromMicrosecondTimestamp(date).toRelativeTimeString()
        }
    }

    func configureCellStatus(_ site: Site) {
        if let bookmarked = site.bookmarked, bookmarked {
            self.descriptionLabel.text = "Bookmarked"
            self.statusIcon.image = UIImage(named: "context_bookmark")
        } else {
            self.descriptionLabel.text = "Visited"
            self.statusIcon.image = UIImage(named: "context_viewed")
        }
    }
}
