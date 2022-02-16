// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UIKit

class WallpaperSettingCollectionCell: UICollectionViewCell, ReusableCell {

    // MARK: - UI Element
    private lazy var imageView: UIImageView = .build { imageView in
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        // Prevent iOS image recognition in VoiceOver from scanning the image.
        imageView.accessibilityTraits = .none
    }

    private lazy var borderView: UIView = .build { borderView in
        borderView.layer.cornerRadius = 10
        borderView.layer.borderWidth = 1
        borderView.backgroundColor = .clear
    }

    private lazy var selectedView: UIView = .build { selectedView in
        selectedView.layer.cornerRadius = 10
        selectedView.layer.borderWidth = 4
        selectedView.backgroundColor = .clear
        selectedView.alpha = 0.0
    }

    // MARK: - Variables
    var notificationCenter: NotificationCenter = NotificationCenter.default
    
    override var isSelected: Bool {
        didSet { selectedView.alpha = isSelected ? 1.0 : 0.0 }
    }
    
    // MARK: - Initializers
    override init(frame: CGRect) {
        super.init(frame: frame)

        setupView()
        setupNotifications(forObserver: self,
                           observing: [.DisplayThemeChanged])
        applyTheme()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        notificationCenter.removeObserver(self)
    }

    // MARK: - View
    override func layoutSubviews() {
        super.layoutSubviews()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
    }

    private func setupView() {
        contentView.addSubview(borderView)
        contentView.addSubview(imageView)
        contentView.addSubview(selectedView)
        contentView.layer.cornerRadius = 10
        contentView.clipsToBounds = true

        NSLayoutConstraint.activate([
            borderView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            borderView.topAnchor.constraint(equalTo: contentView.topAnchor),
            borderView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            borderView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            selectedView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            selectedView.topAnchor.constraint(equalTo: contentView.topAnchor),
            selectedView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            selectedView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
    }

    // MARK: - Methods
    public func updateImage(to image: UIImage?) {
        guard let image = image else { return }
        imageView.image = image
    }
}

// MARK: - Notifications
extension WallpaperSettingCollectionCell: Notifiable {
    func handleNotifications(_ notification: Notification) {
        switch notification.name {
        case .DisplayThemeChanged:
            applyTheme()
        default:
            break
        }
    }
}

extension WallpaperSettingCollectionCell: NotificationThemeable {
    func applyTheme() {
        contentView.backgroundColor = UIColor.theme.homePanel.topSitesBackground
        borderView.layer.borderColor = UIColor.theme.etpMenu.horizontalLine.cgColor
        selectedView.layer.borderColor = UIColor.theme.etpMenu.switchAndButtonTint.cgColor
    }
}
