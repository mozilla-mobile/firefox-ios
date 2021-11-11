// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import UIKit
import Shared

class LoginOnboardingViewController: SettingsViewController {
    private var shownFromAppMenu: Bool = false

    private var onboardingMessageLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = .LoginsOnboardingMessage
        label.font = DynamicFontHelper().DeviceFontExtraLarge
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    private var learnMoreButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(.LoginsOnboardingLearnMoreButtonTitle, for: .normal)
        button.addTarget(self, action: #selector(learnMoreButtonTapped), for: .touchUpInside)
        button.titleLabel?.font = DynamicFontHelper().DeviceFontExtraLarge
        return button
    }()
    
    private var continueButton: UIButton = {
        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = UIColor.Photon.Blue50
        button.layer.cornerRadius = 8
        button.setTitle(.LoginsOnboardingContinueButtonTitle, for: .normal)
        button.titleLabel?.font = DynamicFontHelper().MediumSizeBoldFontAS
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 0)
        button.addTarget(self, action: #selector(proceedButtonTapped), for: .touchUpInside)
        return button
    }()
    
    var doneHandler: () -> Void = {}
    var proceedHandler: () -> Void = {}

    init(profile: Profile? = nil, tabManager: TabManager? = nil, shownFromAppMenu: Bool = false) {
        super.init(profile: profile, tabManager: tabManager)
        self.shownFromAppMenu = shownFromAppMenu
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if shownFromAppMenu {
            navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(doneButtonTapped))
        }
        
        self.title = .LoginsAndPasswordsTitle
        
        self.view.addSubviews(onboardingMessageLabel, learnMoreButton, continueButton)
        
        NSLayoutConstraint.activate([
            onboardingMessageLabel.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            onboardingMessageLabel.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            onboardingMessageLabel.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            onboardingMessageLabel.centerYAnchor.constraint(equalTo: self.view.centerYAnchor),
            
            learnMoreButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            learnMoreButton.topAnchor.constraint(equalTo: onboardingMessageLabel.safeAreaLayoutGuide.bottomAnchor, constant: 20),
            
            continueButton.bottomAnchor.constraint(equalTo: self.view.layoutMarginsGuide.bottomAnchor, constant: -20),
            continueButton.heightAnchor.constraint(equalToConstant: 44),
            continueButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            continueButton.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor, constant: 35, priority: .defaultHigh),
            continueButton.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor, constant: -35, priority: .defaultHigh),
            continueButton.widthAnchor.constraint(lessThanOrEqualToConstant: 360)
        ])
    }
    
    @objc func doneButtonTapped(_ sender: UIButton) {
        self.doneHandler()
    }

    @objc func learnMoreButtonTapped(_ sender: UIButton) {
        let viewController = SettingsContentViewController()
        viewController.url = SupportUtils.URLForTopic("placeholder4")
        navigationController?.pushViewController(viewController, animated: true)
    }

    @objc func proceedButtonTapped(_ sender: UIButton) {
        self.proceedHandler()
    }
}
