/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Shared
import SnapKit

class LoginOnboardingViewController: SettingsViewController {
    private var shownFromAppMenu: Bool = false

    private var onboardingMessageLabel: UILabel = {
        let label = UILabel()
        label.text = Strings.LoginsOnboardingMessage
        label.font = DynamicFontHelper().DeviceFontExtraLarge
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    private var learnMoreButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(Strings.LoginsOnboardingLearnMoreButtonTitle, for: .normal)
        button.addTarget(self, action: #selector(learnMoreButtonTapped), for: .touchUpInside)
        button.titleLabel?.font = DynamicFontHelper().DeviceFontExtraLarge
        return button
    }()
    
    private var continueButton: UIButton = {
        let button = UIButton(type: .custom)
        button.backgroundColor = UIColor.Photon.Blue50
        button.layer.cornerRadius = 8
        button.setTitle(Strings.LoginsOnboardingContinueButtonTitle, for: .normal)
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
        
        self.title = Strings.LoginsAndPasswordsTitle
        
        self.view.addSubview(onboardingMessageLabel)
        onboardingMessageLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(20)
            make.center.equalToSuperview()
        }
        
        self.view.addSubview(learnMoreButton)
        learnMoreButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(onboardingMessageLabel.snp.bottom).offset(20)
        }

        self.view.addSubview(continueButton)
        continueButton.snp.makeConstraints { make in
            make.bottom.equalTo(self.view.snp.bottomMargin).inset(20)
            make.height.equalTo(44)
            make.centerX.equalToSuperview()
            make.width.equalToSuperview().inset(35).priority(.high)
            make.width.lessThanOrEqualTo(360)
         }
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
