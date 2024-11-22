// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

public enum ToolbarButtonGesture {
    case tap
    case longPress
}

class ToolbarButton: UIButton, ThemeApplicable {
    private struct UX {
        static let verticalInset: CGFloat = 10
        static let horizontalInset: CGFloat = 10
        static let badgeIconSize = CGSize(width: 20, height: 20)
    }

    private var foregroundColorNormal: UIColor = .clear
    private var foregroundColorHighlighted: UIColor = .clear
    private var foregroundColorDisabled: UIColor = .clear
    private var backgroundColorNormal: UIColor = .clear

    private var badgeImageView: UIImageView?
    private var maskImageView: UIImageView?

    private var onLongPress: ((UIButton) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)

        configuration = UIButton.Configuration.plain()
        configuration?.contentInsets = NSDirectionalEdgeInsets(top: UX.verticalInset,
                                                               leading: UX.horizontalInset,
                                                               bottom: UX.verticalInset,
                                                               trailing: UX.horizontalInset)
    }

    open func configure(element: ToolbarElement) {
        guard var config = configuration else { return }
        removeAllGestureRecognizers()
        configureLongPressGestureRecognizerIfNeeded(for: element)
        configureCustomA11yActionIfNeeded(for: element)
        isSelected = element.isSelected

        let image = imageConfiguredForRTL(for: element)
        let action = UIAction(title: element.a11yLabel,
                              image: image,
                              handler: { [weak self] _ in
            guard let self else { return }
            element.onSelected?(self)
            UIAccessibility.post(notification: .announcement, argument: element.a11yLabel)
        })

        config.image = image
        isEnabled = element.isEnabled
        isAccessibilityElement = true
        accessibilityIdentifier = element.a11yId
        accessibilityLabel = element.a11yLabel
        accessibilityHint = element.a11yHint
        // Remove all existing actions for .touchUpInside before adding the new one
        // This ensures that we do not accumulate multiple actions for the same event,
        // which can cause the action to be called multiple times when the button is tapped.
        // By removing all existing actions first, we guarantee that only the new action
        // will be associated with the .touchUpInside event.
        removeTarget(nil, action: nil, for: .touchUpInside)
        addAction(action, for: .touchUpInside)

        showsLargeContentViewer = true
        largeContentTitle = element.a11yLabel
        largeContentImage = image

        configuration = config
        if let badgeName = element.badgeImageName {
            addBadgeIcon(imageName: badgeName)
            if let maskImageName = element.maskImageName {
                addMaskIcon(maskImageName: maskImageName)
            }
        } else {
            // Remove badge & mask icons
            imageView?.subviews.forEach { view in
                guard view as? UIImageView != nil else { return }
                view.removeFromSuperview()
            }
        }
        layoutIfNeeded()
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func updateConfiguration() {
        guard var updatedConfiguration = configuration else { return }

        switch state {
        case .highlighted:
            updatedConfiguration.baseForegroundColor = foregroundColorHighlighted
        case .disabled:
            updatedConfiguration.baseForegroundColor = foregroundColorDisabled
        default:
            updatedConfiguration.baseForegroundColor = isSelected ?
                                                       foregroundColorHighlighted :
                                                       foregroundColorNormal
        }

        updatedConfiguration.background.backgroundColor = backgroundColorNormal
        configuration = updatedConfiguration
    }

    private func addBadgeIcon(imageName: String) {
        badgeImageView = UIImageView(image: UIImage(named: imageName))
        guard let badgeImageView, configuration?.image != nil else { return }
        badgeImageView.translatesAutoresizingMaskIntoConstraints = false

        imageView?.addSubview(badgeImageView)
        applyBadgeConstraints(to: badgeImageView)
    }

    private func addMaskIcon(maskImageName: String) {
        maskImageView = UIImageView(image: UIImage(named: maskImageName))
        guard let maskImageView, let badgeImageView else { return }
        maskImageView.translatesAutoresizingMaskIntoConstraints = false

        maskImageView.addSubview(badgeImageView)
        imageView?.addSubview(maskImageView)
        applyBadgeConstraints(to: maskImageView)
    }

    private func applyBadgeConstraints(to imageView: UIImageView) {
        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: UX.badgeIconSize.width),
            imageView.heightAnchor.constraint(equalToConstant: UX.badgeIconSize.height),
            imageView.leadingAnchor.constraint(equalTo: centerXAnchor),
            imageView.bottomAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    private func configureLongPressGestureRecognizerIfNeeded(for element: ToolbarElement) {
        guard element.onLongPress != nil else { return }
        onLongPress = element.onLongPress
        let longPressRecognizer = UILongPressGestureRecognizer(
            target: self,
            action: #selector(handleLongPress)
        )
        addGestureRecognizer(longPressRecognizer)
    }

    private func configureCustomA11yActionIfNeeded(for element: ToolbarElement) {
        guard let a11yCustomActionName = element.a11yCustomActionName,
              let a11yCustomAction = element.a11yCustomAction else { return }
        let a11yAction = UIAccessibilityCustomAction(name: a11yCustomActionName) { _ in
            a11yCustomAction()
            return true
        }
        accessibilityCustomActions = [a11yAction]
    }

    private func imageConfiguredForRTL(for element: ToolbarElement) -> UIImage? {
        let image = UIImage(named: element.iconName)?.withRenderingMode(.alwaysTemplate)
        return element.isFlippedForRTL ? image?.imageFlippedForRightToLeftLayoutDirection() : image
    }

    private func removeAllGestureRecognizers() {
        guard let gestureRecognizers else { return }
            for recognizer in gestureRecognizers {
                removeGestureRecognizer(recognizer)
            }
    }

    // MARK: - Selectors
    @objc
    private func handleLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state == .began {
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.impactOccurred()
            onLongPress?(self)
        }
    }

    // MARK: - ThemeApplicable
    public func applyTheme(theme: Theme) {
        let colors = theme.colors
        foregroundColorNormal = colors.iconPrimary
        foregroundColorHighlighted = colors.actionPrimary
        foregroundColorDisabled = colors.iconDisabled
        backgroundColorNormal = .clear

        badgeImageView?.layer.borderColor = colors.layer1.cgColor
        badgeImageView?.backgroundColor = maskImageView == nil ? colors.layer1 : .clear
        badgeImageView?.tintColor = maskImageView == nil ? .clear : colors.actionInformation
        maskImageView?.tintColor = colors.layer1

        setNeedsUpdateConfiguration()
    }
}
