/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

public struct ClipboardBarToastUX {
    static let ToastDelay = DispatchTimeInterval.milliseconds(4000)
}

protocol ClipboardBarDisplayHandlerDelegate: class {
    func shouldDisplay(clipboardBar bar: ButtonToast)
}

class ClipboardBarDisplayHandler {
    weak var delegate: (ClipboardBarDisplayHandlerDelegate & SettingsDelegate)?
    weak var settingsDelegate: SettingsDelegate?
    weak var tabManager: TabManager?
    private var sessionStarted = true
    private var prefs: Prefs
    private var lastDisplayedURL: String?
    var clipboardToast: ButtonToast?
    
    init(prefs: Prefs, tabManager: TabManager) {
        self.prefs = prefs
        self.tabManager = tabManager
        NotificationCenter.default.addObserver(self, selector: #selector(self.SELAppWillEnterForegroundNotification), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.SELAppWillResignActive), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
    }
    
    @objc private func SELAppWillEnterForegroundNotification() {
        sessionStarted = true
        checkIfShouldDisplayBar()
    }
    
    @objc private func SELAppWillResignActive() {
        sessionStarted = true
        UIPasteboard.general.asyncString().uponQueue(.main) { res in
            if let value = res.successValue {
                self.lastDisplayedURL = value
            }
        }
    }
    
    private func shouldDisplayBar(_ copiedURL: String) -> Bool {
        if !sessionStarted ||
            isClipboardURLAlreadyDisplayed(copiedURL) ||
            self.prefs.intForKey(IntroViewControllerSeenProfileKey) == nil {
            return false
        }
        sessionStarted = false
        return true
    }
    
    // If we already displayed this URL on the previous session, or in an already open
    // tab, we shouldn't display it again
    private func isClipboardURLAlreadyDisplayed(_ clipboardURL: String) -> Bool {
        if lastDisplayedURL == clipboardURL {
            return true
        }

        if let url = URL(string: clipboardURL),
            let _ = tabManager?.getTabFor(url) {
            return true
        }
        return false
    }
    
    func checkIfShouldDisplayBar() {
        guard self.prefs.boolForKey("showClipboardBar") ?? false else {
            // There's no point in doing any of this work unless the
            // user has asked for it in settings.
            return
        }
        UIPasteboard.general.asyncURL().uponQueue(.main) { res in
            guard let copiedURL: URL? = res.successValue,
                let url = copiedURL else {
                return
            }

            let absoluteString = url.absoluteString

            guard self.shouldDisplayBar(absoluteString) else {
                return
            }

            self.lastDisplayedURL = absoluteString

            self.clipboardToast =
                ButtonToast(
                    labelText: Strings.GoToCopiedLink,
                    descriptionText: url.absoluteDisplayString,
                    buttonText: Strings.GoButtonTittle,
                    completion: { buttonPressed in
                        if buttonPressed {
                            self.delegate?.settingsOpenURLInNewTab(url)
                        }
            })

            if let toast = self.clipboardToast {
                self.delegate?.shouldDisplay(clipboardBar: toast)
            }
        }
    }
}
