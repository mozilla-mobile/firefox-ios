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
        static let primaryButtonColour = UIColor.Photon.Blue50
        static let primaryButtonCornerRadius: CGFloat = 10
        static let primaryButtonFont = UIFont.systemFont(ofSize: 18, weight: .semibold)
        static let primaryButtonHeight: CGFloat = 46
        static let primaryButtonEdgeInset: CGFloat = 18
    }

    // Public constants
    let viewModel = ETPViewModel()
    static let theme = BuiltinThemeName(rawValue: LegacyThemeManager.instance.current.name) ?? .normal

    // Private vars
    private var fxTextThemeColour: UIColor {
        // For dark theme we want to show light colours and for light we want to show dark colours
        return ETPCoverSheetViewController.theme == .dark ? .white : .black
    }

    private var fxBackgroundThemeColour: UIColor {
        return ETPCoverSheetViewController.theme == .dark ? .black : .white
    }

    private lazy var doneButton: UIButton = .build { button in
        button.setTitle(.SettingsSearchDoneButton, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .regular)
        button.setTitleColor(UIColor.systemBlue, for: .normal)
        button.addTarget(self, action: #selector(self.dismissAnimated), for: .touchUpInside)
    }

    let pairImageView: UIImageView = .build { imageView in
        imageView.image = UIImage(named: ImageIdentifiers.signinSync)
        imageView.contentMode = .scaleAspectFit
    }

    private lazy var topImageView: UIImageView = .build { imageView in
        imageView.image = self.viewModel.etpCoverSheetmodel?.titleImage
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
    }

    private lazy var titleLabel: UILabel = .build { label in
        label.text = self.viewModel.etpCoverSheetmodel?.titleText
        label.textColor = self.fxTextThemeColour
        label.font = UIFont.boldSystemFont(ofSize: 18)
        label.textAlignment = .left
        label.numberOfLines = 0
    }

    private lazy var descriptionLabel: UILabel = .build { label in
        label.text = self.viewModel.etpCoverSheetmodel?.descriptionText
        label.textColor = self.fxTextThemeColour
        label.font = UIFont.systemFont(ofSize: 18)
        label.textAlignment = .left
        label.numberOfLines = 0
    }

    private lazy var goToSettingsButton: UIButton = .build { button in
        button.setTitle(.CoverSheetETPSettingsButton, for: .normal)
        button.titleLabel?.font = UX.primaryButtonFont
        button.layer.cornerRadius = UX.primaryButtonCornerRadius
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UX.primaryButtonColour
        button.addTarget(self, action: #selector(self.goToSettings), for: .touchUpInside)
    }

    private lazy var startBrowsingButton: UIButton = .build { button in
        button.setTitle(.StartBrowsingButtonTitle, for: .normal)
        button.titleLabel?.font = UX.primaryButtonFont
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
        view.backgroundColor = fxBackgroundThemeColour

        setupLayout()
    }

    private func setupLayout() {
        view.backgroundColor = fxBackgroundThemeColour

        // Initialize
        view.addSubview(topImageView)
        view.addSubview(doneButton)
        view.addSubview(titleLabel)
        view.addSubview(descriptionLabel)
        view.addSubview(goToSettingsButton)
        view.addSubview(startBrowsingButton)

        // Constraints
        NSLayoutConstraint.activate([
            doneButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor,
                                             constant: UX.doneButtonPadding),
            doneButton.trailingAnchor.constraint(equalTo: view.trailingAnchor,
                                                  constant: -UX.doneButtonPadding),
            doneButton.heightAnchor.constraint(equalToConstant: UX.doneButtonPadding),

            topImageView.topAnchor.constraint(equalTo: doneButton.bottomAnchor, constant: 10),
            topImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            topImageView.bottomAnchor.constraint(equalTo: titleLabel.topAnchor, constant: -48),
            topImageView.heightAnchor.constraint(lessThanOrEqualToConstant: 300),

            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            titleLabel.bottomAnchor.constraint(equalTo: descriptionLabel.topAnchor,
                                               constant: -16),

            descriptionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor,
                                                      constant: 16),
            descriptionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor,
                                                       constant: -16),
            descriptionLabel.bottomAnchor.constraint(equalTo: goToSettingsButton.topAnchor,
                                                     constant: -48),

            goToSettingsButton.leadingAnchor.constraint(equalTo: view.leadingAnchor,
                                                      constant: UX.primaryButtonEdgeInset),
            goToSettingsButton.trailingAnchor.constraint(equalTo: view.trailingAnchor,
                                                       constant: -UX.primaryButtonEdgeInset),
            goToSettingsButton.bottomAnchor.constraint(equalTo: startBrowsingButton.topAnchor,
                                                     constant: -16),
            goToSettingsButton.heightAnchor.constraint(equalToConstant: UX.primaryButtonHeight),

            startBrowsingButton.leadingAnchor.constraint(equalTo: view.leadingAnchor,
                                                      constant: UX.primaryButtonEdgeInset),
            startBrowsingButton.trailingAnchor.constraint(equalTo: view.trailingAnchor,
                                                       constant: -UX.primaryButtonEdgeInset),
            startBrowsingButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor,
                                                     constant: -16),
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
