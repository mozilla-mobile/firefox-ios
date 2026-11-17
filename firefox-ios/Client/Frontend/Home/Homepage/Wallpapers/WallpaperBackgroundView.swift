// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

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

    private var lastLayoutSize: CGSize = .zero

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

    override func layoutSubviews() {
        super.layoutSubviews()
        guard bounds.size != lastLayoutSize else { return }
        lastLayoutSize = bounds.size
        updateImageToCurrentWallpaper()
    }

    // MARK: - Methods
    public func updateImageForOrientationChange() {
        updateImageToCurrentWallpaper()
    }

    /// Draws the current wallpaper image into the current graphics context, scaled to aspect fill `rect`
    /// the same way it is displayed on screen, and clipped to `clipRect`.
    func drawWallpaper(aspectFilling rect: CGRect, clippedTo clipRect: CGRect) {
        guard let image = pictureView.image, let context = UIGraphicsGetCurrentContext() else { return }
        context.saveGState()
        context.clip(to: clipRect)
        image.draw(in: WallpaperBackgroundView.aspectFillRect(for: image.size, in: rect))
        context.restoreGState()
    }

    static func aspectFillRect(for imageSize: CGSize, in rect: CGRect) -> CGRect {
        guard imageSize.width > 0, imageSize.height > 0 else { return rect }
        let scale = max(rect.width / imageSize.width, rect.height / imageSize.height)
        let size = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
        return CGRect(
            x: rect.midX - size.width / 2,
            y: rect.midY - size.height / 2,
            width: size.width,
            height: size.height
        )
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
        let configuration = wallpaperState.wallpaperConfiguration
        let isLandscape = UIDevice.current.orientation.isLandscape

        let iPadImage = isLandscape ? configuration.iPadLandscapeImage : configuration.iPadPortraitImage
        let iPhoneImage = isLandscape ? configuration.iPhoneLandscapeImage : configuration.iPhonePortraitImage

        if traitCollection.horizontalSizeClass == .regular {
            return iPadImage ?? iPhoneImage
        }
        return iPhoneImage ?? iPadImage
    }
}
