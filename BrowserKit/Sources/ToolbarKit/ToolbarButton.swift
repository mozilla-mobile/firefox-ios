// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

public enum ToolbarButtonGesture {
    case tap
    case longPress
}

class ToolbarButton: UIButton, ThemeApplicable, UIGestureRecognizerDelegate {
    private struct UX {
        static let verticalInset: CGFloat = 10
        static let horizontalInset: CGFloat = 10
        static let horizontalTextInset: CGFloat = 5
        static let badgeIconSize = CGSize(width: 20, height: 20)
        static let defaultMinimumPressDuration: TimeInterval = 0.5
        static let minimumPressDurationWithLargeContentViewer: TimeInterval = 1.5
    }

    private var foregroundColorNormal: UIColor = .clear
    private var foregroundColorHighlighted: UIColor = .clear
    private var foregroundColorDisabled: UIColor = .clear
    private var foregroundTitleColorNormal: UIColor = .clear
    private var foregroundTitleColorHighlighted: UIColor = .clear
    private var backgroundColorNormal: UIColor = .clear

    private var badgeImageView: UIImageView?
    private var maskImageView: UIImageView?

    private var longPressRecognizer: UILongPressGestureRecognizer?
    private var onLongPress: ((UIButton) -> Void)?
    private var notificationCenter: NotificationProtocol?
    private var largeContentViewerInteraction: UILargeContentViewerInteraction?

    private var isTextButton = false
    private var hasCustomColor = false

    override init(frame: CGRect) {
        super.init(frame: frame)

        configuration = UIButton.Configuration.plain()
        configuration?.contentInsets = NSDirectionalEdgeInsets(top: UX.verticalInset,
                                                               leading: UX.horizontalInset,
                                                               bottom: UX.verticalInset,
                                                               trailing: UX.horizontalInset)
        titleLabel?.adjustsFontForContentSizeCategory = true
    }

    open func configure(
        element: ToolbarElement,
        notificationCenter: NotificationProtocol = NotificationCenter.default) {
        guard var config = configuration else { return }
        removeLongPressGestureRecognizer()
        configureLongPressGestureRecognizerIfNeeded(for: element, notificationCenter: notificationCenter)
        configureCustomA11yActionIfNeeded(for: element)
        isSelected = element.isSelected
        isTextButton = element.title != nil
        hasCustomColor = element.hasCustomColor
        self.notificationCenter = notificationCenter

        let image = imageConfiguredForRTL(for: element)
        let action = UIAction(title: element.title ?? element.a11yLabel,
                              image: image,
                              handler: { [weak self] _ in
            guard let self else { return }
            element.onSelected?(self)
            UIAccessibility.post(notification: .announcement, argument: element.a11yLabel)
        })

        config.image = image
        config.title = element.title
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = FXFontStyles.Regular.callout.scaledFont()
            return outgoing
        }

        if config.title != nil {
            config.contentInsets = NSDirectionalEdgeInsets(top: UX.verticalInset,
                                                           leading: UX.horizontalTextInset,
                                                           bottom: UX.verticalInset,
                                                           trailing: UX.horizontalTextInset)
        }

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

    deinit {
        notificationCenter?.removeObserver(self)
    }

    override public func updateConfiguration() {
        guard var updatedConfiguration = configuration else { return }

        switch state {
        case .highlighted:
            updatedConfiguration.baseForegroundColor = isTextButton ?
                                                        foregroundTitleColorHighlighted :
                                                        foregroundColorHighlighted
        case .disabled:
            updatedConfiguration.baseForegroundColor = foregroundColorDisabled
        default:
            let iconButtonColor = isSelected ? foregroundColorHighlighted : foregroundColorNormal
            let textButtonColor = isSelected ? foregroundTitleColorHighlighted : foregroundTitleColorNormal
            updatedConfiguration.baseForegroundColor = isTextButton ? textButtonColor : iconButtonColor
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

    private func configureLongPressGestureRecognizerIfNeeded(for element: ToolbarElement,
                                                             notificationCenter: NotificationProtocol) {
        guard element.onLongPress != nil else { return }
        onLongPress = element.onLongPress
        let longPressRecognizer = UILongPressGestureRecognizer(
            target: self,
            action: #selector(handleLongPress)
        )
        longPressRecognizer.delegate = self
        addGestureRecognizer(longPressRecognizer)
        self.longPressRecognizer = longPressRecognizer
        setMinimumPressDuration()

        let largeContentViewerInteraction = UILargeContentViewerInteraction()
        self.largeContentViewerInteraction = largeContentViewerInteraction
        addInteraction(largeContentViewerInteraction)

        notificationCenter.addObserver(
            self,
            selector: #selector(largeContentViewerInteractionDidChange),
            name: UILargeContentViewerInteraction.enabledStatusDidChangeNotification,
            object: nil
        )
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
        guard let iconName = element.iconName else { return nil }
        let image = UIImage(named: iconName)?.withRenderingMode(.alwaysTemplate)
        return element.isFlippedForRTL ? image?.imageFlippedForRightToLeftLayoutDirection() : image
    }

    private func removeLongPressGestureRecognizer() {
        guard let recognizer = longPressRecognizer, let interaction = largeContentViewerInteraction else { return }
        removeGestureRecognizer(recognizer)
        longPressRecognizer = nil

        removeInteraction(interaction)
        largeContentViewerInteraction = nil
    }

    private func setMinimumPressDuration() {
        // The default long press duration is 0.5. Here we extend it if
        // UILargeContentViewInteraction is enabled to allow the large content
        // viewer time to display the content
        var minimumPressDuration: TimeInterval = UX.defaultMinimumPressDuration
        if UILargeContentViewerInteraction.isEnabled {
            minimumPressDuration = UX.minimumPressDurationWithLargeContentViewer
        }
        longPressRecognizer?.minimumPressDuration = minimumPressDuration
    }

    // MARK: - Selectors
    @objc
    private func handleLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state == .began {
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.impactOccurred()

            // Cancel showing the large content viewer
            largeContentViewerInteraction?.gestureRecognizerForExclusionRelationship.state = .cancelled

            onLongPress?(self)
        }
    }

    @objc
    private func largeContentViewerInteractionDidChange() {
        setMinimumPressDuration()
    }

    // MARK: - ThemeApplicable
    public func applyTheme(theme: Theme) {
        let colors = theme.colors
        foregroundColorNormal = hasCustomColor ? colors.iconSecondary : colors.iconPrimary
        foregroundColorHighlighted = colors.actionPrimary
        foregroundColorDisabled = colors.iconDisabled
        backgroundColorNormal = .clear

        foregroundTitleColorNormal = colors.textAccent
        foregroundTitleColorHighlighted = colors.actionPrimaryHover

        badgeImageView?.layer.borderColor = colors.layer1.cgColor
        badgeImageView?.backgroundColor = maskImageView == nil ? colors.layer1 : .clear
        badgeImageView?.tintColor = maskImageView == nil ? .clear : colors.actionInformation
        maskImageView?.tintColor = colors.layer1

        layoutIfNeeded()
        setNeedsUpdateConfiguration()
    }

    // MARK: - UIGestureRecognizerDelegate
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            let recognizerRelationship = largeContentViewerInteraction?.gestureRecognizerForExclusionRelationship
            return gestureRecognizer == longPressRecognizer && otherGestureRecognizer == recognizerRelationship
    }
}
