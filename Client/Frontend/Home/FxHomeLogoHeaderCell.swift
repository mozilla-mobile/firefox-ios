// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import UIKit

fileprivate struct LogoViewUX {
    static let imageHeight: CGFloat = 40
    static let imageWidth: CGFloat = 214.74
}

class FxHomeLogoHeaderCell: UICollectionViewCell, ReusableCell {
    typealias a11y = AccessibilityIdentifiers.FirefoxHomepage.OtherButtons

    // MARK: - UI Elements
    lazy var logoButton: UIButton = .build { button in
        button.setTitle("", for: .normal)
        button.backgroundColor = .clear
        button.accessibilityIdentifier = a11y.logoButton
    }

    private var userDefaults: UserDefaults?

    // MARK: - Initializers
    convenience init(userDefaults: UserDefaults = UserDefaults.standard) {
        self.init(frame: .zero)
        self.userDefaults = userDefaults
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        applyTheme()
        setupObservers()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - UI Setup
    func setupView() {
        contentView.backgroundColor = .clear
        contentView.addSubview(logoButton)

        NSLayoutConstraint.activate([
            logoButton.widthAnchor.constraint(equalToConstant: LogoViewUX.imageWidth),
            logoButton.heightAnchor.constraint(equalToConstant: LogoViewUX.imageHeight),
            logoButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            logoButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10)
        ])
    }

    // MARK: - Observers & Notifications
    private func setupObservers() {
        let refreshEvents: [Notification.Name] = [.DisplayThemeChanged, .WallpaperDidChange]
        refreshEvents.forEach {
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(handleNotifications),
                                                   name: $0,
                                                   object: nil)
        }
    }
    
    @objc private func handleNotifications(_ notification: Notification) {
        switch notification.name {
        case .DisplayThemeChanged, .WallpaperDidChange:
            applyTheme()
        default: break
        }
    }

    // MARK: - Animation
    public func animateLogo() {
//        guard !userDefaults?.bool(forKey: PrefsKeys.WallpaperLogoHasShownAnimation) else { return }
        let angle: CGFloat = .pi/32
        let numberOfFrames: Double = 6
        let frameDuration = Double(1/numberOfFrames)

        UIView.animateKeyframes(withDuration: 1, delay: 0, options: []) {

            UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: frameDuration) {
                self.logoButton.transform = CGAffineTransform(rotationAngle: -angle)
            }

            UIView.addKeyframe(withRelativeStartTime: frameDuration,
                               relativeDuration: frameDuration) {
                self.logoButton.transform = CGAffineTransform(rotationAngle: +angle)
            }

            UIView.addKeyframe(withRelativeStartTime: frameDuration*2,
                               relativeDuration: frameDuration) {
                self.logoButton.transform = CGAffineTransform(rotationAngle: -angle)
            }

            UIView.addKeyframe(withRelativeStartTime: frameDuration*3,
                               relativeDuration: frameDuration) {
                self.logoButton.transform = CGAffineTransform(rotationAngle: +angle)
            }

            UIView.addKeyframe(withRelativeStartTime: frameDuration*4,
                               relativeDuration: frameDuration) {
                self.logoButton.transform = CGAffineTransform(rotationAngle: -angle)
            }

            UIView.addKeyframe(withRelativeStartTime: frameDuration*5,
                               relativeDuration: frameDuration) {
                self.logoButton.transform = CGAffineTransform.identity
            }
        } completion: { _ in
            UIView.animateKeyframes(withDuration: 1, delay: 0.5, options: []) {

                UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: frameDuration) {
                    self.logoButton.transform = CGAffineTransform(rotationAngle: -angle)
                }

                UIView.addKeyframe(withRelativeStartTime: frameDuration,
                                   relativeDuration: frameDuration) {
                    self.logoButton.transform = CGAffineTransform(rotationAngle: +angle)
                }

                UIView.addKeyframe(withRelativeStartTime: frameDuration*2,
                                   relativeDuration: frameDuration) {
                    self.logoButton.transform = CGAffineTransform(rotationAngle: -angle)
                }

                UIView.addKeyframe(withRelativeStartTime: frameDuration*3,
                                   relativeDuration: frameDuration) {
                    self.logoButton.transform = CGAffineTransform(rotationAngle: +angle)
                }

                UIView.addKeyframe(withRelativeStartTime: frameDuration*4,
                                   relativeDuration: frameDuration) {
                    self.logoButton.transform = CGAffineTransform(rotationAngle: -angle)
                }

                UIView.addKeyframe(withRelativeStartTime: frameDuration*5,
                                   relativeDuration: frameDuration) {
                    self.logoButton.transform = CGAffineTransform.identity
                }
            } completion: { _ in
//            userDefaults?.set(true, forKey: PrefsKeys.WallpaperLogoHasShownAnimation)
            }
        }
    }
}

extension FxHomeLogoHeaderCell: NotificationThemeable {
    func applyTheme() {
        let wallpaperManager = WallpaperManager()
        let resourceName = "fxHomeHeaderLogo"
        let resourceNameDark = "fxHomeHeaderLogo_dark"
        var imageString = resourceName

        if wallpaperManager.isUsingCustomWallpaper {
            imageString = resourceNameDark
        } else {
            imageString = LegacyThemeManager.instance.currentName == .dark ? resourceNameDark : resourceName
        }

        logoButton.setImage( UIImage(imageLiteralResourceName: imageString), for: .normal)
    }
}
