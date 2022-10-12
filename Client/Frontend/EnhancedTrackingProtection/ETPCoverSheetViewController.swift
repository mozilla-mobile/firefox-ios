// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
import UIKit
import Shared

/* The layout for ETP Cover Sheet
    
 |----------------|
 |            Done|
 |                |
 |     Image      |
 |    [Centre]    | (Top View)
 |                |
 |Title Multiline |
 |                | 
 |Description     |
 |Multiline       |
 |                |
 |----------------|
 |                |
 |    [Button]    |
 |    [Button]    | (Bottom View)
 |----------------|
 
 */

class ETPCoverSheetViewController: UIViewController {

    struct UX {
        static let doneButtonPadding: CGFloat = 20
        static let doneButtonHeight: CGFloat = 20
        static let primaryButtonCornerRadius: CGFloat = 10
        static let primaryButtonHeight: CGFloat = 46
        static let primaryButtonEdgeInset: CGFloat = 18
        static let primaryButtonFontSize: CGFloat = 18
        static let horizontalMargin: CGFloat = 16
        static let largeVerticalMargin: CGFloat = 48
        static let imageHeight: CGFloat = 260
    }

    // Public constants
    let viewModel = ETPViewModel()
    var notificationCenter: NotificationProtocol = NotificationCenter.default

    private lazy var doneButton: UIButton = .build { button in
        button.setTitle(.SettingsSearchDoneButton, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: UX.primaryButtonFontSize,
                                                    weight: .regular)
        button.addTarget(self, action: #selector(self.dismissAnimated), for: .touchUpInside)
    }

    private lazy var pairImageView: UIImageView = .build { imageView in
        imageView.image = UIImage(named: ImageIdentifiers.signinSync)
        imageView.contentMode = .scaleAspectFit
    }

    private lazy var topImageView: UIImageView = .build { imageView in
        imageView.image = self.viewModel.etpCoverSheetmodel?.titleImage
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
    }

    private lazy var textStackView: UIStackView = .build { stackview in
        stackview.axis = .vertical
        stackview.spacing = UX.horizontalMargin
    }

    private lazy var titleLabel: UILabel = .build { label in
        label.text = self.viewModel.etpCoverSheetmodel?.titleText
        label.font = UIFont.boldSystemFont(ofSize: UX.primaryButtonFontSize)
        label.textAlignment = .left
        label.numberOfLines = 0
    }

    private lazy var descriptionLabel: UILabel = .build { label in
        label.text = self.viewModel.etpCoverSheetmodel?.descriptionText
        label.font = UIFont.systemFont(ofSize: 18)
        label.textAlignment = .left
        label.numberOfLines = 0
    }

    private lazy var goToSettingsButton: UIButton = .build { button in
        button.setTitle(.CoverSheetETPSettingsButton, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: UX.primaryButtonFontSize)
        button.layer.cornerRadius = UX.primaryButtonCornerRadius
        button.setTitleColor(.white, for: .normal)
        button.addTarget(self, action: #selector(self.goToSettings), for: .touchUpInside)
    }

    private lazy var startBrowsingButton: UIButton = .build { button in
        button.setTitle(.StartBrowsingButtonTitle, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: UX.primaryButtonFontSize)
        button.setTitleColor(UIColor.Photon.Blue50, for: .normal)
        button.backgroundColor = .clear
        button.addTarget(self, action: #selector(self.startBrowsing), for: .touchUpInside)
    }

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        initialViewSetup()
    }

    func initialViewSetup() {
        setupNotifications(forObserver: self,
                           observing: [.DisplayThemeChanged])
        setupLayout()
        applyTheme()
    }

    private func setupLayout() {
        // Initialize
        textStackView.addArrangedSubview(titleLabel)
        textStackView.addArrangedSubview(descriptionLabel)

        view.addSubviews(topImageView,
                         doneButton,
                         textStackView,
                         goToSettingsButton,
                         startBrowsingButton)

        // Constraints
        NSLayoutConstraint.activate([
            doneButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor,
                                             constant: UX.doneButtonPadding),
            doneButton.trailingAnchor.constraint(equalTo: view.trailingAnchor,
                                                  constant: -UX.doneButtonPadding),
            doneButton.heightAnchor.constraint(equalToConstant: UX.doneButtonPadding),

            topImageView.topAnchor.constraint(equalTo: doneButton.bottomAnchor,
                                              constant: UX.horizontalMargin),
            topImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor,
                                                   constant: UX.horizontalMargin),
            topImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor,
                                                    constant: -UX.horizontalMargin),
            topImageView.bottomAnchor.constraint(greaterThanOrEqualTo: textStackView.topAnchor,
                                                 constant: -UX.largeVerticalMargin),

            textStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor,
                                                   constant: UX.horizontalMargin),
            textStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor,
                                                    constant: -UX.horizontalMargin),
            textStackView.bottomAnchor.constraint(greaterThanOrEqualTo: goToSettingsButton.topAnchor,
                                                  constant: -UX.largeVerticalMargin),

            goToSettingsButton.leadingAnchor.constraint(equalTo: view.leadingAnchor,
                                                      constant: UX.primaryButtonEdgeInset),
            goToSettingsButton.trailingAnchor.constraint(equalTo: view.trailingAnchor,
                                                       constant: -UX.primaryButtonEdgeInset),
            goToSettingsButton.bottomAnchor.constraint(equalTo: startBrowsingButton.topAnchor,
                                                     constant: -UX.horizontalMargin),
            goToSettingsButton.heightAnchor.constraint(equalToConstant: UX.primaryButtonHeight),

            startBrowsingButton.leadingAnchor.constraint(equalTo: view.leadingAnchor,
                                                      constant: UX.primaryButtonEdgeInset),
            startBrowsingButton.trailingAnchor.constraint(equalTo: view.trailingAnchor,
                                                       constant: -UX.primaryButtonEdgeInset),
            startBrowsingButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor,
                                                     constant: -UX.horizontalMargin),
            startBrowsingButton.heightAnchor.constraint(equalToConstant: UX.primaryButtonHeight),
        ])
    }

    // Button Actions
    @objc private func dismissAnimated() {
        self.dismiss(animated: true, completion: nil)
        TelemetryWrapper.recordEvent(category: .action, method: .press, object: .dismissedETPCoverSheet)
    }

    @objc private func goToSettings() {
        viewModel.goToSettings?()
        TelemetryWrapper.recordEvent(category: .action, method: .press, object: .dismissETPCoverSheetAndGoToSettings)
    }

    @objc private func startBrowsing() {
        viewModel.startBrowsing?()
        TelemetryWrapper.recordEvent(category: .action, method: .press, object: .dismissUpdateCoverSheetAndStartBrowsing)
    }
}

// MARK: - Notifiable
extension ETPCoverSheetViewController: Notifiable {
    func handleNotifications(_ notification: Notification) {
        switch notification.name {
        case .DisplayThemeChanged:
            applyTheme()
        default:
            break
        }
    }

    func applyTheme() {
        titleLabel.textColor = LegacyThemeManager.instance.current.onboarding.etpTextColor
        descriptionLabel.textColor = LegacyThemeManager.instance.current.onboarding.etpTextColor
        view.backgroundColor = LegacyThemeManager.instance.current.onboarding.etpBackgroundColor
        doneButton.setTitleColor(LegacyThemeManager.instance.current.onboarding.etpButtonColor, for: [])
        startBrowsingButton.setTitleColor(LegacyThemeManager.instance.current.onboarding.etpButtonColor, for: [])
        goToSettingsButton.setTitleColor(.black, for: [])
        goToSettingsButton.backgroundColor = LegacyThemeManager.instance.current.onboarding.etpButtonColor
    }
}

// UIViewController setup to keep it in portrait mode
extension ETPCoverSheetViewController {
    override var shouldAutorotate: Bool {
        return false
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        // This actually does the right thing on iPad where the modally
        // presented version happily rotates with the iPad orientation.
        return .portrait
    }
}
