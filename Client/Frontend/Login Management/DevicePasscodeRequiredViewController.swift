/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Shared
import SnapKit

// SMA TODO Finalize layout & strings.

class DevicePasscodeRequiredViewController: SettingsViewController {
    private var shownFromAppMenu: Bool = false
    
    private var warningLabel: UILabel = {
        let label = UILabel()
        label.font = DynamicFontHelper().DeviceFontExtraLarge
        label.text = Strings.LoginsDevicePasscodeRequiredMessage
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    private var learnMoreButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(Strings.LoginsDevicePasscodeRequiredLearnMoreButtonTitle, for: .normal)
        button.addTarget(self, action: #selector(learnMoreButtonTapped), for: .touchUpInside)
        button.titleLabel?.font = DynamicFontHelper().DeviceFontExtraLarge
        return button
    }()
    
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
        
        self.view.addSubview(warningLabel)
        warningLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(20)
            make.center.equalToSuperview()
        }
        
        self.view.addSubview(learnMoreButton)
        learnMoreButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(warningLabel.snp.bottom).offset(20)
        }
    }
    
    @objc func doneButtonTapped(_ sender: UIButton) {
        dismiss(animated: true)
    }

    @objc func learnMoreButtonTapped(_ sender: UIButton) {
        let viewController = SettingsContentViewController()
        viewController.url = SupportUtils.URLForTopic("placeholder4")
        navigationController?.pushViewController(viewController, animated: true)
    }
}
