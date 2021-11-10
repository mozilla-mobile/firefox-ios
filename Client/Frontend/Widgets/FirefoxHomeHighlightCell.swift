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
    static let CornerRadius: CGFloat = 8
    static let BorderColor = UIColor.Photon.Grey30
}

class FirefoxHomeHighlightCell: UICollectionViewCell, NotificationThemeable {

    fileprivate lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.font = UIFont.preferredFont(forTextStyle: .headline)
        titleLabel.textAlignment = .left
        titleLabel.numberOfLines = 3
        return titleLabel
    }()

    fileprivate lazy var domainLabel: UILabel = {
        let descriptionLabel = UILabel()
        descriptionLabel.font = UIFont.preferredFont(forTextStyle: .caption1)
        descriptionLabel.textAlignment = .left
        descriptionLabel.numberOfLines = 1
        descriptionLabel.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 1000), for: .vertical)
        return descriptionLabel
    }()
    
    lazy var imageWrapperView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = FirefoxHomeHighlightCellUX.CornerRadius
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 6
        return view
    }()

    lazy var siteImageView: UIImageView = {
        let siteImageView = UIImageView()
        siteImageView.contentMode = .scaleAspectFit
        siteImageView.clipsToBounds = true
        siteImageView.contentMode = .center
        siteImageView.layer.cornerRadius = FirefoxHomeHighlightCellUX.CornerRadius
        siteImageView.layer.masksToBounds = true
        return siteImageView
    }()

    fileprivate lazy var selectedOverlay: UIView = {
        let selectedOverlay = UIView()
        selectedOverlay.backgroundColor = FirefoxHomeHighlightCellUX.SelectedOverlayColor
        selectedOverlay.isHidden = true
        return selectedOverlay
    }()

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

        imageWrapperView.addSubview(siteImageView)
        contentView.addSubview(imageWrapperView)
        contentView.addSubview(selectedOverlay)
        contentView.addSubview(titleLabel)
        contentView.addSubview(domainLabel)

        siteImageView.snp.makeConstraints { make in
            make.edges.equalTo(imageWrapperView)
        }

        imageWrapperView.snp.makeConstraints { make in
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
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        siteImageView.image = nil
        siteImageView.backgroundColor = UIColor.clear
        applyTheme()
    }

    func configureWithPocketStory(_ pocketStory: PocketStory) {
        siteImageView.sd_setImage(with: pocketStory.imageURL)
        siteImageView.contentMode = .scaleAspectFill

        domainLabel.text = pocketStory.domain
        titleLabel.text = pocketStory.title

        applyTheme()
    }

    func applyTheme() {
        titleLabel.textColor = UIColor.theme.homePanel.activityStreamHeaderText
        domainLabel.textColor = UIColor.theme.homePanel.activityStreamCellDescription
        imageWrapperView.layer.shadowColor = UIColor.theme.homePanel.shortcutShadowColor
        imageWrapperView.layer.shadowOpacity = UIColor.theme.homePanel.shortcutShadowOpacity
    }
}
