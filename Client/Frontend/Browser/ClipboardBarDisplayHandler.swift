// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

protocol ClipboardBarDisplayHandlerDelegate: AnyObject {
    func shouldDisplay(clipBoardURL url: URL)
}

class ClipboardBarDisplayHandler: NSObject, URLChangeDelegate {
    public struct UX {
        static let toastDelay = DispatchTimeInterval.milliseconds(10000)
    }

    weak var delegate: ClipboardBarDisplayHandlerDelegate?
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

        NotificationCenter.default.addObserver(self, selector: #selector(UIPasteboardChanged), name: UIPasteboard.changedNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appWillEnterForegroundNotification), name: UIApplication.willEnterForegroundNotification, object: nil)
    }

    @objc
    private func UIPasteboardChanged() {
        // UIPasteboardChanged gets triggered when calling UIPasteboard.general.
        NotificationCenter.default.removeObserver(self, name: UIPasteboard.changedNotification, object: nil)

        UIPasteboard.general.asyncURL { url in
            ensureMainThread {
                defer {
                    NotificationCenter.default.addObserver(self, selector: #selector(self.UIPasteboardChanged), name: UIPasteboard.changedNotification, object: nil)
                }

                guard let url = url else {
                    return
                }
                self.lastDisplayedURL = url.absoluteString
            }
        }
    }

    @objc
    private func appWillEnterForegroundNotification() {
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

    func didRestoreSession() {
        guard !sessionRestored else { return }
        if let tabManager = self.tabManager,
            let firstTab = tabManager.selectedTab {
            observeURLForFirstTab(firstTab: firstTab)
        } else {
            firstTabLoaded = true
        }

        sessionRestored = true
        checkIfShouldDisplayBar()
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
            IntroScreenManager(prefs: prefs).shouldShowIntroScreen {
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

        if let url = URL(string: clipboardURL, invalidCharacters: false),
           tabManager?.getTabFor(url) != nil {
            return true
        }

        return false
    }

    func checkIfShouldDisplayBar() {
        // Clipboard bar feature needs to be enabled by users to be activated in the user settings
        guard prefs.boolForKey("showClipboardBar") ?? false else { return }

        guard UIPasteboard.general.hasURLs,
              let url = UIPasteboard.general.url,
              shouldDisplayBar(url.absoluteString) else { return }

        lastDisplayedURL = url.absoluteString
        delegate?.shouldDisplay(clipBoardURL: url)
    }
}
