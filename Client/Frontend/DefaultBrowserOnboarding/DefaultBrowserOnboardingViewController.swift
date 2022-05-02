// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

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

struct DBOnboardingUX {
    static let textOffset = 20
    static let textOffsetSmall = 13
    static let fontSize: CGFloat = 24
    static let fontSizeSmall: CGFloat = 20
    static let fontSizeXSmall: CGFloat = 16
    static let titleSize: CGFloat = 28
    static let titleSizeSmall: CGFloat = 24
    static let titleSizeLarge: CGFloat = 34
    static let containerViewHeight = 350
    static let containerViewHeightSmall = 300
    static let containerViewHeightXSmall = 250
}

class DefaultBrowserOnboardingViewController: UIViewController, OnViewDismissable {

    // MARK: - Properties

    var onViewDismissed: (() -> Void)? = nil
    // Public constants
    let viewModel = DefaultBrowserOnboardingViewModel()
    let theme = LegacyThemeManager.instance

    // Private vars
    private var fxTextThemeColour: UIColor {
        // For dark theme we want to show light colours and for light we want to show dark colours
        return theme.currentName == .dark ? .white : .black
    }

    private var fxBackgroundThemeColour: UIColor = UIColor.theme.onboarding.backgroundColor

    private var descriptionFontSize: CGFloat {
        return screenSize.height > 1000 ? DBOnboardingUX.fontSizeXSmall :
               screenSize.height > 668 ? DBOnboardingUX.fontSize :
               screenSize.height > 640 ? DBOnboardingUX.fontSizeSmall : DBOnboardingUX.fontSizeXSmall
    }

    private var titleFontSize: CGFloat {
        return screenSize.height > 1000 ? DBOnboardingUX.titleSizeLarge :
               screenSize.height > 640 ? DBOnboardingUX.titleSize : DBOnboardingUX.titleSizeSmall
    }

    // Orientation independent screen size
    private let screenSize = DeviceInfo.screenSizeOrientationIndependent()

    // UI
    private lazy var closeButton: UIButton = .build { [weak self] button in
        button.setImage(UIImage(named: "close-large"), for: .normal)
        button.tintColor = .secondaryLabel
        button.addTarget(self, action: #selector(self?.dismissAnimated), for: .touchUpInside)
    }

    private let textView: UIView = .build { view in }

    private lazy var titleLabel: UILabel = .build { [weak self] label in
        guard let self = self else { return }
        label.text = self.viewModel.model?.titleText
        label.font = .boldSystemFont(ofSize: self.titleFontSize)
        label.textAlignment = .center
        label.numberOfLines = 2
    }

    private lazy var descriptionText: UILabel = .build { [weak self] label in
        guard let self = self else { return }
        label.text = self.viewModel.model?.descriptionText[0]
        label.font = DynamicFontHelper.defaultHelper.preferredFont(withTextStyle: .body, maxSize: 28)
        label.textAlignment = .left
        label.numberOfLines = 5
        label.adjustsFontSizeToFitWidth = true
    }

    private lazy var descriptionLabel1: UILabel = .build() { [weak self] label in
        guard let self = self else { return }
        label.text = self.viewModel.model?.descriptionText[1]
        label.font = DynamicFontHelper.defaultHelper.preferredFont(withTextStyle: .body, maxSize: 36)
        label.textAlignment = .left
        label.numberOfLines = 0
        label.adjustsFontSizeToFitWidth = true
    }

    private lazy var descriptionLabel2: UILabel = .build { [weak self] label in
        guard let self = self else { return }
        label.text = self.viewModel.model?.descriptionText[2]
        label.font = DynamicFontHelper.defaultHelper.preferredFont(withTextStyle: .body, maxSize: 36)
        label.textAlignment = .left
        label.numberOfLines = 0
        label.adjustsFontSizeToFitWidth = true
    }

    private lazy var descriptionLabel3: UILabel = .build { [weak self] label in
        guard let self = self else { return }
        label.text = self.viewModel.model?.descriptionText[3]
        label.font = DynamicFontHelper.defaultHelper.preferredFont(withTextStyle: .body, maxSize: 36)
        label.textAlignment = .left
        label.numberOfLines = 0
        label.adjustsFontSizeToFitWidth = true
    }

    private lazy var goToSettingsButton: UIButton = .build { [weak self] button in
        guard let self = self else { return }
        button.setTitle(.DefaultBrowserOnboardingButton, for: .normal)
        button.layer.cornerRadius = UpdateViewControllerUX.StartBrowsingButton.cornerRadius
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UpdateViewControllerUX.StartBrowsingButton.colour
        button.accessibilityIdentifier = "HomeTabBanner.goToSettingsButton"
        button.addTarget(self, action: #selector(self.goToSettings), for: .touchUpInside)
        button.titleLabel?.font = DynamicFontHelper.defaultHelper.preferredFont(withTextStyle: .title3, maxSize: 40)
        button.titleLabel?.adjustsFontSizeToFitWidth = true
    }

    // Used to set the part of text in center 
    private var containerView = UIView()

    // MARK: - Inits

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycles
    override func viewDidLoad() {
        super.viewDidLoad()
        initialViewSetup()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Portrait orientation: lock enable
        AppDelegate.AppUtility.lockOrientation(UIInterfaceOrientationMask.portrait, andRotateTo: UIInterfaceOrientation.portrait)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Portrait orientation: lock disable
        AppDelegate.AppUtility.lockOrientation(UIInterfaceOrientationMask.all)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        onViewDismissed?()
        onViewDismissed = nil
    }

    func initialViewSetup() {
        updateTheme()

        view.addSubview(closeButton)
        textView.addSubview(containerView)
        containerView.addSubviews(titleLabel, descriptionText, descriptionLabel1, descriptionLabel2, descriptionLabel3)
        view.addSubviews(textView, goToSettingsButton)

        // Constraints
        setupView()

        // Theme change notification
        NotificationCenter.default.addObserver(self, selector: #selector(updateTheme), name: .DisplayThemeChanged, object: nil)
    }

    private func setupView() {

        let textOffset = screenSize.height > 668 ? DBOnboardingUX.textOffset : DBOnboardingUX.textOffsetSmall

        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 10),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            closeButton.heightAnchor.constraint(equalToConstant: 44),

            textView.topAnchor.constraint(equalTo: closeButton.bottomAnchor, constant: 10),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 36),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -36),
            textView.bottomAnchor.constraint(equalTo: goToSettingsButton.topAnchor),

            titleLabel.centerXAnchor.constraint(lessThanOrEqualTo: view.centerXAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),

            descriptionText.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: CGFloat(textOffset)),
            descriptionText.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: CGFloat(textOffset)),
            descriptionText.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: CGFloat(-textOffset)),

            descriptionLabel1.topAnchor.constraint(equalTo: descriptionText.bottomAnchor, constant: CGFloat(textOffset)),
            descriptionLabel1.leadingAnchor.constraint(equalTo: descriptionText.leadingAnchor),
            descriptionLabel1.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            descriptionLabel2.topAnchor.constraint(equalTo: descriptionLabel1.bottomAnchor, constant: CGFloat(textOffset)),
            descriptionLabel2.leadingAnchor.constraint(equalTo: descriptionLabel1.leadingAnchor),
            descriptionLabel2.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            descriptionLabel3.topAnchor.constraint(equalTo: descriptionLabel2.bottomAnchor, constant: CGFloat(textOffset)),
            descriptionLabel3.leadingAnchor.constraint(equalTo: descriptionLabel2.leadingAnchor),
            descriptionLabel3.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])

        if screenSize.height > 1000 {
            NSLayoutConstraint.activate([
                goToSettingsButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -60),
                goToSettingsButton.heightAnchor.constraint(equalToConstant: 50),
                goToSettingsButton.widthAnchor.constraint(equalToConstant: 350)
            ])
        } else if screenSize.height > 640 {
            NSLayoutConstraint.activate([
                goToSettingsButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -5),
                goToSettingsButton.heightAnchor.constraint(equalToConstant: 60),
                goToSettingsButton.widthAnchor.constraint(equalToConstant: 350)
            ])
        } else {
            NSLayoutConstraint.activate([
                goToSettingsButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -5),
                goToSettingsButton.heightAnchor.constraint(equalToConstant: 50),
                goToSettingsButton.widthAnchor.constraint(equalToConstant: 300)
            ])
        }
        goToSettingsButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
    }

    // Button Actions
    @objc private func dismissAnimated() {
        self.dismiss(animated: true, completion: nil)
        TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .dismissDefaultBrowserOnboarding)
    }

    @objc private func goToSettings() {
        viewModel.goToSettings?()
        UserDefaults.standard.set(true, forKey: "DidDismissDefaultBrowserCard") // Don't show default browser card if this button is clicked
        TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .goToSettingsDefaultBrowserOnboarding)
    }

    // Theme
    @objc func updateTheme() {
        view.backgroundColor = .systemBackground
        titleLabel.textColor = fxTextThemeColour
        descriptionText.textColor = fxTextThemeColour
        descriptionLabel1.textColor = fxTextThemeColour
        descriptionLabel2.textColor = fxTextThemeColour
        descriptionLabel3.textColor = fxTextThemeColour
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
