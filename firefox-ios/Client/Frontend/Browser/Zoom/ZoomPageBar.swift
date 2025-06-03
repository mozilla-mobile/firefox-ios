// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common
import Shared
import ComponentLibrary

// MARK: - ZoomPageBarDelegate Protocol

protocol ZoomPageBarDelegate: AnyObject {
    func zoomPageDidPressClose()
}

final class ZoomPageBar: UIView, ThemeApplicable, AlphaDimmable {
    // MARK: - Constants

    private struct UX {
        static let padding: CGFloat = 20
        static let buttonInsets = NSDirectionalEdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16)
        static let stepperHeight: CGFloat = 36
        static let stepperTopBottomPadding: CGFloat = 12
        static let stepperCornerRadius: CGFloat = 6
        static let stepperMinTrailing: CGFloat = 10
        static let stepperSpacing: CGFloat = 8
        static let shadowRadius: CGFloat = 4
        static let shadowOpacity: Float = 1
        static let stepperShadowOffset = CGSize(width: 0, height: 3)
        static let separatorWidth: CGFloat = 1
        static let separatorHeightMultiplier = 0.4
        static let closButtonSize: CGFloat = 30
        static let closButtonLargeSize: CGFloat = 48
        static let shadowHeightOffset = 6
    }

    // MARK: - Properties

    weak var delegate: ZoomPageBarDelegate?
    private let gestureRecognizer = UITapGestureRecognizer()
    private var stepperCompactConstraints = [NSLayoutConstraint]()
    private var stepperDefaultConstraints = [NSLayoutConstraint]()
    private let zoomManager: ZoomPageManager
    private let zoomTelemetry: ZoomTelemetry
    private let toolbarHelper: ToolbarHelperInterface

    // MARK: - UI Elements

    private let leftSeparator: UIView = .build()
    private let rightSeparator: UIView = .build()

    private lazy var stepperContainer: UIStackView = .build { view in
        view.axis = .horizontal
        view.alignment = .center
        view.distribution = .fillProportionally
        view.spacing = UX.stepperSpacing
        view.layer.cornerRadius = UX.stepperCornerRadius
        view.layer.shadowRadius = UX.shadowRadius
        view.layer.shadowOffset = UX.stepperShadowOffset
        view.layer.shadowOpacity = UX.shadowOpacity
        view.clipsToBounds = false
    }

    private lazy var zoomOutButton: UIButton = .build { button in
        self.configureButton(button,
                             image: UIImage.templateImageNamed(StandardImageIdentifiers.Large.subtract),
                             accessibilityLabel: .LegacyAppMenu.ZoomPageDecreaseZoomAccessibilityLabel,
                             accessibilityIdentifier: AccessibilityIdentifiers.ZoomPageBar.zoomPageZoomOutButton)
        button.setContentHuggingPriority(.required, for: .horizontal)
        button.configuration = .plain()
        button.configuration?.contentInsets = UX.buttonInsets
        button.configuration?.contentInsets = UX.buttonInsets
    }

    private lazy var zoomLevel: UILabel = .build { label in
        label.font = FXFontStyles.Regular.body.scaledFont()
        label.accessibilityIdentifier = AccessibilityIdentifiers.ZoomPageBar.zoomPageZoomLevelLabel
        label.isUserInteractionEnabled = true
        label.adjustsFontForContentSizeCategory = true
        label.textAlignment = .center
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    private lazy var zoomInButton: UIButton = .build { button in
        self.configureButton(button,
                             image: UIImage.templateImageNamed(StandardImageIdentifiers.Large.plus),
                             accessibilityLabel: .LegacyAppMenu.ZoomPageIncreaseZoomAccessibilityLabel,
                             accessibilityIdentifier: AccessibilityIdentifiers.ZoomPageBar.zoomPageZoomInButton)
        button.setContentHuggingPriority(.required, for: .horizontal)
        button.configuration = .plain()
        button.configuration?.contentInsets = UX.buttonInsets
    }

    private lazy var closeButton: CloseButton = .build()

    // MARK: - Initializers

    init(zoomManager: ZoomPageManager,
         gleanWrapper: GleanWrapper = DefaultGleanWrapper(),
         toolbarHelper: ToolbarHelperInterface = ToolbarHelper()) {
        self.zoomManager = zoomManager
        self.zoomTelemetry = ZoomTelemetry(gleanWrapper: gleanWrapper)
        self.toolbarHelper = toolbarHelper
        super.init(frame: .zero)

        setupViews()
        setupLayout()
        setupShadow()
        focusOnZoomLevel()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Setup

    private func setupViews() {
        zoomInButton.addTarget(self, action: #selector(didPressZoomIn), for: .touchUpInside)
        zoomOutButton.addTarget(self, action: #selector(didPressZoomOut), for: .touchUpInside)
        closeButton.addTarget(self, action: #selector(didPressClose), for: .touchUpInside)

        gestureRecognizer.addTarget(self, action: #selector(didPressReset))
        zoomLevel.addGestureRecognizer(gestureRecognizer)

        let zoomValue = zoomManager.getZoomLevel()
        updateZoomLabel(zoomValue: zoomValue)
        updateZoomButtonEnabled(zoomValue: zoomValue)

        let closeButtonViewModel = CloseButtonViewModel(
            a11yLabel: .LegacyAppMenu.ZoomPageCloseAccessibilityLabel,
            a11yIdentifier: AccessibilityIdentifiers.FindInPage.findInPageCloseButton)
        closeButton.configure(viewModel: closeButtonViewModel)

        [zoomOutButton, leftSeparator, zoomLevel, rightSeparator, zoomInButton].forEach {
            stepperContainer.addArrangedSubview($0)
        }
        stepperContainer.setCustomSpacing(0, after: zoomOutButton)
        stepperContainer.setCustomSpacing(0, after: rightSeparator)
        stepperContainer.accessibilityElements = [zoomOutButton, zoomLevel, zoomInButton]

        addSubviews(stepperContainer, closeButton)
    }

    private func setupLayout() {
        stepperCompactConstraints.append(stepperContainer.leadingAnchor.constraint(equalTo: leadingAnchor,
                                                                                   constant: UX.padding))
        stepperDefaultConstraints.append(stepperContainer.centerXAnchor.constraint(equalTo: centerXAnchor))
        stepperDefaultConstraints.append(stepperContainer.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor,
                                                                                   constant: UX.padding))
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
            stepperContainer.centerYAnchor.constraint(equalTo: centerYAnchor),

            closeButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            closeButton.trailingAnchor.constraint(equalTo: trailingAnchor,
                                                  constant: -UX.padding),
        ])
        setupCloseButtonConstraints()
    }

    func setupCloseButtonConstraints() {
        let isAccessibilityCategory = UIApplication.shared.preferredContentSizeCategory.isAccessibilityCategory
        let closeButtonSizes = isAccessibilityCategory ? UX.closButtonLargeSize : UX.closButtonSize
        closeButton.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        closeButton.trailingAnchor.constraint(equalTo: trailingAnchor,
                                              constant: -UX.padding).isActive = true
        closeButton.heightAnchor.constraint(equalToConstant: closeButtonSizes).isActive = true
        closeButton.widthAnchor.constraint(equalToConstant: closeButtonSizes).isActive = true
        closeButton.layer.cornerRadius = 0.5 * closeButtonSizes
    }

    private func setupSeparator(_ separator: UIView) {
        separator.widthAnchor.constraint(equalToConstant: UX.separatorWidth).isActive = true
        separator.heightAnchor.constraint(equalTo: stepperContainer.heightAnchor,
                                          multiplier: UX.separatorHeightMultiplier).isActive = true
    }

    private func setupShadow() {
        if traitCollection.userInterfaceIdiom == .pad {
            layer.shadowOffset = CGSize(width: 0, height: UX.shadowHeightOffset)
        } else {
            layer.shadowOffset = CGSize(width: 0, height: -UX.shadowHeightOffset)
        }
        layer.shadowRadius = UX.shadowRadius
        layer.shadowOpacity = UX.shadowOpacity
    }

    // MARK: - Layout Overrides

    override func layoutSubviews() {
        super.layoutSubviews()
        updateStepperConstraintsBasedOnSizeClass()
        setupCloseButtonConstraints()
        layoutIfNeeded()
    }

    // MARK: - Helper Methods

    private func configureButton(_ button: UIButton,
                                 image: UIImage?,
                                 accessibilityLabel: String?,
                                 accessibilityIdentifier: String?) {
        button.setImage(image, for: [])
        button.accessibilityLabel = accessibilityLabel
        button.accessibilityIdentifier = accessibilityIdentifier
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    func updateZoomLabel(zoomValue: CGFloat) {
        zoomLevel.text = NumberFormatter.localizedString(from: NSNumber(value: zoomValue), number: .percent)
        zoomLevel.isEnabled = zoomValue == ZoomConstants.defaultZoomLimit ? false : true
        gestureRecognizer.isEnabled = !(zoomValue == ZoomConstants.defaultZoomLimit)
        zoomLevel.accessibilityLabel = String(format: .LegacyAppMenu.ZoomPageCurrentZoomLevelAccessibilityLabel,
                                              zoomLevel.text ?? "")
    }

    private func updateZoomButtonEnabled(zoomValue: CGFloat) {
        zoomInButton.isEnabled = zoomValue < ZoomConstants.upperZoomLimit
        zoomOutButton.isEnabled = zoomValue > ZoomConstants.lowerZoomLimit
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

    // MARK: - Actions

    @objc
    private func didPressZoomIn(_ sender: UIButton) {
        let level = zoomManager.zoomIn()
        updateZoomLabel(zoomValue: level)
        updateZoomButtonEnabled(zoomValue: level)
        zoomTelemetry.zoomIn(zoomLevel: ZoomLevel(from: level))
    }

    @objc
    private func didPressZoomOut(_ sender: UIButton) {
        let level = zoomManager.zoomOut()
        updateZoomLabel(zoomValue: level)
        updateZoomButtonEnabled(zoomValue: level)
        zoomTelemetry.zoomOut(zoomLevel: ZoomLevel(from: level))
    }

    @objc
    private func didPressReset(_ recognizer: UITapGestureRecognizer) {
        if recognizer.state == .ended {
            zoomManager.resetZoom()
            updateZoomLabel(zoomValue: ZoomConstants.defaultZoomLimit)
            updateZoomButtonEnabled(zoomValue: ZoomConstants.defaultZoomLimit)
            zoomTelemetry.resetZoomLevel()
        }
    }

    @objc
    private func didPressClose(_ sender: UIButton) {
        delegate?.zoomPageDidPressClose()
        if UIAccessibility.isVoiceOverRunning {
            UIAccessibility.post(notification: .layoutChanged, argument: nil)
        }
        zoomTelemetry.closeZoomBar()
    }

    // MARK: - AlphaDimmable

    func updateAlphaForSubviews(_ alpha: CGFloat) {
        self.alpha = alpha
    }

    // MARK: - ThemeApplicable

    func applyTheme(theme: Theme) {
        let colors = theme.colors
        let backgroundAlpha = toolbarHelper.backgroundAlpha()
        backgroundColor = colors.layer2.withAlphaComponent(backgroundAlpha)

        stepperContainer.backgroundColor = colors.layer5
        stepperContainer.layer.shadowColor = colors.shadowDefault.cgColor
        leftSeparator.backgroundColor = colors.borderPrimary
        rightSeparator.backgroundColor = colors.borderPrimary
        zoomLevel.tintColor = colors.textPrimary
        zoomInButton.tintColor = colors.iconPrimary
        let zoomInButtonImageColorTransformer = UIConfigurationColorTransformer({ [weak zoomInButton] baseColor in
            return zoomInButton?.state == .highlighted ? colors.iconDisabled : baseColor
        })
        zoomInButton.configuration?.imageColorTransformer = zoomInButtonImageColorTransformer
        zoomOutButton.tintColor = colors.iconPrimary
        let zoomOutButtonImageColorTransformer = UIConfigurationColorTransformer({ [weak zoomOutButton] baseColor in
            return zoomOutButton?.state == .highlighted ? colors.iconDisabled : baseColor
        })
        zoomOutButton.configuration?.imageColorTransformer = zoomOutButtonImageColorTransformer
        // Close button
        let buttonImage = UIImage(named: StandardImageIdentifiers.Medium.cross)?
            .withTintColor(theme.colors.iconSecondary)
        closeButton.setImage(buttonImage, for: .normal)
        closeButton.backgroundColor = colors.layer4

        layer.shadowColor = colors.shadowDefault.cgColor
    }
}
