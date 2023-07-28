// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common
import Shared

protocol ZoomPageBarDelegate: AnyObject {
    func zoomPageDidPressClose()
    func didChangeZoomLevel()
}

class ZoomPageBar: UIView, ThemeApplicable, AlphaDimmable {
    private struct UX {
        static let leadingTrailingPadding: CGFloat = 20
        static let topBottomPadding: CGFloat = 18
        static let stepperWidth: CGFloat = 222
        static let stepperHeight: CGFloat = 36
        static let stepperTopBottomPadding: CGFloat = 10
        static let stepperCornerRadius: CGFloat = 8
        static let stepperMinTrailing: CGFloat = 10
        static let stepperShadowRadius: CGFloat = 4
        static let stepperSpacing: CGFloat = 12
        static let stepperShadowOpacity: Float = 1
        static let stepperShadowOffset = CGSize(width: 0, height: 4)
        static let separatorWidth: CGFloat = 1
        static let separatorHeightMultiplier = 0.74
        static let fontSize: CGFloat = 16
        static let lowerZoomLimit: CGFloat = 0.5
        static let upperZoomLimit: CGFloat = 2.0
        static let zoomInButtonInsets = UIEdgeInsets(top: 6, left: 0, bottom: 6, right: 12)
        static let zoomOutButtonInsets = UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 0)
    }

    weak var delegate: ZoomPageBarDelegate?
    private let gestureRecognizer = UITapGestureRecognizer()
    private var stepperCompactConstraints = [NSLayoutConstraint]()
    private var stepperDefaultConstraints = [NSLayoutConstraint]()
    private var gradientViewHeightConstraint = NSLayoutConstraint()

    private let tab: Tab

    private let leftSeparator: UIView = .build()
    private let rightSeparator: UIView = .build()
    private let gradientView: UIView = .build()
    private let gradient = CAGradientLayer()

    private let stepperContainer: UIStackView = .build { view in
        view.axis = .horizontal
        view.alignment = .center
        view.distribution = .fill
        view.spacing = UX.stepperSpacing
        view.layer.cornerRadius = UX.stepperCornerRadius
        view.layer.shadowRadius = UX.stepperShadowRadius
        view.layer.shadowOffset = UX.stepperShadowOffset
        view.layer.shadowOpacity = UX.stepperShadowOpacity
        view.clipsToBounds = false
    }

    private let zoomOutButton: UIButton = .build { button in
        button.setImage(UIImage.templateImageNamed(ImageIdentifiers.subtract), for: [])
        button.accessibilityLabel = .AppMenu.ZoomPageDecreaseZoomAccessibilityLabel
        button.accessibilityIdentifier = AccessibilityIdentifiers.ZoomPageBar.zoomPageZoomOutButton
        button.setContentHuggingPriority(.required, for: .horizontal)
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
        button.setInsets(forContentPadding: UX.zoomOutButtonInsets, imageTitlePadding: 0)
    }

    private let zoomLevel: UILabel = .build { label in
        label.font = DefaultDynamicFontHelper.preferredFont(withTextStyle: .callout,
                                                            size: UX.fontSize,
                                                            weight: .semibold)
        label.accessibilityIdentifier = AccessibilityIdentifiers.ZoomPageBar.zoomPageZoomLevelLabel
        label.isUserInteractionEnabled = true
        label.adjustsFontForContentSizeCategory = true
        label.textAlignment = .center
    }

    private let zoomInButton: UIButton = .build { button in
        button.setImage(UIImage.templateImageNamed(StandardImageIdentifiers.Large.plus), for: [])
        button.accessibilityLabel = .AppMenu.ZoomPageIncreaseZoomAccessibilityLabel
        button.accessibilityIdentifier = AccessibilityIdentifiers.ZoomPageBar.zoomPageZoomInButton
        button.setContentHuggingPriority(.required, for: .horizontal)
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
        button.setInsets(forContentPadding: UX.zoomInButtonInsets, imageTitlePadding: 0)
    }

    private let closeButton: UIButton = .build { button in
        button.setImage(UIImage.templateImageNamed(StandardImageIdentifiers.Large.cross), for: [])
        button.accessibilityLabel = .AppMenu.ZoomPageCloseAccessibilityLabel
        button.accessibilityIdentifier = AccessibilityIdentifiers.FindInPage.findInPageCloseButton
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    private lazy var animation: CABasicAnimation = {
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false
        return animation
    }()

    init(tab: Tab) {
        self.tab = tab

        super.init(frame: .zero)

        setupViews()
        setupLayout()
        setupGradientViewLayout()
        setupGradient()
        focusOnZoomLevel()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        remakeGradientViewHeightConstraint()
        updateStepperConstraintsBasedOnSizeClass()
        layoutIfNeeded()
    }

    private func setupViews() {
        zoomInButton.addTarget(self, action: #selector(didPressZoomIn), for: .touchUpInside)
        zoomOutButton.addTarget(self, action: #selector(didPressZoomOut), for: .touchUpInside)
        closeButton.addTarget(self, action: #selector(didPressClose), for: .touchUpInside)

        gestureRecognizer.addTarget(self, action: #selector(didPressReset))
        zoomLevel.addGestureRecognizer(gestureRecognizer)

        updateZoomLabel()
        checkPageZoomLimits()

        [zoomOutButton, leftSeparator, zoomLevel, rightSeparator, zoomInButton].forEach {
            stepperContainer.addArrangedSubview($0)
        }
        stepperContainer.accessibilityElements = [zoomOutButton, zoomLevel, zoomInButton]

        addSubviews(gradientView, stepperContainer, closeButton)
    }

    private func setupLayout() {
        stepperCompactConstraints.append(stepperContainer.leadingAnchor.constraint(equalTo: leadingAnchor,
                                                                                   constant: UX.leadingTrailingPadding))
        stepperDefaultConstraints.append(stepperContainer.centerXAnchor.constraint(equalTo: centerXAnchor))
        stepperDefaultConstraints.append(stepperContainer.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor,
                                                                                   constant: UX.leadingTrailingPadding))
        setupSeparator(leftSeparator)
        setupSeparator(rightSeparator)

        NSLayoutConstraint.activate([
            stepperContainer.topAnchor.constraint(equalTo: topAnchor,
                                                  constant: UX.stepperTopBottomPadding),
            stepperContainer.bottomAnchor.constraint(equalTo: bottomAnchor,
                                                     constant: -UX.stepperTopBottomPadding),
            stepperContainer.trailingAnchor.constraint(lessThanOrEqualTo: closeButton.leadingAnchor,
                                                       constant: -UX.stepperMinTrailing),
            stepperContainer.heightAnchor.constraint(greaterThanOrEqualToConstant: UX.stepperHeight),
            stepperContainer.widthAnchor.constraint(greaterThanOrEqualToConstant: UX.stepperWidth),
            stepperContainer.centerYAnchor.constraint(equalTo: centerYAnchor),

            closeButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            closeButton.trailingAnchor.constraint(equalTo: trailingAnchor,
                                                  constant: -UX.leadingTrailingPadding),
        ])
    }

    private func setupSeparator(_ separator: UIView) {
        separator.widthAnchor.constraint(equalToConstant: UX.separatorWidth).isActive = true
        separator.heightAnchor.constraint(equalTo: stepperContainer.heightAnchor,
                                          multiplier: UX.separatorHeightMultiplier).isActive = true
    }

    private func setupGradient() {
        gradient.locations = [0, 1]
        gradient.startPoint = CGPoint(x: 0.5, y: 0)
        gradient.endPoint = CGPoint(x: 0.5, y: 1)
        gradientView.layer.addSublayer(gradient)
    }

    private func setupGradientViewLayout() {
        gradientView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        gradientView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        if traitCollection.userInterfaceIdiom == .pad {
            gradientView.topAnchor.constraint(equalTo: bottomAnchor).isActive = true
        } else {
            gradientView.bottomAnchor.constraint(equalTo: topAnchor).isActive = true
        }
    }

    private func remakeGradientViewHeightConstraint() {
        let viewPortHeight: CGFloat = (UIScreen.main.bounds.height -
                                       UIConstants.TopToolbarHeightMax -
                                       UIConstants.ZoomPageBarHeight)
        gradientViewHeightConstraint.isActive = false
        gradientViewHeightConstraint = gradientView.heightAnchor.constraint(equalToConstant: viewPortHeight * 0.2)
        gradientViewHeightConstraint.isActive = true
        gradient.frame = gradientView.bounds
    }

    private func updateZoomLabel() {
        zoomLevel.text = NumberFormatter.localizedString(from: NSNumber(value: tab.pageZoom), number: .percent)
        zoomLevel.isEnabled = tab.pageZoom == 1.0 ? false : true
        gestureRecognizer.isEnabled = !(tab.pageZoom == 1.0)
        zoomLevel.accessibilityLabel = String(format: .AppMenu.ZoomPageCurrentZoomLevelAccessibilityLabel,
                                              zoomLevel.text ?? "")
    }

    private func enableZoomButtons() {
        zoomInButton.isEnabled = true
        zoomOutButton.isEnabled = true
    }

    private func checkPageZoomLimits() {
        if tab.pageZoom <= UX.lowerZoomLimit {
            zoomOutButton.isEnabled = false
        } else if tab.pageZoom >= UX.upperZoomLimit {
            zoomInButton.isEnabled = false
        } else { enableZoomButtons() }
    }

    private func updateStepperConstraintsBasedOnSizeClass() {
        if traitCollection.horizontalSizeClass == .regular ||
            (UIWindow.isLandscape && traitCollection.verticalSizeClass == .compact) {
            stepperDefaultConstraints.forEach { $0.isActive = true }
            stepperCompactConstraints.forEach { $0.isActive = false }
        } else {
            stepperDefaultConstraints.forEach { $0.isActive = false }
            stepperCompactConstraints.forEach { $0.isActive = true }
        }
    }

    private func focusOnZoomLevel() {
        if UIAccessibility.isVoiceOverRunning {
            UIAccessibility.post(notification: .layoutChanged, argument: zoomLevel)
        }
    }

    @objc
    private func didPressZoomIn(_ sender: UIButton) {
        tab.zoomIn()
        updateZoomLabel()
        delegate?.didChangeZoomLevel()
        zoomOutButton.isEnabled = true
        if tab.pageZoom >= UX.upperZoomLimit {
            zoomInButton.isEnabled = false
        }
    }

    @objc
    private func didPressZoomOut(_ sender: UIButton) {
        tab.zoomOut()
        updateZoomLabel()
        delegate?.didChangeZoomLevel()
        zoomInButton.isEnabled = true
        if tab.pageZoom <= UX.lowerZoomLimit {
            zoomOutButton.isEnabled = false
        }
    }

    @objc
    private func didPressReset(_ recognizer: UITapGestureRecognizer) {
        if recognizer.state == .ended {
            tab.resetZoom()
            updateZoomLabel()
            delegate?.didChangeZoomLevel()
            enableZoomButtons()
        }
    }

    @objc
    private func didPressClose(_ sender: UIButton) {
        delegate?.zoomPageDidPressClose()
        if UIAccessibility.isVoiceOverRunning {
            UIAccessibility.post(notification: .layoutChanged, argument: nil)
        }
    }

    func updateAlphaForSubviews(_ alpha: CGFloat) {
        self.alpha = alpha
    }

    func applyTheme(theme: Theme) {
        let colors = theme.colors
        backgroundColor = colors.layer1
        stepperContainer.backgroundColor = colors.layer5
        stepperContainer.layer.shadowColor = colors.shadowDefault.cgColor
        leftSeparator.backgroundColor = colors.borderPrimary
        rightSeparator.backgroundColor = colors.borderPrimary
        zoomLevel.tintColor = colors.textPrimary
        zoomInButton.tintColor = colors.iconPrimary
        zoomOutButton.tintColor = colors.iconPrimary
        closeButton.tintColor = colors.iconPrimary
        gradient.colors = traitCollection.userInterfaceIdiom == .pad ?
        colors.layerGradientOverlay.cgColors.reversed() :
        colors.layerGradientOverlay.cgColors
    }
}
