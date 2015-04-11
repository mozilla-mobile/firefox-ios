/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Storage
import WebKit

protocol TabManagerDelegate: class {
    func tabManager(tabManager: TabManager, didSelectedTabChange selected: Browser?, previous: Browser?)
    func tabManager(tabManager: TabManager, didCreateTab tab: Browser)
    func tabManager(tabManager: TabManager, didAddTab tab: Browser)
    func tabManager(tabManager: TabManager, didRemoveTab tab: Browser)
}

class TabManager {
    weak var delegate: TabManagerDelegate? = nil

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

    var openTabs: OpenTabs? {
        didSet {
            didInitOpenTabs(openTabs)
        }
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

        delegate?.tabManager(self, didSelectedTabChange: tab, previous: previous)
    }

    func addTab(var request: NSURLRequest! = nil, configuration: WKWebViewConfiguration = WKWebViewConfiguration()) -> Browser {
        if request == nil {
            request = defaultNewTabRequest
        }

        let tab = Browser(configuration: configuration)
        delegate?.tabManager(self, didCreateTab: tab)
        tabs.append(tab)
        delegate?.tabManager(self, didAddTab: tab)
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
        for i in 0..<count {
            if tabs[i] === tab {
                tabs.removeAtIndex(i)
                break
            }
        }
        assert(count == prevCount - 1, "Tab removed")

        delegate?.tabManager(self, didRemoveTab: tab)
    }

    private func getIndex(tab: Browser) -> Int {
        for i in 0..<count {
            if tabs[i] === tab {
                return i
            }
        }
        
        assertionFailure("Tab not in tabs list")
        return -1
    }
    
    private func didInitOpenTabs(openTabs: OpenTabs?) -> Void {
        // XXX This is to limit the egregious hackery to a single place.
        // As more data is required to be persisted, openTabs is going
        // to have to talk to History, TabManager, and possibly the Browser history stack. 
        // Suggest tabs have ids as well as indices so we can put it all in the Visits table.
        if let openTabs = openTabs as? FileOpenTabs {
            func persistFunction () -> Void {
                var tabJson = Array<AnyObject>()
                for browser in tabs {
                    if let url = browser.url {
                        tabJson.append([
                            "url": url.absoluteString!
                            ])
                    }
                }
                var model = NSMutableDictionary()
                model["selectedIndex"] = selectedIndex
                model["tabs"] = tabJson
                openTabs.writeToDisk(model)
            }
            openTabs.persistenceTask = persistFunction
        }

    }
    
    private func didInitOpenTabs(openTabs: OpenTabs?) -> Void {
        // XXX This is to limit the egregious hackery to a single place.
        // As more data is required to be persisted, openTabs is going
        // to have to talk to History, TabManager, and possibly the Browser history stack. 
        // Suggest tabs have ids as well as indices so we can put it all in the Visits table.
        if let openTabs = openTabs as? FileOpenTabs {
            func persistFunction () -> Void {
                var tabJson = Array<AnyObject>()
                for browser in tabs {
                    if let url = browser.url {
                        tabJson.append([
                            "url": url.absoluteString!
                            ])
                    }
                }
                var model = NSMutableDictionary()
                model["selectedIndex"] = selectedIndex
                model["tabs"] = tabJson
                openTabs.writeToDisk(model)
            }
            openTabs.persistenceTask = persistFunction
            
            if let model = openTabs.readFromDisk() {
                let tabJson = model["tabs"] as Array<NSDictionary>
                for t in tabJson {
                    let urlString = t["url"] as String
                    println("Restoring \(urlString)")
                    let url = NSURL(string: urlString)!
                    let request = NSURLRequest(URL: url)
                    addTab(request: request)
                }
            
                if let tabIndex = model["selectedIndex"] as? Int {
                    selectTab(tabIndex)
                }
            }
        }
    }
}