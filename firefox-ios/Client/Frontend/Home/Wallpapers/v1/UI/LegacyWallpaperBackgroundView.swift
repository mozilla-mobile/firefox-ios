// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

class LegacyWallpaperBackgroundView: UIView {
    // MARK: - UI Elements
    private lazy var pictureView: UIImageView = .build { imageView in
        imageView.image = nil
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
    }

    // MARK: - Variables
    private var wallpaperManager = WallpaperManager()
    var notificationCenter: NotificationProtocol = NotificationCenter.default

    // MARK: - Initializers & Setup
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        setupNotifications(forObserver: self,
                           observing: [.WallpaperDidChange])

        updateImageToCurrentWallpaper()
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
        updateImageToCurrentWallpaper()
    }

    private func updateImageToCurrentWallpaper() {
        ensureMainThread {
            let currentWallpaper = self.currentWallpaperImage()
            UIView.animate(withDuration: 0.3) {
                self.pictureView.image = currentWallpaper
            }
        }
    }

    private func currentWallpaperImage() -> UIImage? {
        let isLandscape = UIDevice.current.orientation.isLandscape
        return isLandscape ? wallpaperManager.currentWallpaper.landscape : wallpaperManager.currentWallpaper.portrait
    }
}

// MARK: - Notifiable
extension LegacyWallpaperBackgroundView: Notifiable {
    func handleNotifications(_ notification: Notification) {
        switch notification.name {
        case .WallpaperDidChange: updateImageToCurrentWallpaper()
        default: break
        }
    }
}
