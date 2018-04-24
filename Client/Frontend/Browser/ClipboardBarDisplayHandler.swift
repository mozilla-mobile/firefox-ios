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

class ClipboardBarDisplayHandler: NSObject, URLChangeDelegate {
    weak var delegate: (ClipboardBarDisplayHandlerDelegate & SettingsDelegate)?
    weak var settingsDelegate: SettingsDelegate?
    weak var tabManager: TabManager?
    private var sessionStarted = true
    private var sessionRestored = false
    private var firstTabLoaded = false
    private var prefs: Prefs
    private var lastDisplayedURL: String?
    private weak var firstTab: Tab?
    var clipboardToast: ButtonToast?
    
    init(prefs: Prefs, tabManager: TabManager) {
        self.prefs = prefs
        self.tabManager = tabManager

        super.init()

        NotificationCenter.default.addObserver(self, selector: #selector(UIPasteboardChanged), name: .UIPasteboardChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appWillEnterForegroundNotification), name: .UIApplicationWillEnterForeground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didRestoreSession), name: .DidRestoreSession, object: nil)
    }
    
    @objc private func UIPasteboardChanged() {
        // UIPasteboardChanged gets triggered when calling UIPasteboard.general.
         NotificationCenter.default.removeObserver(self, name: .UIPasteboardChanged, object: nil)

        UIPasteboard.general.asyncURL().uponQueue(.main) { res in
            defer {
                NotificationCenter.default.addObserver(self, selector: #selector(self.UIPasteboardChanged), name: .UIPasteboardChanged, object: nil)
            }

            guard let copiedURL: URL? = res.successValue,
                let url = copiedURL else {
                    return
            }
            self.lastDisplayedURL = url.absoluteString
        }
    }

    @objc private func appWillEnterForegroundNotification() {
        sessionStarted = true
        checkIfShouldDisplayBar()
    }

    private func observeURLForFirstTab(firstTab: Tab) {
        if firstTab.webView == nil {
            // Nothing to do; bail out.
            firstTabLoaded = true
            return
        }
        self.firstTab = firstTab
        firstTab.observeURLChanges(delegate: self)
    }

    @objc private func didRestoreSession() {
        DispatchQueue.main.sync {
            if let tabManager = self.tabManager,
                let firstTab = tabManager.selectedTab {
                self.observeURLForFirstTab(firstTab: firstTab)
            } else {
                firstTabLoaded = true
            }

            NotificationCenter.default.removeObserver(self, name: .DidRestoreSession, object: nil)

            sessionRestored = true
            checkIfShouldDisplayBar()
        }
    }

    func tab(_ tab: Tab, urlDidChangeTo url: URL) {
        // Ugly hack to ensure we wait until we're finished restoring the session on the first tab
        // before checking if we should display the clipboard bar.
        guard sessionRestored,
            !url.absoluteString.hasPrefix("\(WebServer.sharedInstance.base)/about/sessionrestore?history=") else {
            return
        }

        tab.removeURLChangeObserver(delegate: self)
        firstTabLoaded = true
        checkIfShouldDisplayBar()
    }

    private func shouldDisplayBar(_ copiedURL: String) -> Bool {
        if !sessionStarted ||
            !sessionRestored ||
            !firstTabLoaded ||
            isClipboardURLAlreadyDisplayed(copiedURL) ||
            self.prefs.intForKey(PrefsKeys.IntroSeen) == nil {
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
