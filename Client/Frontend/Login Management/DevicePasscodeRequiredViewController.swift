/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Shared
import SnapKit

// SMA TODO Finalize layout & strings.

class DevicePasscodeRequiredViewController: SettingsTableViewController {
    private var shownFromAppMenu: Bool = false
    
    private var label: UILabel!
    private var button: UIButton!
    
    init(shownFromAppMenu: Bool = false) {
        super.init()
        self.shownFromAppMenu = shownFromAppMenu
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if shownFromAppMenu {
            navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done))
        }
        
        self.title = Strings.LoginsAndPasswordsTitle
        
        label = UILabel()
        label.text = "To access your Logins & Passwords, your device must have a passcode set."
        label.textAlignment = .center
        label.numberOfLines = 0
        self.view.addSubview(label)

        button = UIButton(type: .system)
        button.setTitle("Learn More", for: .normal)
        self.view.addSubview(button)
        
        label.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(20)
            make.center.equalToSuperview()
       }
        
        button.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(label.snp.bottom).offset(10)
        }
    }
    
    @objc func done() {
        dismiss(animated: true)
    }
}
