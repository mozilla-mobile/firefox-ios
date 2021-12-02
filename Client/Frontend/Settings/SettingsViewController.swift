// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import UIKit

class SettingsViewController: UIViewController {
    weak var settingsDelegate: SettingsDelegate? = nil
    
    var profile: Profile!
    var tabManager: TabManager!
    
    let theme = LegacyThemeManager.instance

    init(profile: Profile? = nil, tabManager: TabManager? = nil) {
        super.init(nibName: nil, bundle: nil)
        self.profile = profile
        self.tabManager = tabManager
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        updateTheme()
        NotificationCenter.default.addObserver(self, selector: #selector(updateTheme), name: .DisplayThemeChanged, object: nil)
    }
    
    @objc func updateTheme() {
        view.backgroundColor = theme.current.tableView.headerBackground
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
