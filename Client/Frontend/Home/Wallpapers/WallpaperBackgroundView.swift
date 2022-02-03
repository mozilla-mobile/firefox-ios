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

    private lazy var gradientView: ConfigurableGradientView = .build { gradientView in
        gradientView.alpha = 0.0
    }

    // MARK: - Variables
    private var wallpaperManager = WallpaperManager()

    // MARK: - Initializers & Setup
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        updateGradientColor()
        setupNotifications()
        updateImageTo(wallpaperManager.currentWallpaperImage)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func setupView() {
        backgroundColor = .clear
        addSubview(pictureView)
        addSubview(gradientView)

        NSLayoutConstraint.activate([
            pictureView.leadingAnchor.constraint(equalTo: leadingAnchor),
            pictureView.topAnchor.constraint(equalTo: topAnchor),
            pictureView.bottomAnchor.constraint(equalTo: bottomAnchor),
            pictureView.trailingAnchor.constraint(equalTo: trailingAnchor),

            gradientView.leadingAnchor.constraint(equalTo: leadingAnchor),
            gradientView.topAnchor.constraint(equalTo: topAnchor),
            gradientView.bottomAnchor.constraint(equalTo: bottomAnchor),
            gradientView.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
    }

    // MARK: - Notifications
    private func setupNotifications() {
        let refreshEvents: [Notification.Name] = [.DisplayThemeChanged,
                                                  .WallpaperDidChange]
        refreshEvents.forEach {
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(handleNotifications),
                                                   name: $0,
                                                   object: nil)
        }
    }

    @objc private func handleNotifications(_ notification: Notification) {
        switch notification.name {
        case .WallpaperDidChange:
            updateImageTo(wallpaperManager.currentWallpaperImage)
            updateGradient()
        case .DisplayThemeChanged:
            updateGradient()
        default:
            break
        }
    }

    // MARK: - Methods
    public func cycleWallpaper() {
        guard wallpaperManager.switchWallpaperFromLogoEnabled else { return }
        wallpaperManager.cycleWallpaper()

        TelemetryWrapper.recordEvent(category: .action,
                                     method: .tap,
                                     object: .firefoxHomepage,
                                     value: .cycleWallpaperButton,
                                     extras: wallpaperManager.currentWallpaper.telemetryMetadata)
    }

    public func updateImageForOrientationChange() {
        updateImageTo(wallpaperManager.currentWallpaperImage)
    }

    private func updateImageTo(_ image: UIImage?) {
        UIView.animate(withDuration: 0.3) {
            self.pictureView.image = image
        }
    }

    private func updateGradient() {
        updateGradientColor()
        updateGradientVisibilityForSelectedWallpaper()
    }

    private func updateGradientColor() {
        let contrastColour = LegacyThemeManager.instance.currentName == .dark ? 0.0 : 1.0
        gradientView.configureGradient(
            colors: [UIColor(white: contrastColour, alpha: 0.4),
                     UIColor(white: contrastColour, alpha: 0.35),
                     UIColor(white: contrastColour , alpha: 0.3)],
            positions: [0, 0.5, 0.8],
            startPoint: .zero,
            endPoint: CGPoint(x: 0, y: 1)
        )
    }

    /// By default, no wallpaper collection should show a gradient. If we wish
    /// a particular wallpaper collection to have a gradient, it should be included
    /// in the switch case as
    ///
    /// `case .themed(type: .collectionName): gradientView.alpha = 1.0`
    ///
    /// Both default and Firefox papers have no gradient.
    private func updateGradientVisibilityForSelectedWallpaper() {

        switch wallpaperManager.currentWallpaper.type {
        // No gradient exists for default wallpaper OR firefox default wallpapers.
        default: gradientView.alpha = 0.0
        }

    }
}
