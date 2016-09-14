/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Shared
import Storage

struct HighlightCellUX {
    static let BorderColor = UIColor.blackColor().colorWithAlphaComponent(0.1)
    static let BorderWidth = CGFloat(0.5)
    static let LabelColor = UIAccessibilityDarkerSystemColorsEnabled() ? UIColor.blackColor() : UIColor(rgb: 0x353535)
    static let LabelBackgroundColor = UIColor(white: 1.0, alpha: 0.5)
    static let LabelAlignment: NSTextAlignment = .Left
    static let SelectedOverlayColor = UIColor(white: 0.0, alpha: 0.25)
    static let PlaceholderImage = UIImage(named: "defaultTopSiteIcon")
    static let CornerRadius: CGFloat = 3
    static let NearestNeighbordScalingThreshold: CGFloat = 24
}

class HighlightCell: UITableViewCell {
    var siteImage: UIImage? = nil {
        didSet {
            if let image = siteImage {
                siteImageView.image = image
                siteImageView.contentMode = UIViewContentMode.ScaleAspectFit

                // Force nearest neighbor scaling for small favicons
                if image.size.width < HighlightCellUX.NearestNeighbordScalingThreshold {
                    siteImageView.layer.shouldRasterize = true
                    siteImageView.layer.rasterizationScale = 2
                    siteImageView.layer.minificationFilter = kCAFilterNearest
                    siteImageView.layer.magnificationFilter = kCAFilterNearest
                }
            } else {
                siteImageView.image = HighlightCellUX.PlaceholderImage
                siteImageView.contentMode = UIViewContentMode.Center
            }
        }
    }

    lazy var titleLabel: UILabel = {
        let textLabel = UILabel()
        textLabel.setContentHuggingPriority(1000, forAxis: UILayoutConstraintAxis.Vertical)
        textLabel.font = DynamicFontHelper.defaultHelper.DeviceFontMediumBold
        textLabel.textColor = HighlightCellUX.LabelColor
        textLabel.textAlignment = HighlightCellUX.LabelAlignment
        textLabel.numberOfLines = 2
        return textLabel
    }()

    lazy var timeStamp: UILabel = {
        let textLabel = UILabel()
        textLabel.setContentHuggingPriority(1000, forAxis: UILayoutConstraintAxis.Vertical)
        textLabel.font = DynamicFontHelper.defaultHelper.DeviceFontSmallActivityStream
        textLabel.textColor = UIColor(colorString: "D4D4D4")
        textLabel.textAlignment = HighlightCellUX.LabelAlignment
        return textLabel
    }()

    lazy var siteImageView: UIImageView = {
        let siteImageView = UIImageView()
        siteImageView.contentMode = UIViewContentMode.ScaleAspectFit
        siteImageView.clipsToBounds = true
        siteImageView.layer.cornerRadius = HighlightCellUX.CornerRadius
        return siteImageView
    }()

    lazy var statusIcon: UIImageView = {
        let siteImageView = UIImageView()
        siteImageView.contentMode = UIViewContentMode.ScaleAspectFit
        siteImageView.clipsToBounds = true
        siteImageView.layer.cornerRadius = HighlightCellUX.CornerRadius
        return siteImageView
    }()

    lazy var descriptionLabel: UILabel = {
        let textLabel = UILabel()
        textLabel.setContentHuggingPriority(1000, forAxis: UILayoutConstraintAxis.Vertical)
        textLabel.font = DynamicFontHelper.defaultHelper.DeviceFontDescriptionActivityStream
        textLabel.textColor = UIColor(colorString: "919191")
        textLabel.textAlignment = .Left
        textLabel.numberOfLines = 1
        return textLabel
    }()

    lazy var backgroundImage: UIImageView = {
        let backgroundImage = UIImageView()
        backgroundImage.contentMode = UIViewContentMode.ScaleAspectFill
        backgroundImage.layer.borderColor = HighlightCellUX.BorderColor.CGColor
        backgroundImage.layer.borderWidth = HighlightCellUX.BorderWidth
        backgroundImage.layer.cornerRadius = HighlightCellUX.CornerRadius
        backgroundImage.clipsToBounds = true
        return backgroundImage
    }()

    lazy var selectedOverlay: UIView = {
        let selectedOverlay = UIView()
        selectedOverlay.backgroundColor = HighlightCellUX.SelectedOverlayColor
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
        contentView.addSubview(selectedOverlay)
        contentView.addSubview(backgroundImage)
        contentView.addSubview(siteImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(timeStamp)
        contentView.addSubview(descriptionLabel)
        contentView.addSubview(statusIcon)

        siteImageView.snp_makeConstraints { make in
            make.top.equalTo(backgroundImage)
            make.leading.equalTo(backgroundImage)
            make.size.equalTo(48)
        }

        backgroundImage.snp_makeConstraints { make in
            make.top.equalTo(contentView).offset(5)
            make.leading.equalTo(contentView).offset(20)
            make.trailing.equalTo(contentView).inset(20)
            make.height.equalTo(200)
        }

        selectedOverlay.snp_makeConstraints { make in
            make.edges.equalTo(contentView)
        }

        titleLabel.snp_remakeConstraints { make in
            make.leading.equalTo(contentView).offset(20)
            make.top.equalTo(backgroundImage.snp_bottom).offset(10)
            make.trailing.equalTo(timeStamp.snp_leading).offset(-5)
        }

        statusIcon.snp_makeConstraints { make in
            make.leading.equalTo(backgroundImage)
            make.top.equalTo(titleLabel.snp_bottom).offset(8)
            make.bottom.equalTo(contentView).offset(-12)
            make.size.equalTo(12)
        }

        descriptionLabel.snp_makeConstraints { make in
            make.leading.equalTo(statusIcon.snp_trailing).offset(10)
            make.bottom.equalTo(statusIcon)
        }

        timeStamp.snp_makeConstraints { make in
            make.trailing.equalTo(backgroundImage)
            make.bottom.equalTo(descriptionLabel)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        siteImageView.layer.borderWidth = 0
    }

    func setImageWithURL(url: NSURL) {
        siteImageView.sd_setImageWithURL(url) { (img, err, type, url) -> Void in
            guard let img = img else {
                return
            }
            self.siteImage = img
        }
        backgroundImage.sd_setImageWithURL(NSURL(string: "http://lorempixel.com/640/480/?r=" + String(random())))
        siteImageView.layer.masksToBounds = true
    }

    func configureHighlightCell(site: Site) {
        if let icon = site.icon {
            let url = icon.url
            self.setImageWithURL(NSURL(string: url)!)
        } else {
            self.siteImage = FaviconFetcher.getDefaultFavicon(NSURL(string: site.url)!)
            self.siteImageView.layer.borderWidth = 0.5
        }
        self.titleLabel.text = site.title.characters.count <= 1 ? site.url : site.title
        self.descriptionLabel.text = "Bookmarked"
        self.statusIcon.image = UIImage(named: "bookmarked_passive")
        self.timeStamp.text = "3 days ago"
    }
}