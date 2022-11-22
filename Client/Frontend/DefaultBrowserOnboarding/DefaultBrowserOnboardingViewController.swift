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
    static let textOffset: CGFloat = 20
    static let textOffsetSmall: CGFloat = 13
    static let fontSize: CGFloat = 24
    static let fontSizeSmall: CGFloat = 20
    static let fontSizeXSmall: CGFloat = 16
    static let titleSize: CGFloat = 28
    static let titleSizeSmall: CGFloat = 24
    static let titleSizeLarge: CGFloat = 34
    static let buttonCornerRadius: CGFloat = 10
    static let buttonColour = UIColor.Photon.Blue50
}

class DefaultBrowserOnboardingViewController: UIViewController, OnViewDismissable {

    // MARK: - Properties

    var onViewDismissed: (() -> Void)?
    // Public constants
    let viewModel = DefaultBrowserOnboardingViewModel()
    let theme = LegacyThemeManager.instance

    // Private vars
    private var fxTextThemeColour: UIColor {
        // For dark theme we want to show light colours and for light we want to show dark colours
        return theme.currentName == .dark ? .white : .black
    }

    private var titleFontSize: CGFloat {
        return screenSize.height > 1000 ? DBOnboardingUX.titleSizeLarge :
               screenSize.height > 640 ? DBOnboardingUX.titleSize : DBOnboardingUX.titleSizeSmall
    }

    // Orientation independent screen size
    private let screenSize = DeviceInfo.screenSizeOrientationIndependent()

    // UI
    private lazy var scrollView: UIScrollView = .build { view in
        view.backgroundColor = .clear
    }

    private lazy var containerView: UIView = .build { _ in }

    private lazy var closeButton: UIButton = .build { [weak self] button in
        button.setImage(UIImage(named: "close-large"), for: .normal)
        button.tintColor = .secondaryLabel
        button.addTarget(self, action: #selector(self?.dismissAnimated), for: .touchUpInside)
    }

    private lazy var titleLabel: UILabel = .build { [weak self] label in
        guard let self = self else { return }
        label.text = self.viewModel.model?.titleText
        label.font = DynamicFontHelper.defaultHelper.preferredBoldFont(withTextStyle: .title1,
                                                                       size: self.titleFontSize)
        label.textAlignment = .center
        label.numberOfLines = 0
    }

    private lazy var descriptionText: UILabel = .build { [weak self] label in
        guard let self = self else { return }
        label.text = self.viewModel.model?.descriptionText[0]
        label.font = DynamicFontHelper.defaultHelper.preferredFont(withTextStyle: .body, size: 17)
        label.numberOfLines = 0
    }

    private lazy var descriptionLabel1: UILabel = .build { [weak self] label in
        guard let self = self else { return }
        label.text = self.viewModel.model?.descriptionText[1]
        label.font = DynamicFontHelper.defaultHelper.preferredFont(withTextStyle: .body, size: 17)
        label.numberOfLines = 0
    }

    private lazy var descriptionLabel2: UILabel = .build { [weak self] label in
        guard let self = self else { return }
        label.text = self.viewModel.model?.descriptionText[2]
        label.font = DynamicFontHelper.defaultHelper.preferredFont(withTextStyle: .body, size: 17)
        label.numberOfLines = 0
    }

    private lazy var descriptionLabel3: UILabel = .build { [weak self] label in
        guard let self = self else { return }
        label.text = self.viewModel.model?.descriptionText[3]
        label.font = DynamicFontHelper.defaultHelper.preferredFont(withTextStyle: .body, size: 17)
        label.numberOfLines = 0
    }

    private lazy var goToSettingsButton: ResizableButton = .build { [weak self] button in
        guard let self = self else { return }
        button.setTitle(.DefaultBrowserOnboardingButton, for: .normal)
        button.layer.cornerRadius = DBOnboardingUX.buttonCornerRadius
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = DBOnboardingUX.buttonColour
        button.accessibilityIdentifier = "HomeTabBanner.goToSettingsButton"
        button.addTarget(self, action: #selector(self.goToSettings), for: .touchUpInside)
        button.titleLabel?.font = DynamicFontHelper.defaultHelper.preferredFont(withTextStyle: .title3, size: 20)
        button.contentEdgeInsets = UIEdgeInsets(top: 15, left: 15, bottom: 15, right: 15)
        button.titleLabel?.textAlignment = .center
    }

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
        OrientationLockUtility.lockOrientation(UIInterfaceOrientationMask.portrait, andRotateTo: UIInterfaceOrientation.portrait)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Portrait orientation: lock disable
        OrientationLockUtility.lockOrientation(UIInterfaceOrientationMask.all)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        onViewDismissed?()
        onViewDismissed = nil
    }

    func initialViewSetup() {
        updateTheme()

        view.addSubview(closeButton)
        containerView.addSubview(titleLabel)
        containerView.addSubview(descriptionText)
        containerView.addSubview(descriptionLabel1)
        containerView.addSubview(descriptionLabel2)
        containerView.addSubview(descriptionLabel3)
        containerView.addSubview(goToSettingsButton)
        scrollView.addSubviews(containerView)
        view.addSubviews(scrollView)

        // Constraints
        setupLayout()

        // Theme change notification
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(updateTheme),
                                               name: .DisplayThemeChanged,
                                               object: nil)
    }

    private func setupLayout() {
        let textOffset: CGFloat = screenSize.height > 668 ? DBOnboardingUX.textOffset : DBOnboardingUX.textOffsetSmall

        let containerHeightConstraint = containerView.heightAnchor.constraint(equalTo: scrollView.heightAnchor)
        containerHeightConstraint.priority = .defaultLow

        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 10),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            closeButton.heightAnchor.constraint(equalToConstant: 44),

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
                                                           constant: -60),
                goToSettingsButton.widthAnchor.constraint(equalToConstant: 350)
            ])
        } else if screenSize.height > 640 {
            NSLayoutConstraint.activate([
                goToSettingsButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor,
                                                           constant: -5),
                goToSettingsButton.widthAnchor.constraint(equalToConstant: 350)
            ])
            goToSettingsButton.contentEdgeInsets = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        } else {
            NSLayoutConstraint.activate([
                goToSettingsButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor,
                                                           constant: -5),
                goToSettingsButton.widthAnchor.constraint(equalToConstant: 300)
            ])
        }
        goToSettingsButton.centerXAnchor.constraint(equalTo: containerView.centerXAnchor).isActive = true
    }

    // Button Actions
    @objc private func dismissAnimated() {
        self.dismiss(animated: true, completion: nil)
        TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .dismissDefaultBrowserOnboarding)
    }

    @objc private func goToSettings() {
        viewModel.goToSettings?()
        UserDefaults.standard.set(true, forKey: PrefsKeys.DidDismissDefaultBrowserMessage) // Don't show default browser card if this button is clicked
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
