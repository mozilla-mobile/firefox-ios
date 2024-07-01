// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import Common

protocol ClipboardBarDisplayHandlerDelegate: AnyObject {
    func shouldDisplay(clipBoardURL url: URL)

    @available(iOS 16.0, *)
    func shouldDisplay()
}

class ClipboardBarDisplayHandler: NSObject {
    public struct UX {
        static let toastDelay = DispatchTimeInterval.milliseconds(10000)
    }

    weak var delegate: ClipboardBarDisplayHandlerDelegate?
    weak var settingsDelegate: SettingsDelegate?
    weak var tabManager: TabManager?
    private var prefs: Prefs
    private var lastDisplayedURL: String?
    private var lastPasteBoardChangeCount: Int?
    private weak var firstTab: Tab?
    var clipboardToast: ButtonToast?
    private let windowUUID: WindowUUID

    init(prefs: Prefs, tabManager: TabManager) {
        self.prefs = prefs
        self.tabManager = tabManager
        self.windowUUID = tabManager.windowUUID

        super.init()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(UIPasteboardChanged),
            name: UIPasteboard.changedNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForegroundNotification),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }

    @objc
    private func UIPasteboardChanged() {
        // UIPasteboardChanged gets triggered when calling UIPasteboard.general.
        NotificationCenter.default.removeObserver(self, name: UIPasteboard.changedNotification, object: nil)

        UIPasteboard.general.asyncURL { url in
            ensureMainThread {
                defer {
                    NotificationCenter.default.addObserver(
                        self,
                        selector: #selector(self.UIPasteboardChanged),
                        name: UIPasteboard.changedNotification,
                        object: nil
                    )
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
        checkIfShouldDisplayBar()
    }

    private func shouldDisplayBar(_ copiedURL: String) -> Bool {
        if isClipboardURLAlreadyDisplayed(copiedURL) ||
            IntroScreenManager(prefs: prefs).shouldShowIntroScreen {
            return false
        }
        return true
    }

    private func shouldDisplayBar(_ pasteBoardChangeCount: Int) -> Bool {
        if pasteBoardChangeCount == lastPasteBoardChangeCount ||
            IntroScreenManager(prefs: prefs).shouldShowIntroScreen {
            return false
        }
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
        guard
            prefs.boolForKey("showClipboardBar") ?? false,
            UIPasteboard.general.hasURLs
        else { return }

        if #available(iOS 16.0, *) {
            let pasteBoardChangeCount = UIPasteboard.general.changeCount
            guard shouldDisplayBar(pasteBoardChangeCount) else { return }

            lastPasteBoardChangeCount = pasteBoardChangeCount

            AppEventQueue.wait(for: [.startupFlowComplete, .tabRestoration(windowUUID)]) { [weak self] in
                self?.delegate?.shouldDisplay()
            }
        } else {
            guard
                let url = UIPasteboard.general.url,
                shouldDisplayBar(url.absoluteString)
            else { return }

            lastDisplayedURL = url.absoluteString

            AppEventQueue.wait(for: [.startupFlowComplete, .tabRestoration(windowUUID)]) { [weak self] in
                self?.delegate?.shouldDisplay(clipBoardURL: url)
            }
        }
    }
}
