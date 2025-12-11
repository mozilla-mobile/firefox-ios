// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import Common

@MainActor
protocol ClipboardBarDisplayHandler {
    var clipboardToast: ButtonToast? { get set }
    func checkIfShouldDisplayBar()
}

protocol ClipboardBarDisplayHandlerDelegate: AnyObject {
    @MainActor
    @available(iOS 16.0, *)
    func shouldDisplay()
}

@MainActor
@available(iOS 16.0, *)
final class DefaultClipboardBarDisplayHandler: ClipboardBarDisplayHandler, Notifiable {
    struct UX {
        static let toastDelay = DispatchTimeInterval.milliseconds(10000)
    }

    weak var delegate: ClipboardBarDisplayHandlerDelegate?
    private var prefs: Prefs
    private var lastPasteBoardChangeCount: Int?
    private weak var firstTab: Tab?
    var clipboardToast: ButtonToast?
    private let windowUUID: WindowUUID

    init(prefs: Prefs, windowUUID: WindowUUID) {
        self.prefs = prefs
        self.windowUUID = windowUUID

        startObservingNotifications(
            withNotificationCenter: NotificationCenter.default,
            forObserver: self,
            observing: [
                UIApplication.willEnterForegroundNotification
            ]
        )
    }

    private func appWillEnterForegroundNotification() {
        checkIfShouldDisplayBar()
    }

    private func shouldDisplayBar(_ pasteBoardChangeCount: Int) -> Bool {
        if pasteBoardChangeCount == lastPasteBoardChangeCount ||
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

        let pasteBoardChangeCount = UIPasteboard.general.changeCount
        guard shouldDisplayBar(pasteBoardChangeCount) else { return }

        lastPasteBoardChangeCount = pasteBoardChangeCount

        AppEventQueue.wait(for: [.startupFlowComplete, .tabRestoration(windowUUID)]) {
            Task { @MainActor [weak self] in
                self?.delegate?.shouldDisplay()
            }
        }
    }

    // MARK: - Notifiable

    public func handleNotifications(_ notification: Notification) {
        switch notification.name {
        case UIApplication.willEnterForegroundNotification:
            ensureMainThread {
                self.appWillEnterForegroundNotification
            }
        default:
            return
        }
    }
}
