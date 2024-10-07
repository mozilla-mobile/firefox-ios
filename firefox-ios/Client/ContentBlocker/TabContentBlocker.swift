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
    func currentURL() -> URL?
    func currentWebView() -> WKWebView?
    func imageContentBlockingEnabled() -> Bool
}

class TabContentBlocker {
    weak var tab: ContentBlockerTab?
    let logger: Logger
    var isEnabled: Bool {
        return false
    }

    @objc
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
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(notifiedTabSetupRequired),
            name: .contentBlockerTabSetupRequired,
            object: nil
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
}
