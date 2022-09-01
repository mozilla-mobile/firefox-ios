// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

class WallpaperBackgroundView: UIView {

    // MARK: - UI Elements
    private lazy var pictureView: UIImageView = .build { imageView in
        imageView.image = nil
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
    }

    // MARK: - Variables
    // TODO: Roux - this will need to hook into the new wallpaper manager
    private var wallpaperManager = LegacyWallpaperManager()
    var notificationCenter: NotificationProtocol = NotificationCenter.default

    // MARK: - Initializers & Setup
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        setupNotifications(forObserver: self,
                           observing: [.WallpaperDidChange])

        updateImageTo(wallpaperManager.currentWallpaperImage)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        notificationCenter.removeObserver(self)
    }

    private func setupView() {
        backgroundColor = .clear
        addSubview(pictureView)

        NSLayoutConstraint.activate([
            pictureView.leadingAnchor.constraint(equalTo: leadingAnchor),
            pictureView.topAnchor.constraint(equalTo: topAnchor),
            pictureView.bottomAnchor.constraint(equalTo: bottomAnchor),
            pictureView.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
    }

    // MARK: - Methods
    public func updateImageForOrientationChange() {
        updateImageTo(wallpaperManager.currentWallpaperImage)
    }

    private func updateImageTo(_ image: UIImage?) {
        UIView.animate(withDuration: 0.3) {
            self.pictureView.image = image
        }
    }
}

// MARK: - Notifiable
extension WallpaperBackgroundView: Notifiable {
    func handleNotifications(_ notification: Notification) {
        switch notification.name {
        case .WallpaperDidChange: updateImageTo(wallpaperManager.currentWallpaperImage)
        default: break
        }
    }
}
