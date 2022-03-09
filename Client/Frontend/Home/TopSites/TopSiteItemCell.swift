// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
import Shared
import SDWebImage
import Storage

/// The TopSite cell that appears in the ASHorizontalScrollView.
class TopSiteItemCell: UICollectionViewCell, NotificationThemeable {

    struct UX {
        static let titleHeight: CGFloat = 20
        static let cellCornerRadius: CGFloat = 8
        static let titleOffset: CGFloat = 4
        static let overlayColor = UIColor(white: 0.0, alpha: 0.25)
        static let iconSize = CGSize(width: 36, height: 36)
        static let iconCornerRadius: CGFloat = 4
        static let backgroundSize = CGSize(width: 60, height: 60)
        static let shadowRadius: CGFloat = 6
        static let borderColor = UIColor(white: 0, alpha: 0.1)
        static let borderWidth: CGFloat = 0.5
        static let pinIconSize: CGFloat = 12
    }

    var url: URL?

    lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.layer.cornerRadius = UX.iconCornerRadius
        imageView.layer.masksToBounds = true
        return imageView
    }()

    lazy var titleWrapper = UIView()

    lazy var pinImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage.templateImageNamed("pin_small")
        return imageView
    }()

    lazy fileprivate var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.textAlignment = .center
        titleLabel.font = UIFont.preferredFont(forTextStyle: .caption1)
        titleLabel.preferredMaxLayoutWidth = UX.backgroundSize.width + TopSiteItemCell.UX.shadowRadius
        return titleLabel
    }()

    lazy private var faviconBG: UIView = {
        let view = UIView()
        view.layer.cornerRadius = UX.cellCornerRadius
        view.layer.borderWidth = UX.borderWidth
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = UX.shadowRadius
        return view
    }()

    lazy var selectedOverlay: UIView = {
        let selectedOverlay = UIView()
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
        isAccessibilityElement = true
        accessibilityIdentifier = "TopSite"
        contentView.addSubview(titleWrapper)
        titleWrapper.addSubview(titleLabel)
        contentView.addSubview(faviconBG)
        faviconBG.addSubview(imageView)
        contentView.addSubview(selectedOverlay)

        titleWrapper.snp.makeConstraints { make in
            make.top.equalTo(faviconBG.snp.bottom).offset(8)
            make.bottom.centerX.equalTo(contentView)
            make.width.lessThanOrEqualTo(UX.backgroundSize.width + 20)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleWrapper)
            make.leading.trailing.equalTo(titleWrapper)
        }

        imageView.snp.makeConstraints { make in
            make.size.equalTo(UX.iconSize)
            make.center.equalTo(faviconBG)
        }

        selectedOverlay.snp.makeConstraints { make in
            make.edges.equalTo(contentView)
        }

        faviconBG.snp.makeConstraints { make in
            make.top.centerX.equalTo(contentView)
            make.size.equalTo(UX.backgroundSize)
        }

        pinImageView.snp.makeConstraints { make in
            make.size.equalTo(UX.pinIconSize)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        contentView.backgroundColor = UIColor.clear
        imageView.image = nil
        imageView.backgroundColor = UIColor.clear
        faviconBG.backgroundColor = UIColor.clear
        pinImageView.removeFromSuperview()
        imageView.sd_cancelCurrentImageLoad()
        titleLabel.text = ""
    }

    func configureWithTopSiteItem(_ site: Site) {
        url = site.tileURL

        if let provider = site.metadata?.providerName {
            titleLabel.text = provider.lowercased()
        } else {
            titleLabel.text = site.tileURL.shortDisplayString
        }

        let words = titleLabel.text?.components(separatedBy: NSCharacterSet.whitespacesAndNewlines).count
        titleLabel.numberOfLines = words == 1 ? 1 : 2

        // If its a pinned site add a bullet point to the front
        if let _ = site as? PinnedSite {
            titleWrapper.addSubview(pinImageView)
            pinImageView.snp.makeConstraints { make in
                make.trailing.equalTo(self.titleLabel.snp.leading).offset(-UX.titleOffset)
                make.centerY.equalTo(self.titleLabel.snp.centerY)
            }
            titleLabel.snp.updateConstraints { make in
                make.leading.equalTo(titleWrapper).offset(UX.pinIconSize + UX.titleOffset)
            }
        } else {
            titleLabel.snp.updateConstraints { make in
                make.leading.equalTo(titleWrapper)
            }
        }

        accessibilityLabel = titleLabel.text
        self.imageView.setFaviconOrDefaultIcon(forSite: site) {}

        applyTheme()
    }

    func applyTheme() {
        pinImageView.tintColor = UIColor.theme.homePanel.topSitePin
        titleLabel.textColor = UIColor.theme.homePanel.topSiteDomain
        faviconBG.backgroundColor = UIColor.theme.homePanel.shortcutBackground
        faviconBG.layer.borderColor = UX.borderColor.cgColor
        faviconBG.layer.shadowColor = UIColor.theme.homePanel.shortcutShadowColor
        faviconBG.layer.shadowOpacity = UIColor.theme.homePanel.shortcutShadowOpacity
        selectedOverlay.backgroundColor = UX.overlayColor
        titleLabel.backgroundColor = UIColor.clear
    }
}
