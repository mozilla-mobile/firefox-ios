// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Storage

// MARK: - PhotonActionSheetSiteHeaderView
class PhotonActionSheetSiteHeaderView: UITableViewHeaderFooterView {

    struct UX {
        static let padding: CGFloat = 12
        static let verticalPadding: CGFloat = 2
    }

    lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.font = DynamicFontHelper.defaultHelper.MediumSizeBoldFontAS
        titleLabel.textAlignment = .left
        titleLabel.numberOfLines = 2
        return titleLabel
    }()

    lazy var descriptionLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.font = DynamicFontHelper.defaultHelper.MediumSizeRegularWeightAS
        titleLabel.textAlignment = .left
        titleLabel.numberOfLines = 1
        return titleLabel
    }()

    lazy var siteImageView: UIImageView = {
        let siteImageView = UIImageView()
        siteImageView.contentMode = .center
        siteImageView.clipsToBounds = true
        siteImageView.layer.cornerRadius = PhotonActionSheet.UX.CornerRadius
        siteImageView.layer.borderColor = PhotonActionSheet.UX.BorderColor.cgColor
        siteImageView.layer.borderWidth = PhotonActionSheet.UX.BorderWidth
        return siteImageView
    }()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)

        self.backgroundView = UIView()
        self.backgroundView?.backgroundColor = .clear
        contentView.addSubview(siteImageView)

        siteImageView.snp.remakeConstraints { make in
            make.top.equalTo(contentView).offset(PhotonActionSheetSiteHeaderView.UX.padding)
            make.centerY.equalTo(contentView)
            make.leading.equalTo(contentView).offset(PhotonActionSheetSiteHeaderView.UX.padding)
            make.size.equalTo(PhotonActionSheet.UX.SiteImageViewSize)
        }

        let stackView = UIStackView(arrangedSubviews: [titleLabel, descriptionLabel])
        stackView.spacing = PhotonActionSheetSiteHeaderView.UX.verticalPadding
        stackView.alignment = .leading
        stackView.axis = .vertical

        contentView.addSubview(stackView)

        stackView.snp.makeConstraints { make in
            make.leading.equalTo(siteImageView.snp.trailing).offset(PhotonActionSheetSiteHeaderView.UX.padding)
            make.trailing.equalTo(contentView).inset(PhotonActionSheetSiteHeaderView.UX.padding)
            make.centerY.equalTo(siteImageView.snp.centerY)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        self.siteImageView.image = nil
        self.siteImageView.backgroundColor = UIColor.clear
    }

    func configure(with site: Site) {
        if site.icon != nil {
            self.siteImageView.setFavicon(forSite: site) {
                self.siteImageView.image = self.siteImageView.image?.createScaled(PhotonActionSheet.UX.IconSize)
            }
        } else if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            let profile = appDelegate.profile
            profile.favicons.getFaviconImage(forSite: site).uponQueue(.main) { result in
                guard let image = result.successValue else { return }

                self.siteImageView.backgroundColor = .clear
                self.siteImageView.image = image.createScaled(PhotonActionSheet.UX.IconSize)
            }
        }
        self.titleLabel.text = site.title.isEmpty ? site.url : site.title
        self.descriptionLabel.text = site.tileURL.baseDomain
        self.titleLabel.textColor = LegacyThemeManager.instance.current.actionMenu.foreground
        self.descriptionLabel.textColor = LegacyThemeManager.instance.current.actionMenu.foreground

    }
}
