// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import ComponentLibrary
import Foundation
import UIKit
import Shared

/*
    
 |----------------|
 |              X |
 |Title Multiline |
 |                | (Top View)
 |Description     |
 |Multiline       |
 |                |
 |                |
 |                |
 |----------------|
 |    [Button]    | (Bottom View)
 |----------------|
 
 */

class DefaultBrowserOnboardingViewController: UIViewController, OnViewDismissable, Themeable {
    private struct UX {
        static let textOffset: CGFloat = 20
        static let textOffsetSmall: CGFloat = 13
        static let ctaButtonWidth: CGFloat = 350
        static let ctaButtonWidthSmall: CGFloat = 300
        static let ctaButtonBottomSpace: CGFloat = 60
        static let ctaButtonBottomSpaceSmall: CGFloat = 5
        static let closeButtonSize = CGRect(width: 44, height: 44)
    }

    // MARK: - Properties
    var themeManager: ThemeManager
    var themeObserver: NSObjectProtocol?
    var notificationCenter: NotificationProtocol
    var onViewDismissed: (() -> Void)?

    // Public constants
    let viewModel = DefaultBrowserOnboardingViewModel()
    let windowUUID: WindowUUID
    var currentWindowUUID: UUID? { windowUUID }

    // Orientation independent screen size
    private let screenSize = DeviceInfo.screenSizeOrientationIndependent()

    // UI
    private lazy var scrollView: UIScrollView = .build { view in
        view.backgroundColor = .clear
    }

    private lazy var containerView: UIView = .build { _ in }

    private lazy var closeButton: UIButton = .build { button in
        button.setImage(UIImage(named: StandardImageIdentifiers.ExtraLarge.crossCircleFill), for: .normal)
        button.accessibilityIdentifier = AccessibilityIdentifiers.FirefoxHomepage.HomeTabBanner.closeButton
    }

    private lazy var titleLabel: UILabel = .build { [weak self] label in
        label.font = FXFontStyles.Bold.title1.scaledFont()
        label.textAlignment = .center
        label.numberOfLines = 0
        label.accessibilityIdentifier = AccessibilityIdentifiers.FirefoxHomepage.HomeTabBanner.titleLabel
    }

    private lazy var descriptionText: UILabel = .build { label in
        label.font = FXFontStyles.Regular.body.scaledFont()
        label.numberOfLines = 0
        label.accessibilityIdentifier = AccessibilityIdentifiers.FirefoxHomepage.HomeTabBanner.descriptionLabel
    }

    private lazy var descriptionLabel1: UILabel = .build { label in
        label.font = FXFontStyles.Regular.body.scaledFont()
        label.numberOfLines = 0
        label.accessibilityIdentifier = AccessibilityIdentifiers.FirefoxHomepage.HomeTabBanner.descriptionLabel1
    }

    private lazy var descriptionLabel2: UILabel = .build { label in
        label.font = FXFontStyles.Regular.body.scaledFont()
        label.numberOfLines = 0
        label.accessibilityIdentifier = AccessibilityIdentifiers.FirefoxHomepage.HomeTabBanner.descriptionLabel2
    }

    private lazy var descriptionLabel3: UILabel = .build { label in
        label.font = FXFontStyles.Regular.body.scaledFont()
        label.numberOfLines = 0
        label.accessibilityIdentifier = AccessibilityIdentifiers.FirefoxHomepage.HomeTabBanner.descriptionLabel3
    }

    private lazy var goToSettingsButton: PrimaryRoundedButton = .build { button in
        button.addTarget(self, action: #selector(self.goToSettings), for: .touchUpInside)
    }

    // MARK: - Inits

    init(windowUUID: WindowUUID,
         themeManager: ThemeManager = AppContainer.shared.resolve(),
         notificationCenter: NotificationProtocol = NotificationCenter.default) {
        self.themeManager = themeManager
        self.windowUUID = windowUUID
        self.notificationCenter = notificationCenter
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycles
    override func viewDidLoad() {
        super.viewDidLoad()

        initialViewSetup()
        listenForThemeChange(view)
        applyTheme()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        onViewDismissed?()
        onViewDismissed = nil
    }

    private func currentTheme() -> Theme {
        return themeManager.getCurrentTheme(for: windowUUID)
    }

    func initialViewSetup() {
        titleLabel.text = viewModel.model?.titleText
        descriptionText.text = viewModel.model?.descriptionText[0]
        descriptionLabel1.text = viewModel.model?.descriptionText[1]
        descriptionLabel2.text = viewModel.model?.descriptionText[2]
        descriptionLabel3.text = viewModel.model?.descriptionText[3]

        closeButton.addTarget(self, action: #selector(dismissAnimated), for: .touchUpInside)

        let goToSettingsButtonViewModel = PrimaryRoundedButtonViewModel(
            title: .DefaultBrowserOnboardingButton,
            a11yIdentifier: AccessibilityIdentifiers.FirefoxHomepage.HomeTabBanner.ctaButton
        )
        goToSettingsButton.configure(viewModel: goToSettingsButtonViewModel)
        goToSettingsButton.applyTheme(theme: currentTheme())

        setupLayout()
    }

    private func setupLayout() {
        let textOffset: CGFloat = screenSize.height > 668 ? UX.textOffset : UX.textOffsetSmall

        let containerHeightConstraint = containerView.heightAnchor.constraint(equalTo: scrollView.heightAnchor)
        containerHeightConstraint.priority = .defaultLow

        view.addSubview(closeButton)
        containerView.addSubview(titleLabel)
        containerView.addSubview(descriptionText)
        containerView.addSubview(descriptionLabel1)
        containerView.addSubview(descriptionLabel2)
        containerView.addSubview(descriptionLabel3)
        containerView.addSubview(goToSettingsButton)
        scrollView.addSubviews(containerView)
        view.addSubviews(scrollView)

        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 10),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            closeButton.heightAnchor.constraint(equalToConstant: UX.closeButtonSize.height),
            closeButton.widthAnchor.constraint(equalToConstant: UX.closeButtonSize.width),

            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.topAnchor.constraint(equalTo: closeButton.bottomAnchor, constant: 10),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            scrollView.frameLayoutGuide.widthAnchor.constraint(equalTo: containerView.widthAnchor),

            scrollView.contentLayoutGuide.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            scrollView.contentLayoutGuide.topAnchor.constraint(equalTo: containerView.topAnchor),
            scrollView.contentLayoutGuide.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            scrollView.contentLayoutGuide.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),

            containerHeightConstraint,

            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: textOffset),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -textOffset),

            descriptionText.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: textOffset),
            descriptionText.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: textOffset),
            descriptionText.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -textOffset),

            descriptionLabel1.topAnchor.constraint(equalTo: descriptionText.bottomAnchor, constant: textOffset),
            descriptionLabel1.leadingAnchor.constraint(equalTo: descriptionText.leadingAnchor),
            descriptionLabel1.trailingAnchor.constraint(equalTo: descriptionText.trailingAnchor),

            descriptionLabel2.topAnchor.constraint(equalTo: descriptionLabel1.bottomAnchor, constant: textOffset),
            descriptionLabel2.leadingAnchor.constraint(equalTo: descriptionLabel1.leadingAnchor),
            descriptionLabel2.trailingAnchor.constraint(equalTo: descriptionLabel1.trailingAnchor),

            descriptionLabel3.topAnchor.constraint(equalTo: descriptionLabel2.bottomAnchor, constant: textOffset),
            descriptionLabel3.leadingAnchor.constraint(equalTo: descriptionLabel2.leadingAnchor),
            descriptionLabel3.trailingAnchor.constraint(equalTo: descriptionLabel2.trailingAnchor),

            goToSettingsButton.topAnchor.constraint(greaterThanOrEqualTo: descriptionLabel3.bottomAnchor, constant: 24)
        ])

        if screenSize.height > 1000 {
            NSLayoutConstraint.activate([
                goToSettingsButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor,
                                                           constant: -UX.ctaButtonBottomSpace),
                goToSettingsButton.widthAnchor.constraint(equalToConstant: UX.ctaButtonWidth)
            ])
        } else if screenSize.height > 640 {
            NSLayoutConstraint.activate([
                goToSettingsButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor,
                                                           constant: -UX.ctaButtonBottomSpaceSmall),
                goToSettingsButton.widthAnchor.constraint(equalToConstant: UX.ctaButtonWidth)
            ])
        } else {
            NSLayoutConstraint.activate([
                goToSettingsButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor,
                                                           constant: -UX.ctaButtonBottomSpaceSmall),
                goToSettingsButton.widthAnchor.constraint(equalToConstant: UX.ctaButtonWidthSmall)
            ])
        }
        goToSettingsButton.centerXAnchor.constraint(equalTo: containerView.centerXAnchor).isActive = true
    }

    // Button Actions
    @objc
    private func dismissAnimated() {
        viewModel.didAskToDismissView?()
        TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .dismissDefaultBrowserOnboarding)
    }

    @objc
    private func goToSettings() {
        viewModel.goToSettings?()

        // Don't show default browser card if this button is clicked
        UserDefaults.standard.set(true, forKey: PrefsKeys.DidDismissDefaultBrowserMessage)
        TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .goToSettingsDefaultBrowserOnboarding)

        DefaultApplicationHelper().openSettings()
    }

    // MARK: Themeable
    func applyTheme() {
        let theme = currentTheme()

        view.backgroundColor = theme.colors.layer1
        titleLabel.textColor = theme.colors.textPrimary

        descriptionText.textColor = theme.colors.textPrimary
        descriptionLabel1.textColor = theme.colors.textPrimary
        descriptionLabel2.textColor = theme.colors.textPrimary
        descriptionLabel3.textColor = theme.colors.textPrimary

        closeButton.tintColor = theme.colors.textSecondary
    }

    // MARK: - Orientation

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    override var shouldAutorotate: Bool {
        return false
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
