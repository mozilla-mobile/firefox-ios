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

class ClipboardBarDisplayHandler: NSObject {
    weak var delegate: (ClipboardBarDisplayHandlerDelegate & SettingsDelegate)?
    weak var settingsDelegate: SettingsDelegate?
    weak var tabManager: TabManager?
    private var sessionStarted = true
    private var sessionRestored = false
    private var firstTabLoaded = false
    private var prefs: Prefs
    private var lastDisplayedURL: String?
    private var firstTab: Tab?
    var clipboardToast: ButtonToast?
    
    init(prefs: Prefs, tabManager: TabManager) {
        self.prefs = prefs
        self.tabManager = tabManager

        super.init()

        NotificationCenter.default.addObserver(self, selector: #selector(SELUIPasteboardChanged), name: NSNotification.Name.UIPasteboardChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(SELAppWillEnterForegroundNotification), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(SELDidRestoreSession), name: NotificationDidRestoreSession, object: nil)
    }

    deinit {
        if !firstTabLoaded {
            firstTab?.webView?.removeObserver(self, forKeyPath: "URL")
        }
    }
    
    @objc private func SELUIPasteboardChanged() {
        // UIPasteboardChanged gets triggered when callng UIPasteboard.general
         NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIPasteboardChanged, object: nil)

        UIPasteboard.general.asyncURL().uponQueue(.main) { res in
            defer {
                NotificationCenter.default.addObserver(self, selector: #selector(self.SELUIPasteboardChanged), name: NSNotification.Name.UIPasteboardChanged, object: nil)
            }

            guard let copiedURL: URL? = res.successValue,
                let url = copiedURL else {
                    return
            }
            self.lastDisplayedURL = url.absoluteString
        }
    }

    @objc private func SELAppWillEnterForegroundNotification() {
        sessionStarted = true
        checkIfShouldDisplayBar()
    }

    @objc private func SELDidRestoreSession() {
        DispatchQueue.main.sync {
            if let tabManager = self.tabManager,
                let firstTab = tabManager.selectedTab,
                let webView = firstTab.webView {
                self.firstTab = firstTab
                webView.addObserver(self, forKeyPath: "URL", options: .new, context: nil)
            } else {
                firstTabLoaded = true
            }

            NotificationCenter.default.removeObserver(self, name: NotificationDidRestoreSession, object: nil)

            sessionRestored = true
            checkIfShouldDisplayBar()
        }
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        // Ugly hack to ensure we wait until we're finished restoring the session on the first tab
        // before checking if we should display the clipboard bar.
        guard sessionRestored,
            let path = keyPath,
            path == "URL",
            let firstTab = self.firstTab,
            let webView = firstTab.webView,
            let url = firstTab.url?.absoluteString,
            !url.startsWith("\(WebServer.sharedInstance.base)/about/sessionrestore?history=") else {
            return
        }

        webView.removeObserver(self, forKeyPath: "URL")

        firstTabLoaded = true
        checkIfShouldDisplayBar()
    }

    private func shouldDisplayBar(_ copiedURL: String) -> Bool {
        if !sessionStarted ||
            !sessionRestored ||
            !firstTabLoaded ||
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
