/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

class BrowserViewController: UIViewController {
    override func viewDidLoad() {
        view.backgroundColor = UIConstants.Colors.Background

        let settingsButton = UIButton()
        settingsButton.addTarget(self, action: #selector(settingsClicked), for: .touchUpInside)
        settingsButton.setTitle(UIConstants.Strings.LabelOpenSettings, for: .normal)
        view.addSubview(settingsButton)
        settingsButton.snp.makeConstraints { make in
            make.center.equalTo(self.view)
        }
    }

    func settingsClicked() {
        let settingsViewController = SettingsViewController()
        present(settingsViewController, animated: true, completion: nil)
    }
}
