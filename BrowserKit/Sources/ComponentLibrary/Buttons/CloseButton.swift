// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

public class CloseButton: UIButton,
                          Notifiable {
    public var notificationCenter: any NotificationProtocol = NotificationCenter.default

    private var viewModel: CloseButtonViewModel?
    private var heightConstraint: NSLayoutConstraint?
    private var widthConstraint: NSLayoutConstraint?

    private struct UX {
        static let closeButtonSize = CGSize(width: 30, height: 30)
        static let crossCircleImage = StandardImageIdentifiers.ExtraLarge.crossCircleFill
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        setImage(UIImage(named: UX.crossCircleImage), for: .normal)
        adjustsImageSizeForAccessibilityContentSizeCategory = true
        setupConstraints()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupConstraints() {
        translatesAutoresizingMaskIntoConstraints = false
        heightConstraint = heightAnchor.constraint(equalToConstant: UX.closeButtonSize.height)
        heightConstraint?.isActive = true
        widthConstraint = widthAnchor.constraint(equalToConstant: UX.closeButtonSize.width)
        widthConstraint?.isActive = true
        updateButtonSizeForDynamicFont()
    }

    public func configure(viewModel: CloseButtonViewModel,
                          notificationCenter: NotificationProtocol = NotificationCenter.default) {
        self.notificationCenter = notificationCenter
        setupNotifications(forObserver: self, observing: [UIContentSizeCategory.didChangeNotification])

        self.viewModel = viewModel
        accessibilityIdentifier = viewModel.a11yIdentifier
        accessibilityLabel = viewModel.a11yLabel
    }

    private func updateButtonSizeForDynamicFont() {
        let dynamicWidth = max(UIFontMetrics.default.scaledValue(for: UX.closeButtonSize.width), UX.closeButtonSize.width)
        let dynamicHeight = max(UIFontMetrics.default.scaledValue(for: UX.closeButtonSize.height), UX.closeButtonSize.height)
        heightConstraint?.constant = dynamicHeight
        widthConstraint?.constant = dynamicWidth
    }

    // MARK: - Notifiable

    public func handleNotifications(_ notification: Notification) {
        switch notification.name {
        case UIContentSizeCategory.didChangeNotification:
            updateButtonSizeForDynamicFont()
        default:
            break
        }
    }

    deinit {
        notificationCenter.removeObserver(self)
    }
}
