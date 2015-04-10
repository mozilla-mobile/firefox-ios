/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit

protocol TabManagerDelegate: class {
    func tabManager(tabManager: TabManager, didSelectedTabChange selected: Browser?, previous: Browser?)
    func tabManager(tabManager: TabManager, didCreateTab tab: Browser)
    func tabManager(tabManager: TabManager, didAddTab tab: Browser)
    func tabManager(tabManager: TabManager, didRemoveTab tab: Browser)
}

struct WeakTabManagerDelegate {
    var value : TabManagerDelegate?

    init (value: TabManagerDelegate) {
        self.value = value
    }

    func get() -> TabManagerDelegate? {
        return value
    }
}

class TabManager {
    private var delegates = [WeakTabManagerDelegate]()

    func addDelegate(delegate: TabManagerDelegate) {
        println("Append \(delegate)")
        delegates.append(WeakTabManagerDelegate(value: delegate))
    }

    func removeDelegate(delegate: TabManagerDelegate) {
        println("Delegates \(delegates)")
        for var i = 0; i < delegates.count; i++ {
            var del = delegates[i]
            if delegate === del.get() {
                delegates.removeAtIndex(i)
                return
            }
        }
    }

    private var tabs: [Browser] = []
    private var _selectedIndex = -1
    var selectedIndex: Int { return _selectedIndex }
    private let defaultNewTabRequest: NSURLRequest

    init(defaultNewTabRequest: NSURLRequest) {
        self.defaultNewTabRequest = defaultNewTabRequest
    }

    var count: Int {
        return tabs.count
    }

    var selectedTab: Browser? {
        if !(0..<count ~= _selectedIndex) {
            return nil
        }

        return tabs[_selectedIndex]
    }

    func getTab(index: Int) -> Browser {
        return tabs[index]
    }

    func getTab(webView: WKWebView) -> Browser? {
        for tab in tabs {
            if tab.webView === webView {
                return tab
            }
        }

        return nil
    }

    func selectTab(tab: Browser?) {
        if selectedTab === tab {
            return
        }

        let previous = selectedTab

        _selectedIndex = -1
        for i in 0..<count {
            if tabs[i] === tab {
                _selectedIndex = i
                break
            }
        }

        assert(tab === selectedTab, "Expected tab is selected")

        for var i = 0; i < delegates.count; i++ {
            var delegate = delegates[i]
            delegate.get()?.tabManager(self, didSelectedTabChange: tab, previous: previous)
        }
    }

    func addTab(var request: NSURLRequest! = nil, configuration: WKWebViewConfiguration = WKWebViewConfiguration()) -> Browser {
        if request == nil {
            request = defaultNewTabRequest
        }

        let tab = Browser(configuration: configuration)
        for var i = 0; i < delegates.count; i++ {
            var delegate = delegates[i]
            delegate.get()?.tabManager(self, didCreateTab: tab)
        }
        tabs.append(tab)
        for var i = 0; i < delegates.count; i++ {
            var delegate = delegates[i]
            delegate.get()?.tabManager(self, didAddTab: tab)
        }
        tab.loadRequest(request)
        selectTab(tab)
        return tab
    }

    func removeTab(tab: Browser) {
        // If the removed tab was selected, find the new tab to select.
        if tab === selectedTab {
            let index = getIndex(tab)
            if index + 1 < count {
                selectTab(tabs[index + 1])
            } else if index - 1 >= 0 {
                selectTab(tabs[index - 1])
            } else {
                assert(count == 1, "Removing last tab")
                selectTab(nil)
            }
        }

        let prevCount = count
        var index = -1
        for i in 0..<count {
            if tabs[i] === tab {
                tabs.removeAtIndex(i)
                index = i
                break
            }
        }
        assert(count == prevCount - 1, "Tab removed")

        for var i = 0; i < delegates.count; i++ {
            var delegate = delegates[i]
            delegate.get()?.tabManager(self, didRemoveTab: tab)
        }
    }

    func removeAll() {
        let tabs = self.tabs
        for tab in tabs {
            removeTab(tab)
        }
    }

    func getIndex(tab: Browser) -> Int {
        for i in 0..<count {
            if tabs[i] === tab {
                return i
            }
        }
        
        assertionFailure("Tab not in tabs list")
        return -1
    }
}