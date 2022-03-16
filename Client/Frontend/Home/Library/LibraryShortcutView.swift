// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Shared
import UIKit
import Storage

class LibraryShortcutView: UIView {

    var notificationCenter: NotificationCenter = NotificationCenter.default

    struct UX {
        static let viewHeight: CGFloat = 90
        static let buttonSize = CGSize(width: 60, height: 60)
        static let imageSize = CGSize(width: 22, height: 22)
        static let spacing: CGFloat = 8
    }

    private lazy var button: ActionButton = .build { button in
        button.imageView?.layer.masksToBounds = true
        button.layer.cornerRadius = 8
        button.layer.borderColor = UIColor(white: 0.0, alpha: 0.1).cgColor
        button.layer.borderWidth = 0.5

        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 6
        let shadowRect = CGRect(width: UX.buttonSize.width, height: UX.buttonSize.height)
        button.layer.shadowPath = UIBezierPath(rect: shadowRect).cgPath
    }

    private lazy var titleLabel: UILabel = .build { titleLabel in
        titleLabel.textAlignment = .center
        titleLabel.lineBreakMode = .byWordWrapping
        titleLabel.font = UIFont.preferredFont(forTextStyle: .caption1)
        titleLabel.preferredMaxLayoutWidth = 70
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(button)
        addSubview(titleLabel)


        NSLayoutConstraint.activate([
            widthAnchor.constraint(greaterThanOrEqualToConstant: UX.buttonSize.width),
            heightAnchor.constraint(equalToConstant: UX.viewHeight),

            button.widthAnchor.constraint(equalToConstant: UX.buttonSize.width),
            button.heightAnchor.constraint(equalToConstant: UX.buttonSize.height),
            button.centerXAnchor.constraint(equalTo: centerXAnchor),
            button.topAnchor.constraint(equalTo: topAnchor),

            titleLabel.topAnchor.constraint(equalTo: button.bottomAnchor, constant: UX.spacing),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
        ])

        setupNotifications(forObserver: self, observing: [.DisplayThemeChanged])
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        notificationCenter.removeObserver(self)
    }

    func configure(_ panel: ASLibraryCell.LibraryPanel, action: @escaping (UIButton) -> Void) {
        button.setImage(panel.image, for: .normal)
        button.touchUpAction = action
        button.tintColor = panel.color

        titleLabel.text = panel.title
        let words = titleLabel.text?.components(separatedBy: NSCharacterSet.whitespacesAndNewlines).count
        titleLabel.numberOfLines = words == 1 ? 1 : 2

        applyTheme()
    }
}

// MARK: NotificationThemeable
extension LibraryShortcutView: NotificationThemeable {
    func applyTheme() {
        titleLabel.textColor = UIColor.theme.homePanel.activityStreamCellTitle
        button.backgroundColor = UIColor.theme.homePanel.shortcutBackground
        button.layer.shadowColor = UIColor.theme.homePanel.shortcutShadowColor
        button.layer.shadowOpacity = UIColor.theme.homePanel.shortcutShadowOpacity
    }
}

// MARK: - Notifiable
extension LibraryShortcutView: Notifiable {
    func handleNotifications(_ notification: Notification) {
        switch notification.name {
        case .DisplayThemeChanged:
            applyTheme()
        default: break
        }
    }
}
