// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import WebKit
import Common

extension Notification.Name {
   public static let didChangeContentBlocking = Notification.Name("didChangeContentBlocking")
   public static let contentBlockerTabSetupRequired = Notification.Name("contentBlockerTabSetupRequired")
}

protocol ContentBlockerTab: AnyObject {
    @MainActor
    func currentURL() -> URL?
    @MainActor
    func currentWebView() -> WKWebView?
    @MainActor
    func imageContentBlockingEnabled() -> Bool
}

@MainActor
class TabContentBlocker: Notifiable {
    weak var tab: ContentBlockerTab?
    let logger: Logger

    var isEnabled: Bool {
        return false
    }

    func notifiedTabSetupRequired() {}

    func currentlyEnabledLists() -> [String] {
        return []
    }

    func notifyContentBlockingChanged() {}

    var status: BlockerStatus {
        guard isEnabled else {
            return .disabled
        }
        guard let url = tab?.currentURL() else {
            return .noBlockedURLs
        }

        if ContentBlocker.shared.isSafelisted(url: url) {
            return .safelisted
        }
        if stats.total == 0 {
            return .noBlockedURLs
        } else {
            return .blocking
        }
    }

    var stats = TPPageStats()

    init(tab: ContentBlockerTab, logger: Logger = DefaultLogger.shared) {
        self.tab = tab
        self.logger = logger
        startObservingNotifications(
            withNotificationCenter: NotificationCenter.default,
            forObserver: self,
            observing: [
                .contentBlockerTabSetupRequired
            ]
        )
    }

    func scriptMessageHandlerNames() -> [String]? {
        return ["trackingProtectionStats"]
    }

    class func prefsChanged() {
        // This class func needs to notify all the active instances of ContentBlocker to update.
        NotificationCenter.default.post(name: .contentBlockerTabSetupRequired, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Notifiable

    public func handleNotifications(_ notification: Notification) {
        switch notification.name {
        case .contentBlockerTabSetupRequired:
            ensureMainThread {
                self.notifiedTabSetupRequired
            }
        default:
            return
        }
    }
}
