// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Storage
import Shared

class PhotonActionSheetSiteHeaderView: UITableViewHeaderFooterView, ReusableCell, ThemeApplicable {
    struct UX {
        static let borderWidth: CGFloat = 0.5
        static let padding: CGFloat = 12
        static let verticalPadding: CGFloat = 2
        static let siteImageViewSize: CGFloat = 52
    }

    private lazy var labelContainerView: UIView = .build { _ in }

    private lazy var titleLabel: UILabel = .build { label in
        label.font = DynamicFontHelper.defaultHelper.preferredBoldFont(withTextStyle: .body, size: 17)
        label.textAlignment = .left
        label.numberOfLines = 2
    }

    private lazy var descriptionLabel: UILabel = .build { label in
        label.font = DynamicFontHelper.defaultHelper.preferredFont(withTextStyle: .body, size: 17)
        label.textAlignment = .left
        label.numberOfLines = 1
    }

    private lazy var siteImageView: UIImageView = .build { imageView in
        imageView.contentMode = .center
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = PhotonActionSheet.UX.cornerRadius
        imageView.layer.borderWidth = UX.borderWidth
    }

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        translatesAutoresizingMaskIntoConstraints = false
        setupLayout()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        siteImageView.image = nil
        siteImageView.backgroundColor = UIColor.clear
    }

    func configure(with site: Site) {
        if site.icon != nil {
            siteImageView.setFavicon(forSite: site) {
                self.siteImageView.image = self.siteImageView.image?.createScaled(PhotonActionSheet.UX.iconSize)
            }
        } else if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            let profile = appDelegate.profile
            profile.favicons.getFaviconImage(forSite: site) { result in
                guard let image = result else { return }

                DispatchQueue.main.async {
                    self.siteImageView.backgroundColor = .clear
                    self.siteImageView.image = image.createScaled(PhotonActionSheet.UX.iconSize)
                }
            }
        }

        titleLabel.text = site.title.isEmpty ? site.url : site.title
        descriptionLabel.text = site.tileURL.baseDomain
    }

    func applyTheme(theme: Theme) {
        siteImageView.layer.borderColor = theme.colors.borderPrimary.cgColor
        titleLabel.textColor = theme.colors.textPrimary
        descriptionLabel.textColor = theme.colors.textPrimary
    }

    private func setupLayout() {
        backgroundView = UIView()
        backgroundView?.backgroundColor = .clear
        contentView.addSubview(siteImageView)

        labelContainerView.addSubview(titleLabel)
        labelContainerView.addSubview(descriptionLabel)
        contentView.addSubview(labelContainerView)

        let padding = PhotonActionSheetSiteHeaderView.UX.padding

        NSLayoutConstraint.activate([
            siteImageView.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor, constant: padding),
            siteImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            siteImageView.widthAnchor.constraint(equalToConstant: UX.siteImageViewSize),
            siteImageView.heightAnchor.constraint(equalToConstant: UX.siteImageViewSize),
            siteImageView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -padding),
            siteImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            labelContainerView.leadingAnchor.constraint(equalTo: siteImageView.trailingAnchor, constant: padding),
            labelContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            labelContainerView.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor, constant: padding),
            labelContainerView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor,
                                                       constant: -padding),
            labelContainerView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            titleLabel.leadingAnchor.constraint(equalTo: labelContainerView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: labelContainerView.trailingAnchor),
            titleLabel.topAnchor.constraint(equalTo: labelContainerView.topAnchor),

            descriptionLabel.leadingAnchor.constraint(equalTo: labelContainerView.leadingAnchor),
            descriptionLabel.trailingAnchor.constraint(equalTo: labelContainerView.trailingAnchor),
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor,
                                                  constant: PhotonActionSheetSiteHeaderView.UX.verticalPadding),
            descriptionLabel.bottomAnchor.constraint(equalTo: labelContainerView.bottomAnchor),
        ])
    }
}
