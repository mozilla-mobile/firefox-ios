// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

class WallpaperBackgroundView: UIView {
    private enum GradientDirection { case topToBottom, bottomToTop }

    // MARK: - UI Elements
    private lazy var pictureView: UIImageView = .build { imageView in
        imageView.image = nil
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
    }

    /// 28% black scrim layered over the wallpaper to improve legibility.
    private lazy var scrimView: UIView = .build { view in
        view.backgroundColor = UIColor.black.withAlphaComponent(0.28)
        view.isHidden = true
    }

    /// Blur view that fades from strong at the top edge to nothing toward the center.
    private lazy var topBlurView: UIVisualEffectView = .build { view in
        view.effect = UIBlurEffect(style: .systemUltraThinMaterial)
    }

    /// Blur view that fades from strong at the bottom edge to nothing toward the center.
    private lazy var bottomBlurView: UIVisualEffectView = .build { view in
        view.effect = UIBlurEffect(style: .systemUltraThinMaterial)
    }

    // MARK: - Variables
    var wallpaperState: WallpaperState? {
        didSet {
            updateImageToCurrentWallpaper()
        }
    }

    /// When set, this provider wallpaper image takes priority over the Redux wallpaper state.
    var unsplashImage: UIImage? {
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
        addSubview(scrimView)
        addSubview(topBlurView)
        addSubview(bottomBlurView)

        let blurHeightRatioTop: CGFloat = 0.04
        let blurHeightRatioBottom: CGFloat = 0.04

        NSLayoutConstraint.activate([
            pictureView.leadingAnchor.constraint(equalTo: leadingAnchor),
            pictureView.topAnchor.constraint(equalTo: topAnchor),
            pictureView.bottomAnchor.constraint(equalTo: bottomAnchor),
            pictureView.trailingAnchor.constraint(equalTo: trailingAnchor),

            scrimView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrimView.topAnchor.constraint(equalTo: topAnchor),
            scrimView.bottomAnchor.constraint(equalTo: bottomAnchor),
            scrimView.trailingAnchor.constraint(equalTo: trailingAnchor),

            topBlurView.leadingAnchor.constraint(equalTo: leadingAnchor),
            topBlurView.trailingAnchor.constraint(equalTo: trailingAnchor),
            topBlurView.topAnchor.constraint(equalTo: topAnchor),
            topBlurView.heightAnchor.constraint(equalTo: heightAnchor,
                                                multiplier: blurHeightRatioTop),

            bottomBlurView.leadingAnchor.constraint(equalTo: leadingAnchor),
            bottomBlurView.trailingAnchor.constraint(equalTo: trailingAnchor),
            bottomBlurView.bottomAnchor.constraint(equalTo: bottomAnchor),
            bottomBlurView.heightAnchor.constraint(equalTo: heightAnchor,
                                                   multiplier: blurHeightRatioBottom)
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        applyGradientMask(to: topBlurView, direction: .topToBottom)
        applyGradientMask(to: bottomBlurView, direction: .bottomToTop)
    }

    /// Applies a gradient mask so the blur fades from opaque (edge) to transparent (center).
    private func applyGradientMask(to blurView: UIVisualEffectView,
                                   direction: GradientDirection) {
        let gradient = CAGradientLayer()
        gradient.frame = blurView.bounds
        gradient.colors = [UIColor.black.cgColor, UIColor.clear.cgColor]
        switch direction {
        case .topToBottom:
            gradient.startPoint = CGPoint(x: 0.5, y: 0)
            gradient.endPoint   = CGPoint(x: 0.5, y: 1)
        case .bottomToTop:
            gradient.startPoint = CGPoint(x: 0.5, y: 1)
            gradient.endPoint   = CGPoint(x: 0.5, y: 0)
        }
        blurView.layer.mask = gradient
    }

    // MARK: - Methods
    public func updateImageForOrientationChange() {
        updateImageToCurrentWallpaper()
    }

    private func updateImageToCurrentWallpaper() {
        ensureMainThread {
            // Provider wallpaper takes priority if set
            if let providerImage = self.unsplashImage {
                UIView.animate(withDuration: 0.3) {
                    self.pictureView.image = providerImage
                    self.scrimView.isHidden = false
                }
                return
            }

            guard let state = self.wallpaperState else { return }
            let currentWallpaperImage = self.currentWallpaperImage(from: state)
            UIView.animate(withDuration: 0.3) {
                self.pictureView.image = currentWallpaperImage
                self.scrimView.isHidden = currentWallpaperImage == nil
            }
        }
    }

    private func currentWallpaperImage(from wallpaperState: WallpaperState) -> UIImage? {
        let isLandscape = UIDevice.current.orientation.isLandscape
        return isLandscape ?
        wallpaperState.wallpaperConfiguration.landscapeImage :
         wallpaperState.wallpaperConfiguration.portraitImage
    }
}
