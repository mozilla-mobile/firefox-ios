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
    var notificationCenter: NotificationCenter = NotificationCenter.default

    // MARK: - Initializers & Setup
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        updateGradient()
        setupNotifications(forObserver: self,
                           observing: [.DisplayThemeChanged,
                                       .WallpaperDidChange])

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
        struct GradientValues {
            let start: CGFloat
            let transition: CGFloat
            let end: CGFloat
        }
        
        let isDarkTheme = LegacyThemeManager.instance.currentName == .dark
        let contrastColour = isDarkTheme ? 0.0 : 1.0
        let gradientValue = isDarkTheme ? GradientValues(start: 0.37, transition: 0.35, end: 0.32) : GradientValues(start: 0.28, transition: 0.26, end: 0.24)
        
        gradientView.configureGradient(
            colors: [UIColor(white: contrastColour, alpha: gradientValue.start),
                     UIColor(white: contrastColour, alpha: gradientValue.transition),
                     UIColor(white: contrastColour , alpha: gradientValue.end)],
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
        case .themed(type: .projectHouse),
                .themed(type: .firefoxOverlay):
            gradientView.alpha = 1.0
        case .themed(type: .firefox),
                .defaultBackground:
            gradientView.alpha = 0.0
        }

    }
}

// MARK: - Notifiable
extension WallpaperBackgroundView: Notifiable {
    func handleNotifications(_ notification: Notification) {
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
}
