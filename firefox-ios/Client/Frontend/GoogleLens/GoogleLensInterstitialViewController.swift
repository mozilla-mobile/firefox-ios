// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

final class GoogleLensInterstitialViewController: UIViewController, Themeable {
    let themeManager: ThemeManager
    var themeListenerCancellable: Any?
    var currentWindowUUID: UUID? { windowUUID }

    private let windowUUID: WindowUUID

    init(windowUUID: WindowUUID, themeManager: ThemeManager) {
        self.windowUUID = windowUUID
        self.themeManager = themeManager
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        isModalInPresentation = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = GoogleLensInterstitialView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        listenForThemeChanges(withNotificationCenter: NotificationCenter.default)
        applyTheme()
    }

    func applyTheme() {
        let theme = themeManager.getCurrentTheme(for: windowUUID)
        (viewIfLoaded as? GoogleLensInterstitialView)?.applyTheme(theme: theme)
    }
}
