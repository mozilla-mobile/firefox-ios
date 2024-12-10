// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit
import Storage
import Shared
import SiteImageView

class PhotonActionSheetSiteHeaderView: UITableViewHeaderFooterView, ReusableCell, ThemeApplicable {
    struct UX {
        static let borderWidth: CGFloat = 0.5
        static let padding: CGFloat = 12
        static let verticalPadding: CGFloat = 2
        static let siteImageViewSize: CGFloat = 52
    }

    private lazy var labelContainerView: UIView = .build { _ in }

    private lazy var titleLabel: UILabel = .build { label in
        label.font = FXFontStyles.Bold.body.scaledFont()
        label.textAlignment = .left
        label.numberOfLines = 2
    }

    private lazy var descriptionLabel: UILabel = .build { label in
        label.font = FXFontStyles.Regular.body.scaledFont()
        label.textAlignment = .left
        label.numberOfLines = 1
    }

    private lazy var imageView: FaviconImageView = .build { _ in }

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        translatesAutoresizingMaskIntoConstraints = false
        setupLayout()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with site: Site) {
        imageView.setFavicon(FaviconImageViewModel(siteURLString: site.url))
        titleLabel.text = site.title.isEmpty ? site.url : site.title
        descriptionLabel.text = site.tileURL.baseDomain
    }

    func configure(with bookmarkFolderTitle: String) {
        imageView.manuallySetImage(UIImage(resource: .folderLarge))
        titleLabel.text = bookmarkFolderTitle
    }

    func applyTheme(theme: Theme) {
        imageView.layer.borderColor = theme.colors.borderPrimary.cgColor
        titleLabel.textColor = theme.colors.textPrimary
        descriptionLabel.textColor = theme.colors.textPrimary
    }

    private func setupLayout() {
        backgroundView = UIView()
        backgroundView?.backgroundColor = .clear
        contentView.addSubview(imageView)

        labelContainerView.addSubview(titleLabel)
        labelContainerView.addSubview(descriptionLabel)
        contentView.addSubview(labelContainerView)

        let padding = PhotonActionSheetSiteHeaderView.UX.padding

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor, constant: padding),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            imageView.widthAnchor.constraint(equalToConstant: UX.siteImageViewSize),
            imageView.heightAnchor.constraint(equalToConstant: UX.siteImageViewSize),
            imageView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -padding),
            imageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            labelContainerView.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: padding),
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
