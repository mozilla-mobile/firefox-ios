// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import Common

// TODO: FXIOS-12907 This legacy ClipboardBar code can be removed once iOS 15 is dropped
protocol LegacyClipboardBarDisplayHandlerDelegate: AnyObject {
    @MainActor
    func shouldDisplay(clipBoardURL url: URL)
}

final class LegacyClipboardBarDisplayHandler: ClipboardBarDisplayHandler {
    struct UX {
        static let toastDelay = DispatchTimeInterval.milliseconds(10000)
    }

    weak var delegate: LegacyClipboardBarDisplayHandlerDelegate?
    weak var tabManager: TabManager?

    private var lastDisplayedURL: String?
    private var prefs: Prefs
    private let windowUUID: WindowUUID
    var clipboardToast: ButtonToast?

    init(prefs: Prefs, tabManager: TabManager) {
        self.prefs = prefs
        self.tabManager = tabManager
        self.windowUUID = tabManager.windowUUID

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForegroundNotification),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(UIPasteboardChanged),
            name: UIPasteboard.changedNotification,
            object: nil
        )
    }

    @objc
    private func appWillEnterForegroundNotification() {
        checkIfShouldDisplayBar()
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

                MainActor.assumeIsolated {
                    self.lastDisplayedURL = url.absoluteString
                }
            }
        }
    }

    // If we already displayed this URL on the previous session, or in an already open
    // tab, we shouldn't display it again
    private func isClipboardURLAlreadyDisplayed(_ clipboardURL: String) -> Bool {
        if lastDisplayedURL == clipboardURL {
            return true
        }

        if let url = URL(string: clipboardURL),
           tabManager?.getTabForURL(url) != nil {
            return true
        }

        return false
    }

    private func shouldDisplayBar(_ copiedURL: String) -> Bool {
        if isClipboardURLAlreadyDisplayed(copiedURL) ||
            IntroScreenManager(prefs: prefs).shouldShowIntroScreen {
            return false
        }
        return true
    }

    func checkIfShouldDisplayBar() {
        // Clipboard bar feature needs to be enabled by users to be activated in the user settings
        guard prefs.boolForKey(PrefsKeys.ShowClipboardBar) ?? false,
              UIPasteboard.general.hasURLs
        else { return }

        guard let url = UIPasteboard.general.url,
              shouldDisplayBar(url.absoluteString)
        else { return }

        lastDisplayedURL = url.absoluteString

        AppEventQueue.wait(for: [.startupFlowComplete, .tabRestoration(windowUUID)]) { [weak self] in
            ensureMainThread { [weak self] in
                self?.delegate?.shouldDisplay(clipBoardURL: url)
            }
        }
    }
}
