// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

// MARK: - FxHomePocketDiscoverMoreCell
/// A cell to be placed at the last position in the Pocket section
class PocketDiscoverCell: BlurrableCollectionViewCell, ReusableCell {

    struct UX {
        static let discoverMoreFontSize: CGFloat = 20
        static let horizontalMargin: CGFloat = 16
        static let generalCornerRadius: CGFloat = 12
        static let shadowOffset: CGFloat = 2
    }

    // MARK: - UI Elements
    let itemTitle: UILabel = .build { label in
        label.adjustsFontForContentSizeCategory = true
        label.font = DynamicFontHelper.defaultHelper.preferredBoldFont(withTextStyle: .title3,
                                                                       size: UX.discoverMoreFontSize)
        label.numberOfLines = 0
        label.textAlignment = .left
    }

    // MARK: - Variables
    var notificationCenter: NotificationProtocol = NotificationCenter.default

    // MARK: - Initializers
    override init(frame: CGRect) {
        super.init(frame: .zero)

        setupNotifications(forObserver: self,
                           observing: [.DisplayThemeChanged,
                                       .WallpaperDidChange])
        setupLayout()
        applyTheme()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        itemTitle.text = nil
    }

    deinit {
        notificationCenter.removeObserver(self)
    }

    func configure(text: String) {
        itemTitle.text = text
        adjustLayout()
    }

    // MARK: - Helpers

    private func setupLayout() {
        setupShadow()
        contentView.addSubviews(itemTitle)

        NSLayoutConstraint.activate([
            itemTitle.leadingAnchor.constraint(equalTo: contentView.leadingAnchor,
                                               constant: UX.horizontalMargin),
            itemTitle.trailingAnchor.constraint(equalTo: contentView.trailingAnchor,
                                                constant: -UX.horizontalMargin),
            itemTitle.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }

    private func adjustLayout() {
        if shouldApplyWallpaperBlur {
            contentView.addBlurEffectWithClearBackgroundAndClipping(using: .systemThickMaterial)
        } else {
            contentView.removeVisualEffectView()
            contentView.backgroundColor = LegacyThemeManager.instance.currentName == .dark ?
            UIColor.Photon.DarkGrey30 : .white
            setupShadow()
        }
    }

    private func setupShadow() {
        contentView.layer.cornerRadius = UX.generalCornerRadius
        contentView.layer.shadowPath = UIBezierPath(roundedRect: contentView.bounds,
                                                    cornerRadius: UX.generalCornerRadius).cgPath
        contentView.layer.shadowRadius = PocketStandardCell.UX.shadowRadius
        contentView.layer.shadowOffset = CGSize(width: 0, height: UX.shadowOffset)
        contentView.layer.shadowColor = UIColor.theme.homePanel.shortcutShadowColor
        contentView.layer.shadowOpacity = 0.12
    }
}

// MARK: - Theme
extension PocketDiscoverCell: NotificationThemeable {
    func applyTheme() {
        if LegacyThemeManager.instance.currentName == .dark {
            itemTitle.textColor = UIColor.Photon.LightGrey10
        } else {
            itemTitle.textColor = UIColor.Photon.DarkGrey90
        }
    }
}

// MARK: - Notifiable
extension PocketDiscoverCell: Notifiable {
    func handleNotifications(_ notification: Notification) {
        ensureMainThread { [weak self] in
            switch notification.name {
            case .DisplayThemeChanged:
                self?.applyTheme()
            case .WallpaperDidChange:
                self?.adjustLayout()
            default: break
            }
        }
    }
}
