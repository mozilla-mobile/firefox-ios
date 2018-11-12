/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import SwiftyJSON
import WebKit

private let UserScriptTemplate = """
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
    /*const { browser, chrome }*/%1$@
    // END: WebExtensionAPI.js
    """

private func defaultIconPathFromManifestAction(_ action: JSON) -> String? {
    var defaultIconPath: String?

    if let defaultIconDictionary = action["default_icon"].dictionary,
        let firstDefaultIconKey = defaultIconDictionary.keys.first, // TODO: Determine the largest `default_icon`
        let firstDefaultIconPath = defaultIconDictionary[firstDefaultIconKey]?.string {
        defaultIconPath = firstDefaultIconPath
    } else if let defaultIconString = action["default_icon"].string {
        defaultIconPath = defaultIconString
    }

    return defaultIconPath
}

class WebExtensionAction {
    let webExtension: WebExtension
    let manifestKey: String
    let eventDispatcher: WebExtensionAPIEventDispatcher

    let apiUserScript: WKUserScript

    fileprivate(set) var defaultIcon: URL?
    fileprivate(set) var defaultTitle: String
    fileprivate(set) var defaultURL: URL?

    init?(webExtension: WebExtension, manifestKey: String, eventDispatcher: WebExtensionAPIEventDispatcher) {
        self.webExtension = webExtension
        self.manifestKey = manifestKey
        self.eventDispatcher = eventDispatcher

        let wrappedAPIUserScriptSource = String(format: UserScriptTemplate, webExtension.webExtensionAPIJS)
        self.apiUserScript = WKUserScript(source: wrappedAPIUserScriptSource, injectionTime: .atDocumentStart, forMainFrameOnly: true)

        self.defaultTitle = webExtension.name
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

            eventDispatcher.dispatch(to: backgroundWebView, listener: "onClicked", args: [tab])
        }
    }
}

class WebExtensionBrowserAction: WebExtensionAction {
    init?(webExtension: WebExtension) {
        super.init(webExtension: webExtension, manifestKey: "browser_action", eventDispatcher: webExtension.interface.browserAction)

        let json = webExtension.manifest["browser_action"]
        guard let _ = json.dictionary else {
            return nil
        }

        guard let defaultIconPath = defaultIconPathFromManifestAction(json),
            let defaultTitle = json["default_title"].string else {
            return nil
        }

        self.defaultIcon = webExtension.tempDirectoryURL.appendingPathComponent(defaultIconPath)
        self.defaultTitle = defaultTitle

        if let defaultPopupPath = json["default_popup"].string {
            self.defaultURL = webExtension.urlForResource(at: defaultPopupPath)
        }
    }
}

class WebExtensionSidebarAction: WebExtensionAction {
    init?(webExtension: WebExtension) {
        super.init(webExtension: webExtension, manifestKey: "sidebar_action", eventDispatcher: webExtension.interface.sidebarAction)

        let json = webExtension.manifest["sidebar_action"]
        guard let _ = json.dictionary else {
            return nil
        }

        if let defaultTitle = json["default_title"].string {
            self.defaultTitle = defaultTitle
        }

        if let defaultPanelPath = json["default_panel"].string {
            self.defaultURL = webExtension.urlForResource(at: defaultPanelPath)
        }
    }
}
