// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import Storage
import CoreSpotlight
import MobileCoreServices
import WebKit
import SiteImageView
import Common
import WebEngine

let browsingActivityType = "org.mozilla.ios.firefox.browsing"

private let searchableIndex = CSSearchableIndex.default()

class UserActivityHandler {
    private let logger: Logger

    init(logger: Logger = DefaultLogger.shared) {
        self.logger = logger
        register(
            self,
            forTabEvents: .didClose,
            .didLoseFocus,
            .didGainFocus,
            .didChangeURL,
            .didLoadPageMetadata,
            .didLoadReadability
        )
    }

    class func clearSearchIndex(completionHandler: ((Error?) -> Void)? = nil) {
        searchableIndex.deleteAllSearchableItems(completionHandler: completionHandler)
    }

    fileprivate func setUserActivityForTab(_ tab: Tab, url: URL) {
        guard !tab.isPrivate, url.isWebPage(includeDataURIs: false),
              !InternalURL.isValid(url: url)
        else {
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
    var tabEventWindowResponseType: TabEventHandlerWindowResponseType { return .allWindows }

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
        guard let url = URL(string: metadata.siteURL, invalidCharacters: false) else { return }

        setUserActivityForTab(tab, url: url)
    }

    func tab(_ tab: Tab, didLoadReadability page: ReadabilityResult) {
        Task {
            await spotlightIndex(page, for: tab)
        }
    }

    func tabDidClose(_ tab: Tab) {
        guard let userActivity = tab.userActivity else { return }
        tab.userActivity = nil
        userActivity.invalidate()
    }
}

extension UserActivityHandler {
    func spotlightIndex(_ page: ReadabilityResult, for tab: Tab) async {
        guard let url = tab.url,
              !tab.isPrivate,
              url.isWebPage(includeDataURIs: false),
              !InternalURL.isValid(url: url)
        else { return }

        let spotlightConfig = FxNimbus.shared.features.spotlightSearch.value()
        if !spotlightConfig.enabled { return }

        let attributeSet = CSSearchableItemAttributeSet(itemContentType: UTType.text.identifier)
        attributeSet.title = page.title

        switch spotlightConfig.searchableContent {
        case .textExcerpt:
            attributeSet.contentDescription = page.excerpt
        case .textContent:
            attributeSet.contentDescription = page.textContent
        case .htmlContent:
            attributeSet.htmlContentData = page.content.utf8EncodedData
        default:
            attributeSet.contentDescription = nil
            attributeSet.htmlContentData = nil
        }

        switch spotlightConfig.iconType {
        case .screenshot:
            attributeSet.thumbnailData = tab.screenshot?.pngData()
        case .favicon:
            if let url = tab.url {
                let faviconFetcher = DefaultSiteImageHandler.factory()
                let siteImageModel = SiteImageModel(id: UUID(),
                                                    imageType: .favicon,
                                                    siteURL: url)
                let image = await faviconFetcher.getImage(model: siteImageModel)
                attributeSet.thumbnailData = image.pngData()
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

        let identifier = tab.currentURL()?.absoluteString

        let item = CSSearchableItem(
            uniqueIdentifier: identifier,
            domainIdentifier: "org.mozilla.ios.firefox",
            attributeSet: attributeSet
        )

        if let numDays = spotlightConfig.keepForDays {
            let day: TimeInterval = 60 * 60 * 24
            item.expirationDate = Date(timeIntervalSinceNow: Double(numDays) * day)
        }
        do {
            try await searchableIndex.indexSearchableItems([item])
        } catch {}
    }
}
