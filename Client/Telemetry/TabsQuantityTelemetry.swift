// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

final class TabsQuantityTelemetry {

    var notificationCenter = NotificationCenter.default

    init() {
        setupNotifications(forObserver: self, observing: [UIApplication.didFinishLaunchingNotification])
    }

    deinit {
        notificationCenter.removeObserver(self)
    }

    func trackTabsQuantity(tabManager: TabManager) {
        guard !TabsQuantityTelemetry.quantitySent else { return }

        let privateExtra = [TelemetryWrapper.EventExtraKey.tabsQuantity.rawValue: Int64(tabManager.privateTabs.count)]
        TelemetryWrapper.recordEvent(category: .information,
                                     method: .background,
                                     object: .tabPrivateQuantity,
                                     extras: privateExtra)

        let normalExtra = [TelemetryWrapper.EventExtraKey.tabsQuantity.rawValue: Int64(tabManager.normalTabs.count)]
        TelemetryWrapper.recordEvent(category: .information,
                                     method: .background,
                                     object: .tabNormalQuantity,
                                     extras: normalExtra)

        TabsQuantityTelemetry.quantitySent = true
    }


    // MARK: UserDefaults

    /// Make sure we only send the tabs quantity once per app lifecycle
    static var quantitySent: Bool {
        get { UserDefaults.standard.object(forKey: UserDefaultsKey.tabsQuantitySent.rawValue) as? Bool ?? false }
        set { UserDefaults.standard.set(newValue, forKey: UserDefaultsKey.tabsQuantitySent.rawValue) }
    }

    private enum UserDefaultsKey: String {
        case tabsQuantitySent = "com.moz.tabsQuantitySent.key"
    }
}

// MARK: - Notifiable
extension TabsQuantityTelemetry: Notifiable {
    func handleNotifications(_ notification: Notification) {
        switch notification.name {
        case UIApplication.didFinishLaunchingNotification:
            TabsQuantityTelemetry.quantitySent = false
        default: break
        }
    }
}
