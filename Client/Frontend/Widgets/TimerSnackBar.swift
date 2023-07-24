// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation

/**
 * A special version of a snackbar that persists for at least a timeout. After that
 * it will dismiss itself on the next page load where this tab isn't showing. As long as
 * you stay on the current tab though, it will persist until you interact with it.
 */
class TimerSnackBar: SnackBar {
    fileprivate var timer: Timer?
    fileprivate var timeout: TimeInterval

    init(timeout: TimeInterval = 10, text: String, img: UIImage?) {
        self.timeout = timeout
        super.init(text: text, img: img)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    static func showAppStoreConfirmationBar(forTab tab: Tab, appStoreURL: URL, completion: @escaping (Bool) -> Void) {
        let bar = TimerSnackBar(
            text: .ExternalLinkAppStoreConfirmationTitle,
            img: UIImage(named: StandardImageIdentifiers.Large.globe)?.withRenderingMode(.alwaysOriginal))
        let openAppStore = SnackButton(title: .AppStoreString, accessibilityIdentifier: "ConfirmOpenInAppStore", bold: true) { bar in
            tab.removeSnackbar(bar)
            UIApplication.shared.open(appStoreURL, options: [:])
            completion(true)
        }
        let cancelButton = SnackButton(title: .NotNowString, accessibilityIdentifier: "CancelOpenInAppStore", bold: false) { bar in
            tab.removeSnackbar(bar)
            completion(false)
        }
        bar.addButton(cancelButton)
        bar.addButton(openAppStore)
        tab.addSnackbar(bar)
    }

    override func show() {
        self.timer = Timer(timeInterval: timeout, target: self, selector: #selector(timerDone), userInfo: nil, repeats: false)
        RunLoop.current.add(self.timer!, forMode: RunLoop.Mode.default)
        super.show()
    }

    @objc
    func timerDone() {
        self.timer = nil
    }

    override func shouldPersist(_ tab: Tab) -> Bool {
        if !showing {
            return timer != nil
        }
        return super.shouldPersist(tab)
    }
}
