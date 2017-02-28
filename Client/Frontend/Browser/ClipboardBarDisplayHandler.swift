/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

public struct ClipboardBarToastUX {
    static let ToastDelay = 4.0
}

protocol ClipboardBarDisplayHandlerDelegate: class {
    func shouldDisplay(clipboardBar bar: ButtonToast)
}

class ClipboardBarDisplayHandler {
    weak var delegate: (ClipboardBarDisplayHandlerDelegate & SettingsDelegate)?
    weak var settingsDelegate: SettingsDelegate?
    private var sessionStarted = true
    private var prefs: Prefs
    private var lastDisplayedURL: String?
    var clipboardToast: ButtonToast?
    
    init(prefs: Prefs) {
        self.prefs = prefs
        NotificationCenter.default.addObserver(self, selector: #selector(self.SELAppWillEnterForegroundNotification), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
    }
    
    @objc private func SELAppWillEnterForegroundNotification() {
        sessionStarted = true
        checkIfShouldDisplayBar()
    }
    
    private func shouldDisplayBar() -> Bool {
        if !sessionStarted ||
            UIPasteboard.general.copiedURL == nil ||
            wasClipboardURLAlreadyDisplayed() ||
            self.prefs.intForKey(IntroViewControllerSeenProfileKey) == nil {
            return false
        }
        sessionStarted = false
        lastDisplayedURL = UIPasteboard.general.copiedURL?.absoluteString
        return true
    }
    
    //If we already displayed this URL on the previous session
    //We shouldn't display it again
    private func wasClipboardURLAlreadyDisplayed() -> Bool {
        guard let clipboardURL = UIPasteboard.general.copiedURL?.absoluteString ,
            let savedURL = lastDisplayedURL else {
                return false
        }
        if clipboardURL == savedURL {
            return true
        }
        return false
    }
    
    func checkIfShouldDisplayBar() {
        guard let absoluteString = UIPasteboard.general.copiedURL?.absoluteString, shouldDisplayBar() else { return }
        
        clipboardToast = ButtonToast(labelText: Strings.GoToCopiedLink, descriptionText: absoluteString, buttonText: Strings.GoButtonTittle, completion: { buttonPressed in

            guard let url = URL(string: absoluteString), buttonPressed else { return }
            self.delegate?.settingsOpenURLInNewTab(url)
        })
        
        if let toast = clipboardToast {
            delegate?.shouldDisplay(clipboardBar: toast)
        }
    }
}
