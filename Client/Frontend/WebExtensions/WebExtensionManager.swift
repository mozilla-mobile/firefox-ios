/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import WebKit

class WebExtensionManager {
    static let `default` = WebExtensionManager()

    fileprivate(set) var webExtensions: [WebExtension] = []

    fileprivate var backgroundProcesses: [WebExtensionBackgroundProcess] = []

    private var tabObservers: TabObservers!
    private let backgroundQueue = OperationQueue()

    var tabWebViews: [WKWebView] {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate,
            let tabManager = appDelegate.tabManager else {
                return []
        }

        return tabManager.tabs.compactMap({ $0.webView })
    }

    var backgroundProcessWebViews: [WKWebView] {
        return backgroundProcesses.map({ $0.webView })
    }

    var allWebViews: [WKWebView] {
        return tabWebViews + backgroundProcessWebViews
    }

    private init() {
        self.tabObservers = registerFor(.didChangeURL, .didGainFocus, queue: backgroundQueue)

        self.reloadWebExtensions()
    }

    deinit {
        unregister(tabObservers)
    }

    func reloadWebExtensions() {
        var webExtensions: [WebExtension] = []

        do {
            let webExtensionsPath = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("WebExtensions")
            let files = try FileManager.default.contentsOfDirectory(at: webExtensionsPath, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles, .skipsPackageDescendants, .skipsSubdirectoryDescendants])

            for file in files {
                if let webExtension = WebExtension(path: file.path) {
                    webExtensions.append(webExtension)

                    if let backgroundProcess = webExtension.backgroundProcess {
                        backgroundProcesses.append(backgroundProcess)
                    }
                }
            }
        } catch let error {
            print("Unable to get files in WebExtensions folder: \(error.localizedDescription)")
            self.webExtensions = []
        }

        self.webExtensions = webExtensions
    }

    func dispatchToAllWebExtensions(to webView: WKWebView? = nil, apiName: String, listener: String, args: [Any?]? = nil) {
        for webExtension in webExtensions {
            let mirror = Mirror(reflecting: webExtension.interface)
            if let child = mirror.children.first(where: { $0.label == apiName }),
                let api = child.value as? WebExtensionAPIEventDispatcher {
                if let webView = webView {
                    api.dispatch(to: webView, listener: listener, args: args)
                } else {
                    api.dispatchToAllWebViews(listener: listener, args: args)
                }
            }
        }
    }
}

extension WebExtensionManager: TabEventHandler {
    func tab(_ tab: Tab, didChangeURL url: URL) {
        dispatchToAllWebExtensions(apiName: "tabs", listener: "onUpdated", args: [tab.id, ["url": url.absoluteString]])
    }

    func tabDidGainFocus(_ tab: Tab) {
        dispatchToAllWebExtensions(apiName: "tabs", listener: "onActivated", args: [tab.id])
        dispatchToAllWebExtensions(apiName: "tabs", listener: "onActiveChanged", args: [tab.id])
    }
}
