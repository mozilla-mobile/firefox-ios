/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import CoreSpotlight
import MobileCoreServices
import WebKit

private let log = Logger.browserLogger
private let browsingActivityType: String = "org.mozilla.ios.firefox.browsing"

class SpotlightHelper: NSObject {
    fileprivate(set) var activity: NSUserActivity? {
        willSet {
            activity?.invalidate()
        }
    }

    fileprivate var searchableItem: CSSearchableItem?

    fileprivate var urlForThumbnail: URL?
    fileprivate var thumbnailImage: UIImage?

    fileprivate weak var tab: Tab?

    fileprivate var isPrivate: Bool {
        return self.tab?.isPrivate ?? true
    }

    init(tab: Tab) {
        self.tab = tab

        if let path = Bundle.main.path(forResource: "SpotlightHelper", ofType: "js") {
            if let source = try? NSString(contentsOfFile: path, encoding: String.Encoding.utf8.rawValue) as String {
                let userScript = WKUserScript(source: source, injectionTime: WKUserScriptInjectionTime.atDocumentEnd, forMainFrameOnly: true)
                tab.webView!.configuration.userContentController.addUserScript(userScript)
            }
        }
    }

    deinit {

        // Invalidate the currently held user activity (in willSet)
        // and release it.
        self.activity = nil
    }

    func update(_ pageContent: [String: String], forURL url: URL) {
        guard url.isWebPage(includeDataURIs: false) else {
            return
        }

        let attributeSet = CSSearchableItemAttributeSet(itemContentType: kUTTypeHTML as String)

        var activity: NSUserActivity
        if self.activity != nil && self.activity?.webpageURL == url {
            activity = self.activity!
        } else {
            activity = createUserActivity(forURL: url, attributeSet: attributeSet)
            self.activity = activity
        }

        if !self.isPrivate {
            var searchableItem: CSSearchableItem
            if self.searchableItem != nil && self.searchableItem?.attributeSet.contentURL == url {
                searchableItem = self.searchableItem!
            } else {
                searchableItem = createSearchableItem(forURL: url, attributeSet: attributeSet)
                self.searchableItem = searchableItem
            }

            let title = pageContent["title"]
            let description = pageContent["description"]

            activity.title = title

            attributeSet.title = title
            attributeSet.contentDescription = description
        }

        // We can't be certain that the favicon isn't already available.
        // If it is, for this URL, then update the activity with the favicon now.
        if urlForThumbnail == url {
            updateImage(thumbnailImage, forURL: url)
        }
    }

    func updateImage(_ image: UIImage? = nil, forURL url: URL) {
        if self.activity == nil || self.activity?.webpageURL != url {

            // We've got a favicon, but not for this URL.
            // Let's store it until we can get the title and description.
            urlForThumbnail = url
            thumbnailImage = image
            return
        }

        if let image = image {
            let thumbnailData = UIImagePNGRepresentation(image)

            activity?.contentAttributeSet?.thumbnailData = thumbnailData

            if !self.isPrivate {
                searchableItem?.attributeSet.thumbnailData = thumbnailData
            }
        }

        if !self.isPrivate && searchableItem != nil {
            CSSearchableIndex.default().indexSearchableItems([searchableItem!])
        }

        activity?.becomeCurrent()

        urlForThumbnail = nil
        thumbnailImage = nil
    }

    func createUserActivity(forURL url: URL, attributeSet: CSSearchableItemAttributeSet) -> NSUserActivity {
        let userActivity = NSUserActivity(activityType: browsingActivityType)
        userActivity.webpageURL = url
        userActivity.contentAttributeSet = attributeSet
        userActivity.isEligibleForSearch = false
        return userActivity
    }

    func createSearchableItem(forURL url: URL, attributeSet: CSSearchableItemAttributeSet) -> CSSearchableItem {
        let searchableItem = CSSearchableItem(uniqueIdentifier: url.absoluteString, domainIdentifier: "webpages", attributeSet: attributeSet)
        attributeSet.contentURL = url
        return searchableItem
    }
}

extension SpotlightHelper: TabContentScript {
    static func name() -> String {
        return "SpotlightHelper"
    }

    func scriptMessageHandlerName() -> String? {
        return "spotlightMessageHandler"
    }

    func userContentController(_ userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        if let tab = self.tab,
            let url = tab.url,
            let payload = message.body as? [String: String] {
                update(payload, forURL: url as URL)
        }
    }
}

extension SpotlightHelper {
    class func clearSearchIndex(completionHandler: ((Error?) -> Void)? = nil) {
        CSSearchableIndex.default().deleteAllSearchableItems(completionHandler: completionHandler)
    }
}
