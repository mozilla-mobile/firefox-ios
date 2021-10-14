/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Shared
import SnapKit

// SMA TODO Finalize layout & strings.

class DevicePasscodeRequiredViewController: SettingsViewController {
    private var shownFromAppMenu: Bool = false
    
    private var warningTextView: UITextView!
    private var learnMoreButton: UIButton!
    
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
        
        let warningTextView = UITextView()
        warningTextView.font = DynamicFontHelper().DeviceFontExtraLarge
        warningTextView.text = Strings.LoginsDevicePasscodeRequiredMessage
        warningTextView.textAlignment = .center
        warningTextView.clipsToBounds = true
        warningTextView.isScrollEnabled = false
        warningTextView.isUserInteractionEnabled = false
        warningTextView.sizeToFit()
        self.view.addSubview(warningTextView)

        learnMoreButton = UIButton(type: .system)
        learnMoreButton.setTitle(Strings.LoginsDevicePasscodeRequiredLearnMoreButtonTitle, for: .normal)
        learnMoreButton.addTarget(self, action: #selector(learnMoreButtonTapped), for: .touchUpInside)
        learnMoreButton.titleLabel?.font = DynamicFontHelper().DeviceFontExtraLarge
        self.view.addSubview(learnMoreButton)
        
        warningTextView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(20)
            make.center.equalToSuperview()
       }
        
        learnMoreButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(warningTextView.snp.bottom).offset(10)
        }
    }
    
    @objc func doneButtonTapped(_ sender: UIButton) {
        dismiss(animated: true)
    }

    @objc func learnMoreButtonTapped(_ sender: UIButton) {
        let viewController = SettingsContentViewController()
        viewController.url = SupportUtils.URLForTopic("firefox-ios-passcode")
        navigationController?.pushViewController(viewController, animated: true)
    }
}
