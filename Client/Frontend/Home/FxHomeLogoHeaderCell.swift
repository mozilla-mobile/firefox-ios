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
        button.accessibilityLabel = .Settings.Homepage.Wallpaper.AccessibilityLabels.FxHomepageWallpaperButton
    }

    // MARK: - Variables
    var notificationCenter: NotificationCenter = NotificationCenter.default
    private var userDefaults: UserDefaults = UserDefaults.standard

    // MARK: - Initializers
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        applyTheme()
        setupNotifications(forObserver: self,
                           observing: [.DisplayThemeChanged])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        notificationCenter.removeObserver(self)
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

    // MARK: - Animation
    public func runLogoAnimation() {
        animateLogo(withDelay: 0) {
            self.animateLogo(withDelay: 0.5) {
                self.userDefaults.set(true, forKey: PrefsKeys.WallpaperLogoHasShownAnimation)
            }
        }
    }

    private func animateLogo(withDelay delay: TimeInterval, completionHandler: @escaping () -> Void) {
        let angle: CGFloat = .pi/32
        let numberOfFrames: Double = 6
        let frameDuration = Double(1/numberOfFrames)

        // The number of keyframes added in this keyframe block are equal to the
        // `numberOfFrames`. But each keyframe needs to change angle for the
        // respective animation to move through the keyframes. Instead of doing this
        // manually, we can automate it given that we treat the `relativeStartTimeModifier`
        // as an index (ie, starting at 0) and the `numberOfFrames` as a `.count`
        // meaning that the correct index is found at `x - 1`.
        UIView.animateKeyframes(withDuration: 1, delay: delay, options: []) {

            var relativeStartTimeModifier = 0.0
            repeat {

                let adjustedAngle = (relativeStartTimeModifier.remainder(dividingBy: 2) == 0) ? +angle : -angle
                let newStartTime = frameDuration*relativeStartTimeModifier

                UIView.addKeyframe(withRelativeStartTime: newStartTime,
                                   relativeDuration: frameDuration) {

                    if relativeStartTimeModifier < numberOfFrames - 1 {
                        self.logoButton.transform = CGAffineTransform(rotationAngle: adjustedAngle)

                    } else if relativeStartTimeModifier == numberOfFrames - 1 {
                        self.logoButton.transform = CGAffineTransform.identity
                    }
                }

                relativeStartTimeModifier += 1.0
            } while relativeStartTimeModifier < numberOfFrames

        } completion: { _ in
            completionHandler()
        }
    }
}

// MARK: - Theme
extension FxHomeLogoHeaderCell: NotificationThemeable {
    func applyTheme() {
        let resourceName = "fxHomeHeaderLogo"
        let resourceNameDark = "fxHomeHeaderLogo_dark"
        let imageString = LegacyThemeManager.instance.currentName == .dark ? resourceNameDark : resourceName
        logoButton.setImage(UIImage(imageLiteralResourceName: imageString), for: .normal)
    }
}

// MARK: - Notifiable
extension FxHomeLogoHeaderCell: Notifiable {
    func handleNotifications(_ notification: Notification) {
        switch notification.name {
        case .DisplayThemeChanged:
            applyTheme()
        default: break
        }
    }
}
