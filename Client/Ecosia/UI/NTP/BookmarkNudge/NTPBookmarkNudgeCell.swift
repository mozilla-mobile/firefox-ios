// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Core
import Common

final class NTPBookmarkNudgeCell: UICollectionViewCell, Themeable, ReusableCell {
    
    private enum UX {
        static let BackgroundCardCornerRadius: CGFloat = 8
        static let CloseButtonImageInset: CGFloat = 10
        static let OpenBookmarksButtonTitleFont = UIFontMetrics(forTextStyle: .callout).scaledFont(for: .systemFont(ofSize: 16))
        static let OpenBookmarksButtonTitleInset: CGFloat = 12
        static let OpenBookmarksButtonCornerRadius: CGFloat = 15
        static let OpenBookmarksButtonBorderWidth: CGFloat = 1
        static let OpenBookmarksButtonHeight: CGFloat = 32
        static let CloseButtonDimensions: CGFloat = 44
        static let IconDimensions: CGFloat = 64
        static let InsetMargin: CGFloat = 16
        static let BadgeHeight: CGFloat = 20
        
    }
    
    private let backgroundCard: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = UX.BackgroundCardCornerRadius
        return view
    }()
    
    private let badge: NTPBookmarkNudgeCellBadge = {
        let view = NTPBookmarkNudgeCellBadge()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let closeButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(named: "xmark"), for: .normal)
        button.imageView?.contentMode = .scaleAspectFill
        button.imageEdgeInsets = UIEdgeInsets(equalInset: UX.CloseButtonImageInset)
        return button
    }()
    
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setContentHuggingPriority(.required, for: .vertical)
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        label.text = .localized(.bookmarksNtpNudgeCardDescription)
        label.numberOfLines = 0
        return label
    }()
    
    private let openBookmarksButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer.cornerRadius = UX.OpenBookmarksButtonCornerRadius
        button.layer.borderWidth = UX.OpenBookmarksButtonBorderWidth
        button.setTitle(.localized(.bookmarksNtpNudgeCardButtonTitle), for: .normal)
        button.titleLabel?.font = UX.OpenBookmarksButtonTitleFont
        button.contentEdgeInsets = UIEdgeInsets(horizontal: UX.OpenBookmarksButtonTitleInset)
        return button
    }()
     
    private let icon: UIImageView = {
        let imageView = UIImageView(image: .init(named: "bookmarkImportExport"))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    var openBookmarksHandler: (() -> Void)?
    var closeHandler: (() -> Void)?
    
    // MARK: - Themeable Properties
    
    var themeManager: ThemeManager { AppContainer.shared.resolve() }
    var themeObserver: NSObjectProtocol?
    var notificationCenter: NotificationProtocol = NotificationCenter.default

    // MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        contentView.addSubview(backgroundCard)
        backgroundCard.addSubview(badge)
        backgroundCard.addSubview(closeButton)
        backgroundCard.addSubview(descriptionLabel)
        backgroundCard.addSubview(openBookmarksButton)
        backgroundCard.addSubview(icon)
        
        NSLayoutConstraint.activate([
            backgroundCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            backgroundCard.topAnchor.constraint(equalTo: contentView.topAnchor, constant: UX.InsetMargin),
            backgroundCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            badge.heightAnchor.constraint(equalToConstant: UX.BadgeHeight).priority(.required),
            badge.topAnchor.constraint(equalTo: backgroundCard.topAnchor, constant: UX.InsetMargin),
            badge.leadingAnchor.constraint(equalTo: backgroundCard.leadingAnchor, constant: UX.InsetMargin),
            
            closeButton.widthAnchor.constraint(equalToConstant: UX.CloseButtonDimensions),
            closeButton.heightAnchor.constraint(equalToConstant: UX.CloseButtonDimensions),
            closeButton.trailingAnchor.constraint(equalTo: backgroundCard.trailingAnchor),
            closeButton.topAnchor.constraint(equalTo: backgroundCard.topAnchor),
            
            descriptionLabel.topAnchor.constraint(equalTo: badge.bottomAnchor, constant: UX.InsetMargin / 2),
            descriptionLabel.leadingAnchor.constraint(equalTo: backgroundCard.leadingAnchor, constant: UX.InsetMargin),
            descriptionLabel.trailingAnchor.constraint(equalTo: icon.leadingAnchor, constant: -UX.InsetMargin),
            
            openBookmarksButton.heightAnchor.constraint(equalToConstant: UX.OpenBookmarksButtonHeight).priority(.required),
            openBookmarksButton.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: UX.InsetMargin),
            openBookmarksButton.leadingAnchor.constraint(equalTo: backgroundCard.leadingAnchor, constant: UX.InsetMargin),
            backgroundCard.bottomAnchor.constraint(equalTo: openBookmarksButton.bottomAnchor, constant: UX.InsetMargin),
            
            icon.trailingAnchor.constraint(equalTo: backgroundCard.trailingAnchor, constant: -UX.InsetMargin),
            icon.bottomAnchor.constraint(equalTo: openBookmarksButton.bottomAnchor, constant: 0),
            icon.widthAnchor.constraint(equalToConstant: UX.IconDimensions).priority(.required),
            icon.heightAnchor.constraint(equalToConstant: UX.IconDimensions).priority(.required)
        ])
        
        closeButton.addTarget(self, action: #selector(handleClose), for: .touchUpInside)
        openBookmarksButton.addTarget(self, action: #selector(handleOpenBookmarks), for: .touchUpInside)
        applyTheme()
        listenForThemeChange(self.contentView)
    }
    
    @objc func applyTheme() {
        backgroundCard.backgroundColor = .legacyTheme.ecosia.ntpCellBackground
        openBookmarksButton.setTitleColor(.legacyTheme.ecosia.primaryText, for: .normal)
        openBookmarksButton.layer.borderColor = UIColor.legacyTheme.ecosia.primaryText.cgColor
        closeButton.tintColor = .legacyTheme.ecosia.primaryText

        badge.applyTheme()
    }
    
    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
            let targetSize = CGSize(width: layoutAttributes.frame.width, height: 0)
            layoutAttributes.frame.size = contentView.systemLayoutSizeFitting(targetSize, withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel)
            return layoutAttributes
    }
    
    @objc private func handleOpenBookmarks() {
        Analytics.shared.bookmarksNtp(action: .click)
        openBookmarksHandler?()
    }
    
    @objc private func handleClose() {
        Analytics.shared.bookmarksNtp(action: .close)
        closeHandler?()
    }
}

private final class NTPBookmarkNudgeCellBadge: UIView, Themeable {

    private enum UX {
        static let LabelInsetX: CGFloat = 8
        static let LabelInsetY: CGFloat = 2.5
        static let CornerRadius: CGFloat = 10
        static let HeightInset: CGFloat = 5
        static let WidthInset: CGFloat = 16
    }
    
    private let badgeLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .preferredFont(forTextStyle: .footnote).bold()
        label.adjustsFontForContentSizeCategory = true
        label.text = .localized(.new)
        return label
    }()
    
    // MARK: - Themeable Properties
    
    var themeManager: ThemeManager { AppContainer.shared.resolve() }
    var themeObserver: NSObjectProtocol?
    var notificationCenter: NotificationProtocol = NotificationCenter.default

    // MARK: - Init

    init() {
        super.init(frame: .zero)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        isUserInteractionEnabled = false
        
        addSubview(badgeLabel)

        let size = badgeLabel.sizeThatFits(.init(width: CGFloat.greatestFiniteMagnitude, height: .greatestFiniteMagnitude))
        frame.size = .init(width: size.width + UX.WidthInset, height: size.height + UX.HeightInset)
        layer.cornerRadius = UX.CornerRadius
        
        NSLayoutConstraint.activate([
            badgeLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: UX.LabelInsetX),
            badgeLabel.topAnchor.constraint(equalTo: topAnchor, constant: UX.LabelInsetY),
            badgeLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -UX.LabelInsetX),
            badgeLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -UX.LabelInsetY)
        ])
        
        applyTheme()
    }
    
    func applyTheme() {
        backgroundColor = .legacyTheme.ecosia.primaryBrand
        badgeLabel.textColor = .legacyTheme.ecosia.primaryTextInverted
    }
}
