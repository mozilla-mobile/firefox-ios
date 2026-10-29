// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

final class GoogleLensInterstitialViewController: UIViewController, Themeable {
    private let interstitialView: GoogleLensInterstitialView = .build()
    private var hasStartedEntrance = false
    private var isExiting = false

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

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(interstitialView)
        interstitialView.pinToSuperview()
        listenForThemeChanges(withNotificationCenter: NotificationCenter.default)
        applyTheme()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !hasStartedEntrance, !isExiting else { return }
        hasStartedEntrance = true
        interstitialView.animateEntrance()
    }

    func animateExit(completion: @escaping () -> Void) {
        guard !isExiting else { return }
        isExiting = true
        interstitialView.animateExit(completion: completion)
    }

    func stopAnimation() {
        isExiting = true
        interstitialView.stopAnimation()
    }

    func applyTheme() {
        let theme = themeManager.getCurrentTheme(for: windowUUID)
        interstitialView.applyTheme(theme: theme)
    }
}
