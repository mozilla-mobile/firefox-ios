/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Shared
import SnapKit

class LoginOnboardingViewController: SettingsViewController {
    private var shownFromAppMenu: Bool = false

    private var label: UILabel!
    private var button: UIButton!
    
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
            navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneButtonTapped))
        }
        
        self.title = Strings.LoginsAndPasswordsTitle
        
        label = UILabel()
        label.text = "We have changed things. No more Firefox passcode, we now use your device FaceID, TouchID or Passcode." // TODO SMA
        label.textAlignment = .center
        label.numberOfLines = 0
        self.view.addSubview(label)

        button = UIButton(type: .custom)
        button.backgroundColor = UIColor.Photon.Blue50
        button.layer.cornerRadius = 8
        button.setTitle("Continue", for: .normal) // TODO SMA String
        button.titleLabel?.font = DynamicFontHelper().MediumSizeBoldFontAS
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 0)
        button.addTarget(self, action: #selector(proceedButtonTapped), for: .touchUpInside)
        self.view.addSubview(button)
        
        label.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(20)
            make.center.equalToSuperview()
        }

        button.snp.makeConstraints { make in
            make.top.equalTo(label.snp_bottomMargin).offset(30)
            make.height.equalTo(44)
            make.left.equalToSuperview().inset(20)
            make.right.equalToSuperview().inset(20)
         }
    }
    
    @objc func doneButtonTapped(_ sender: UIButton) {
        self.doneHandler()
    }
    
    @objc func proceedButtonTapped(_ sender: UIButton) {
        self.proceedHandler()
    }
}
