/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import SwiftyJSON
import WebKit

private let UserScriptTemplate = """
    (function() {
        document.addEventListener("readystatechange", function() {
            if (document.readyState !== "interactive") { return; }
            let viewport = document.querySelector("meta[name=\\"viewport\\"]");
            if (!viewport) {
                viewport = document.createElement("meta");
                viewport.name = "viewport";
                document.head.appendChild(viewport);
            }
            viewport.content = "width=device-width,initial-scale=1,minimum-scale=1";
        });

        // BEGIN: WebExtensionAPI.js
        /*const browser*/%1$@
        // END: WebExtensionAPI.js
    })();
    """

private func defaultIconPathFromManifest(_ manifest: JSON) -> String? {
    var defaultIconPath: String?

    let json = manifest["browser_action"]

    if let defaultIconDictionary = json["default_icon"].dictionary,
        let firstDefaultIconKey = defaultIconDictionary.keys.first, // TODO: Determine the largest `default_icon`
        let firstDefaultIconPath = defaultIconDictionary[firstDefaultIconKey]?.string {
        defaultIconPath = firstDefaultIconPath
    } else if let defaultIconString = json["default_icon"].string {
        defaultIconPath = defaultIconString
    }

    return defaultIconPath
}

class WebExtensionBrowserAction {
    let webExtension: WebExtension

    let apiUserScript: WKUserScript

    let defaultIcon: URL
    let defaultTitle: String

    private(set) var defaultPopup: URL?

    init?(webExtension: WebExtension) {
        let json = webExtension.manifest["browser_action"]

        guard let defaultIconPath = defaultIconPathFromManifest(webExtension.manifest),
            let defaultTitle = json["default_title"].string else {
            return nil
        }

        let tempDirectoryURL = webExtension.tempDirectoryURL

        self.webExtension = webExtension

        let wrappedAPIUserScriptSource = String(format: UserScriptTemplate, webExtension.webExtensionAPIJS)
        self.apiUserScript = WKUserScript(source: wrappedAPIUserScriptSource, injectionTime: .atDocumentStart, forMainFrameOnly: true)

        self.defaultIcon = tempDirectoryURL.appendingPathComponent(defaultIconPath)
        self.defaultTitle = defaultTitle

        if let defaultPopupPath = json["default_popup"].string {
            self.defaultPopup = webExtension.urlForResource(at: defaultPopupPath)
        }
    }

    func didClick() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate,
            let tabManager = appDelegate.tabManager,
            let backgroundWebView = webExtension.backgroundProcess?.webView else {
            return
        }

        if let selectedTab = appDelegate.tabManager.selectedTab {
            let tab: [String : Any?] = [
                "id": selectedTab.id,
                "active": true,
                "hidden": false,
                "highlighted": true,
                "incognito": selectedTab.isPrivate,
                "index": tabManager.tabs.firstIndex(of: selectedTab) ?? -1,
                "isArticle": selectedTab.readerModeAvailableOrActive,
                "isInReaderMode": selectedTab.url?.isReaderModeURL ?? false,
                "lastAccessed": selectedTab.lastExecutedTime ?? 0,
                "pinned": false,
                "selected": true,
                "url": selectedTab.url?.absoluteString
            ]

            webExtension.interface.browserAction.dispatch(to: backgroundWebView, listener: "onClicked", args: [tab])
        }
    }
}
