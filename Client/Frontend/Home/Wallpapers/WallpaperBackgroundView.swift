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

        let contrastColour = LegacyThemeManager.instance.currentName == .dark ? 1.0 : 0.0
        gradientView.configureGradient(
            colors: [UIColor(white: 1.0, alpha: 0.5),
                     UIColor(white: 1.0, alpha: 0.41),
                     UIColor(white: 1.0, alpha: 0.35)],
            positions: [0, 0.5, 0.8],
            startPoint: .zero,
            endPoint: CGPoint(x: 0, y: 1)
        )
        gradientView.alpha = 0.0
    }

    // MARK: - Variables
    private var wallpaperManager = WallpaperManager()

    // MARK: - Initializers & Setup
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        setupNotifications()
        updateImageTo(wallpaperManager.currentWallpaper)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleNotifications),
                                               name: .WallpaperDidChange,
                                               object: nil)
    }

    @objc private func handleNotifications(_ notification: Notification) {
        switch notification.name {
        case .WallpaperDidChange:
            updateImageTo(wallpaperManager.currentWallpaper)
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
                                     extras: wallpaperManager.telemetryMetadata)
    }

    public func updateImageForOrientationChange() {
        updateImageTo(wallpaperManager.currentWallpaper)
    }

    private func updateImageTo(_ image: UIImage?) {
        guard let image = image else {
            pictureView.image = nil
            gradientView.alpha = 0.0
            return
        }

        pictureView.image = image
        gradientView.alpha = 1.0
    }
}
