// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Shared
import Common

class SettingsViewController: UIViewController, Themeable {
    var themeManager: ThemeManager
    var themeObserver: NSObjectProtocol?
    var notificationCenter: NotificationProtocol

    weak var settingsDelegate: SettingsDelegate?

    var profile: Profile!
    var tabManager: TabManager!
    let windowUUID: WindowUUID

    var currentWindowUUID: UUID? { return windowUUID }

    init(windowUUID: WindowUUID,
         profile: Profile? = nil,
         tabManager: TabManager? = nil,
         themeManager: ThemeManager = AppContainer.shared.resolve(),
         notificationCenter: NotificationCenter = NotificationCenter.default) {
        self.themeManager = themeManager
        self.notificationCenter = notificationCenter
        self.windowUUID = windowUUID
        super.init(nibName: nil, bundle: nil)
        self.profile = profile
        self.tabManager = tabManager
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        listenForThemeChange(view)
        applyTheme()
    }

    func applyTheme() {
        let theme = themeManager.getCurrentTheme(for: currentWindowUUID)
        view.backgroundColor = theme.colors.layer1
    }
}
