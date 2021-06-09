/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Shared
import Storage

private struct FirefoxHomeHighlightCellUX {
    static let BorderWidth: CGFloat = 0.5
    static let CellSideOffset = 20
    static let TitleLabelOffset = 2
    static let CellTopBottomOffset = 12
    static let SiteImageViewSize = CGSize(width: 99, height: UIDevice.current.userInterfaceIdiom == .pad ? 120 : 90)
    static let StatusIconSize = 12
    static let FaviconSize = CGSize(width: 45, height: 45)
    static let SelectedOverlayColor = UIColor(white: 0.0, alpha: 0.25)
    static let CornerRadius: CGFloat = 3
    static let BorderColor = UIColor.Photon.Grey30
}

class FirefoxHomeHighlightCell: UICollectionViewCell {

    fileprivate lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.font = DynamicFontHelper.defaultHelper.MediumSizeHeavyWeightAS
        titleLabel.textColor = UIColor.theme.homePanel.activityStreamCellTitle
        titleLabel.textAlignment = .left
        titleLabel.numberOfLines = 3
        return titleLabel
    }()

    fileprivate lazy var descriptionLabel: UILabel = {
        let descriptionLabel = UILabel()
        descriptionLabel.font = DynamicFontHelper.defaultHelper.SmallSizeRegularWeightAS
        descriptionLabel.textColor = UIColor.theme.homePanel.activityStreamCellDescription
        descriptionLabel.textAlignment = .left
        descriptionLabel.numberOfLines = 1
        return descriptionLabel
    }()

    fileprivate lazy var domainLabel: UILabel = {
        let descriptionLabel = UILabel()
        descriptionLabel.font = DynamicFontHelper.defaultHelper.SmallSizeRegularWeightAS
        descriptionLabel.textColor = UIColor.theme.homePanel.activityStreamCellDescription
        descriptionLabel.textAlignment = .left
        descriptionLabel.numberOfLines = 1
        descriptionLabel.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 1000), for: .vertical)
        return descriptionLabel
    }()

    lazy var siteImageView: UIImageView = {
        let siteImageView = UIImageView()
        siteImageView.contentMode = .scaleAspectFit
        siteImageView.clipsToBounds = true
        siteImageView.contentMode = .center
        siteImageView.layer.cornerRadius = FirefoxHomeHighlightCellUX.CornerRadius
        siteImageView.layer.borderColor = FirefoxHomeHighlightCellUX.BorderColor.cgColor
        siteImageView.layer.borderWidth = FirefoxHomeHighlightCellUX.BorderWidth
        siteImageView.layer.masksToBounds = true
        return siteImageView
    }()

    fileprivate lazy var statusIcon: UIImageView = {
        let statusIcon = UIImageView()
        statusIcon.contentMode = .scaleAspectFit
        statusIcon.clipsToBounds = true
        statusIcon.layer.cornerRadius = FirefoxHomeHighlightCellUX.CornerRadius
        return statusIcon
    }()

    fileprivate lazy var selectedOverlay: UIView = {
        let selectedOverlay = UIView()
        selectedOverlay.backgroundColor = FirefoxHomeHighlightCellUX.SelectedOverlayColor
        selectedOverlay.isHidden = true
        return selectedOverlay
    }()

    fileprivate lazy var playLabel: UIImageView = {
        let view = UIImageView()
        view.image = UIImage.templateImageNamed("play")
        view.tintColor = .white
        view.alpha = 0.97
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.3
        view.layer.shadowRadius = 2
        view.isHidden = true
        return view
    }()

    fileprivate lazy var pocketTrendingIconNormal = UIImage(named: "context_pocket")?.tinted(withColor: UIColor.Photon.Grey90)
    fileprivate lazy var pocketTrendingIconDark = UIImage(named: "context_pocket")?.tinted(withColor: UIColor.Photon.Grey10)

    override var isSelected: Bool {
        didSet {
            self.selectedOverlay.isHidden = !isSelected
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        layer.shouldRasterize = true
        layer.rasterizationScale = UIScreen.main.scale

        isAccessibilityElement = true

        contentView.addSubview(siteImageView)
        contentView.addSubview(descriptionLabel)
        contentView.addSubview(selectedOverlay)
        contentView.addSubview(titleLabel)
        contentView.addSubview(statusIcon)
        contentView.addSubview(domainLabel)
        contentView.addSubview(playLabel)

        siteImageView.snp.makeConstraints { make in
            make.top.equalTo(contentView)
            make.leading.equalTo(contentView.safeArea.leading)
            make.trailing.equalTo(contentView.safeArea.trailing)
            make.centerX.equalTo(contentView)
            make.height.equalTo(FirefoxHomeHighlightCellUX.SiteImageViewSize)
        }

        selectedOverlay.snp.makeConstraints { make in
            make.edges.equalTo(contentView.safeArea.edges)
        }

        domainLabel.snp.makeConstraints { make in
            make.leading.equalTo(siteImageView)
            make.trailing.equalTo(contentView.safeArea.trailing)
            make.top.equalTo(siteImageView.snp.bottom).offset(5)
        }

        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(siteImageView)
            make.trailing.equalTo(contentView.safeArea.trailing)
            make.top.equalTo(domainLabel.snp.bottom).offset(5)
        }

        descriptionLabel.snp.makeConstraints { make in
            make.leading.equalTo(statusIcon.snp.trailing).offset(FirefoxHomeHighlightCellUX.TitleLabelOffset)
            make.bottom.equalTo(contentView)
        }

        statusIcon.snp.makeConstraints { make in
            make.size.equalTo(FirefoxHomeHighlightCellUX.StatusIconSize)
            make.centerY.equalTo(descriptionLabel.snp.centerY)
            make.leading.equalTo(siteImageView)
        }

        playLabel.snp.makeConstraints { make in
            make.center.equalTo(siteImageView.snp.center)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        self.siteImageView.image = nil
        contentView.backgroundColor = UIColor.clear
        siteImageView.backgroundColor = UIColor.clear
        playLabel.isHidden = true
        descriptionLabel.textColor = UIColor.theme.homePanel.activityStreamCellDescription
    }

    func configureWithSite(_ site: Site) {
        if let mediaURLStr = site.metadata?.mediaURL,
            let mediaURL = URL(string: mediaURLStr) {
            self.siteImageView.sd_setImage(with: mediaURL)
            self.siteImageView.contentMode = .scaleAspectFill
        } else {
            self.siteImageView.setFavicon(forSite: site) { [weak self]  in
                self?.siteImageView.image = self?.siteImageView.image?.createScaled(FirefoxHomeHighlightCellUX.FaviconSize)
            }
            self.siteImageView.contentMode = .center
        }

        self.domainLabel.text = site.tileURL.shortDisplayString
        self.titleLabel.text = site.title.isEmpty ? site.url : site.title

        if let bookmarked = site.bookmarked, bookmarked {
            self.descriptionLabel.text = Strings.HighlightBookmarkText
            self.statusIcon.image = UIImage(named: "context_bookmark")
        } else {
            self.descriptionLabel.text = Strings.HighlightVistedText
            self.statusIcon.image = UIImage(named: "context_viewed")
        }
    }

    func configureWithPocketStory(_ pocketStory: PocketStory) {
        self.siteImageView.sd_setImage(with: pocketStory.imageURL)
        self.siteImageView.contentMode = .scaleAspectFill

        self.domainLabel.text = pocketStory.domain
        self.titleLabel.text = pocketStory.title

        self.descriptionLabel.text = Strings.PocketTrendingText
        self.statusIcon.image = ThemeManager.instance.currentName == .dark ? pocketTrendingIconDark : pocketTrendingIconNormal
    }

    func configureWithPocketVideoStory(_ pocketStory: PocketStory) {
        playLabel.isHidden = false
        self.configureWithPocketStory(pocketStory)
    }

}
