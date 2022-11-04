// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

// An empty cell to show when a row is incomplete
class EmptyTopSiteCell: UICollectionViewCell, ReusableCell {

    struct UX {
        static let borderColor = LegacyThemeManager.instance.current.homePanel.emptyTopSitesBorder
        static let horizontalMargin: CGFloat = 8
    }

    var notificationCenter: NotificationProtocol = NotificationCenter.default

    lazy private var emptyBG: UIView = .build { view in
        view.layer.cornerRadius = TopSiteItemCell.UX.cellCornerRadius
        view.layer.borderWidth = TopSiteItemCell.UX.borderWidth
        view.layer.borderColor = UX.borderColor.cgColor
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        setupLayout()
        applyTheme()
        setupNotifications(forObserver: self, observing: [.DisplayThemeChanged])
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLayout() {
        contentView.addSubview(emptyBG)

        NSLayoutConstraint.activate([
            emptyBG.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            emptyBG.widthAnchor.constraint(equalToConstant: TopSiteItemCell.UX.imageBackgroundSize.width),
            emptyBG.heightAnchor.constraint(equalToConstant: TopSiteItemCell.UX.imageBackgroundSize.height),
            emptyBG.topAnchor.constraint(equalTo: contentView.topAnchor),
        ])
    }

    private func applyTheme() {
        emptyBG.layer.borderColor = UX.borderColor.withAlphaComponent(0.2)
            .cgColor
    }
}

extension EmptyTopSiteCell: Notifiable {
    func handleNotifications(_ notification: Notification) {
        switch notification.name {
        case .DisplayThemeChanged:
            applyTheme()
        default: break
        }
    }
}
