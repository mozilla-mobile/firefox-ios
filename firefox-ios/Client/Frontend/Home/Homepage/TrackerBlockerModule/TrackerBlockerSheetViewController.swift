// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

final class TrackerBlockerSheetViewController: UIViewController, Themeable {
    var currentWindowUUID: WindowUUID? { return windowUUID }
    var themeManager: any ThemeManager
    var themeListenerCancellable: Any?
    var notificationCenter: any NotificationProtocol

    private let windowUUID: WindowUUID

    init(
        windowUUID: WindowUUID,
        themeManager: any ThemeManager = AppContainer.shared.resolve(),
        notificationCenter: any NotificationProtocol = NotificationCenter.default
    ) {
        self.windowUUID = windowUUID
        self.themeManager = themeManager
        self.notificationCenter = notificationCenter
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        listenForThemeChanges(withNotificationCenter: notificationCenter)
        applyTheme()
    }

    func applyTheme() {
        let theme = themeManager.getCurrentTheme(for: windowUUID)
        view.backgroundColor = theme.colors.layerAccentPrivate
    }
}
