// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
import Shared
import Storage
import CoreSpotlight
import MobileCoreServices
import WebKit

private let browsingActivityType: String = "org.mozilla.ios.firefox.browsing"

private let searchableIndex = CSSearchableIndex.default()

class UserActivityHandler {
    init() {
        register(self, forTabEvents: .didClose, .didLoseFocus, .didGainFocus, .didChangeURL, .didLoadPageMetadata, .didLoadReadability) // .didLoadFavicon, // TODO: Bug 1390294
    }

    class func clearSearchIndex(completionHandler: ((Error?) -> Void)? = nil) {
        searchableIndex.deleteAllSearchableItems(completionHandler: completionHandler)
    }

    fileprivate func setUserActivityForTab(_ tab: Tab, url: URL) {
        guard !tab.isPrivate, url.isWebPage(includeDataURIs: false), !InternalURL.isValid(url: url) else {
            tab.userActivity?.resignCurrent()
            tab.userActivity = nil
            return
        }

        tab.userActivity?.invalidate()

        let userActivity = NSUserActivity(activityType: browsingActivityType)
        userActivity.webpageURL = url
        userActivity.becomeCurrent()

        tab.userActivity = userActivity
    }
}

extension UserActivityHandler: TabEventHandler {
    func tabDidGainFocus(_ tab: Tab) {
        tab.userActivity?.becomeCurrent()
    }

    func tabDidLoseFocus(_ tab: Tab) {
        tab.userActivity?.resignCurrent()
    }

    func tab(_ tab: Tab, didChangeURL url: URL) {
        setUserActivityForTab(tab, url: url)
    }

    func tab(_ tab: Tab, didLoadPageMetadata metadata: PageMetadata) {
        guard let url = URL(string: metadata.siteURL) else {
            return
        }

        setUserActivityForTab(tab, url: url)
    }

    func tab(_ tab: Tab, didLoadReadability page: ReadabilityResult) {
        spotlightIndex(page, for: tab)
    }

    func tabDidClose(_ tab: Tab) {
        guard let userActivity = tab.userActivity else {
            return
        }
        tab.userActivity = nil
        userActivity.invalidate()
    }
}

private let log = Logger.browserLogger

extension UserActivityHandler {
    func spotlightIndex(_ page: ReadabilityResult, for tab: Tab) {
        guard let url = tab.url, !tab.isPrivate, url.isWebPage(includeDataURIs: false), !InternalURL.isValid(url: url) else {
            return
        }
        guard let experimental = Experiments.shared.getVariables(featureId: .search).getVariables("spotlight"),
              experimental.getBool("enabled") == true else { // i.e. defaults to false
            return
        }

        let attributeSet = CSSearchableItemAttributeSet(itemContentType: kUTTypeText as String)
        attributeSet.title = page.title

        switch experimental.getString("description") ?? "excerpt" {
        case "excerpt":
            attributeSet.contentDescription = page.excerpt
        case "content":
            attributeSet.contentDescription = page.textContent
        default:
            attributeSet.contentDescription = nil
        }

        switch experimental.getBool("use-html-content") ?? true {
        case true:
            attributeSet.htmlContentData = page.content.utf8EncodedData
        default:
            attributeSet.htmlContentData = nil
        }

        switch experimental.getString("icon") ?? "letter" {
        case "screenshot":
            attributeSet.thumbnailData = tab.screenshot?.pngData()
        case "favicon":
            if let baseDomain = tab.url?.baseDomain {
                attributeSet.thumbnailData = FaviconFetcher.getFaviconFromDiskCache(imageKey: baseDomain)?.pngData()
            }
        case "letter":
            if let url = tab.url {
                attributeSet.thumbnailData = FaviconFetcher.letter(forUrl: url).pngData()
            }
        default:
            attributeSet.thumbnailData = nil
        }

        attributeSet.lastUsedDate = Date()

        let name = page.credits
        if !name.isEmptyOrWhitespace() {
            let author = CSPerson(displayName: name, handles: [], handleIdentifier: name)
            attributeSet.authors = [author]
        }

        let identifier = !page.url.isEmptyOrWhitespace() ? page.url : tab.currentURL()?.absoluteString

        let item = CSSearchableItem(uniqueIdentifier: identifier, domainIdentifier: "org.mozilla.ios.firefox", attributeSet: attributeSet)

        if let numDays = experimental.getInt("keep-for-days") {
            let day: TimeInterval = 60 * 60 * 24
            item.expirationDate = Date.init(timeIntervalSinceNow: Double(numDays) * day)
        }
        searchableIndex.indexSearchableItems([item]) { error in
            if let error = error {
                log.info("Spotlight: Indexing error: \(error.localizedDescription)")
            } else {
                log.info("Spotlight: Search item successfully indexed!")
            }
        }
    }

    func spotlightDeindex(_ page: ReadabilityResult) {
        searchableIndex.deleteSearchableItems(withIdentifiers: [page.url]) { error in
            if let error = error {
                log.info("Spotlight: Deindexing error: \(error.localizedDescription)")
            } else {
                log.info("Spotlight: sSearch item successfully removed!")
            }
        }
    }
}
