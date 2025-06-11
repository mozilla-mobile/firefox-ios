// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import SiteImageView

/// A supplementary view shown below the `ExperimentTabCell` containing the tab favicon and title
final class TabTitleSupplementaryView: UICollectionReusableView, ThemeApplicable, ReusableCell {
    struct UX {
        static let tabViewFooterSpacing: CGFloat = 4
        static let faviconSize = CGSize(width: 16, height: 16)
        static let bottomAnchorText: CGFloat = 8
    }

    private lazy var footerView: UIStackView = .build { stackView in
        stackView.axis = .horizontal
        stackView.distribution = .fill
        stackView.alignment = .center
        stackView.spacing = UX.tabViewFooterSpacing
        stackView.backgroundColor = .clear
    }

    private lazy var titleText: UILabel = .build { label in
        label.numberOfLines = 1
        label.font = FXFontStyles.Regular.footnote.scaledFont()
        label.adjustsFontForContentSizeCategory = true
        label.isAccessibilityElement = false
        label.textAlignment = .center
        label.setContentHuggingPriority(.defaultHigh, for: .horizontal)
    }

    private lazy var favicon: FaviconImageView = .build()
    private lazy var faviconContainer: UIView = .build()

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(footerView)
        footerView.addArrangedSubview(faviconContainer)
        footerView.addArrangedSubview(titleText)
        faviconContainer.addSubview(favicon)

        NSLayoutConstraint.activate([
            footerView.topAnchor.constraint(equalTo: bottomAnchor, constant: UX.bottomAnchorText),
            footerView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor),
            footerView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor),
            footerView.centerXAnchor.constraint(equalTo: centerXAnchor),

            faviconContainer.topAnchor.constraint(lessThanOrEqualTo: favicon.topAnchor),
            faviconContainer.bottomAnchor.constraint(greaterThanOrEqualTo: favicon.bottomAnchor),
            faviconContainer.leadingAnchor.constraint(equalTo: favicon.leadingAnchor),
            faviconContainer.trailingAnchor.constraint(equalTo: favicon.trailingAnchor),

            favicon.heightAnchor.constraint(equalToConstant: UX.faviconSize.height),
            favicon.widthAnchor.constraint(equalToConstant: UX.faviconSize.width),
            favicon.centerYAnchor.constraint(equalTo: titleText.centerYAnchor),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        favicon.layer.cornerRadius = UX.faviconSize.height / 2
    }

    func configure(with tabModel: TabModel, theme: Theme?) {
        titleText.text = tabModel.tabTitle

        let identifier = StandardImageIdentifiers.Large.globe
        if let globeFavicon = UIImage(named: identifier)?.withRenderingMode(.alwaysTemplate) {
            favicon.manuallySetImage(globeFavicon)
        }

        if !tabModel.isFxHomeTab, let tabURL = tabModel.url?.absoluteString {
            favicon.setFavicon(FaviconImageViewModel(siteURLString: tabURL))
        }

        if let theme {
            applyTheme(theme: theme)
        }
    }

    func applyTheme(theme: Theme) {
        titleText.textColor = theme.colors.textPrimary
        favicon.tintColor = theme.colors.textPrimary
    }
}
