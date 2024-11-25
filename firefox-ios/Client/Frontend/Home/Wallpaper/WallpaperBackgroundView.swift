// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common
import Redux

class WallpaperBackgroundView: UIView {
    // MARK: - UI Elements
    private lazy var pictureView: UIImageView = .build { imageView in
        imageView.image = nil
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
    }

    // MARK: - Variables
    var wallpaperState: WallpaperState? {
        didSet {
            updateImageToCurrentWallpaper()
        }
    }

    // MARK: - Initializers & Setup
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
        guard let state = wallpaperState else { return }
        ensureMainThread {
            let currentWallpaperImage = self.currentWallpaperImage(from: state)
            UIView.animate(withDuration: 0.3) {
                self.pictureView.image = currentWallpaperImage
            }
        }
    }

    private func currentWallpaperImage(from wallpaperState: WallpaperState) -> UIImage? {
        let isLandscape = UIDevice.current.orientation.isLandscape
        return isLandscape ?
        wallpaperState.wallpaperConfiguration.landscapeImage :
         wallpaperState.wallpaperConfiguration.landscapeImage
    }
}
