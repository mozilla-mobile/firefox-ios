// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import WebKit

// MARK: - TabManagerDelegate
protocol TabManagerDelegate: AnyObject {
    // Must be called on the main thread
    func tabManager(_ tabManager: TabManager, didSelectedTabChange selectedTab: Tab, previousTab: Tab?, isRestoring: Bool)
    func tabManager(_ tabManager: TabManager, didAddTab tab: Tab, placeNextToParentTab: Bool, isRestoring: Bool)
    func tabManager(_ tabManager: TabManager, didRemoveTab tab: Tab, isRestoring: Bool)

    func tabManagerDidRestoreTabs(_ tabManager: TabManager)
    func tabManagerDidAddTabs(_ tabManager: TabManager)
    func tabManagerDidRemoveAllTabs(_ tabManager: TabManager, toast: ButtonToast?)
    func tabManagerUpdateCount()
    func tabManagerTabDidFinishLoading()
}

extension TabManagerDelegate {
    func tabManager(_ tabManager: TabManager, didSelectedTabChange selectedTab: Tab, previousTab: Tab?, isRestoring: Bool) {}
    func tabManager(_ tabManager: TabManager, didAddTab tab: Tab, placeNextToParentTab: Bool, isRestoring: Bool) {}
    func tabManager(_ tabManager: TabManager, didRemoveTab tab: Tab, isRestoring: Bool) {}

    func tabManagerDidRestoreTabs(_ tabManager: TabManager) {}
    func tabManagerDidAddTabs(_ tabManager: TabManager) {}
    func tabManagerDidRemoveAllTabs(_ tabManager: TabManager, toast: ButtonToast?) {}
    func tabManagerUpdateCount() {}
    func tabManagerTabDidFinishLoading() {}
}

// MARK: - WeakTabManagerDelegate
// We can't use a WeakList here because this is a protocol.
class WeakTabManagerDelegate: CustomDebugStringConvertible {
    weak var value: TabManagerDelegate?

    init(value: TabManagerDelegate) {
        self.value = value
    }

    func get() -> TabManagerDelegate? {
        return value
    }

    var debugDescription: String {
        let className = String(describing: type(of: self))
        let memAddr = Unmanaged.passUnretained(self).toOpaque()
        let valueStr = (value == nil ? "<nil>" : "\(value!)")
        return "<\(className): \(memAddr)> Value: \(valueStr)"
    }
}
