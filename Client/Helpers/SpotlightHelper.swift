/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import CoreSpotlight
import WebKit


private let log = Logger.browserLogger
private let browsingActivityType: String = "org.mozilla.ios.firefox.browsing"

class SpotlightHelper: NSObject {
    private(set) var activity: NSUserActivity? {
        willSet {
            activity?.invalidate()
        }
        didSet {
            activity?.delegate = self
        }
    }

    private var urlForThumbnail: NSURL?
    private var thumbnailImage: UIImage?

    private let createNewTab: ((url: NSURL) -> ())?

    private weak var tab: Browser?

    init(browser: Browser, openURL: ((url: NSURL) -> ())? = nil) {
        createNewTab = openURL
        self.tab = browser

        if let path = NSBundle.mainBundle().pathForResource("SpotlightHelper", ofType: "js") {
            if let source = try? NSString(contentsOfFile: path, encoding: NSUTF8StringEncoding) as String {
                let userScript = WKUserScript(source: source, injectionTime: WKUserScriptInjectionTime.AtDocumentEnd, forMainFrameOnly: true)
                browser.webView!.configuration.userContentController.addUserScript(userScript)
            }
        }
    }

    deinit {
        // Invalidate the currently held user activity (in willSet)
        // and release it.
        self.activity = nil
    }

    func update(pageContent: [String: String], forURL url: NSURL) {
        if AboutUtils.isAboutURL(url) || url.scheme == "about" {
            return
        }

        var activity: NSUserActivity
        if let currentActivity = self.activity where currentActivity.webpageURL == url {
            activity = currentActivity
        } else {
            activity = createUserActivity()
            self.activity = activity
            activity.webpageURL = url
        }

        activity.title = pageContent["title"]
        if #available(iOS 9, *) {
            if !(tab?.isPrivate ?? true) {
                let attrs = CSSearchableItemAttributeSet(itemContentType: kUTTypeHTML as String)
                attrs.contentDescription = pageContent["description"]
                attrs.contentURL = url
                activity.contentAttributeSet = attrs
                activity.eligibleForSearch = true

            }
        }

        // We can't be certain that the favicon isn't already available.
        // If it is, for this URL, then update the activity with the favicon now.
        if urlForThumbnail == url {
            updateImage(thumbnailImage, forURL: url)
        }
    }

    func updateImage(image: UIImage? = nil, forURL url: NSURL) {
        guard let currentActivity = self.activity where currentActivity.webpageURL == url else {
            // We've got a favicon, but not for this URL.
            // Let's store it until we can get the title and description.
            urlForThumbnail = url
            thumbnailImage = image
            return
        }

        if #available(iOS 9.0, *) {
            if let image = image {
                activity?.contentAttributeSet?.thumbnailData = UIImagePNGRepresentation(image)
            }
        }
        urlForThumbnail = nil
        thumbnailImage = nil

        becomeCurrent()
    }

    func becomeCurrent() {
        activity?.becomeCurrent()
    }

    func createUserActivity() -> NSUserActivity {
        return NSUserActivity(activityType: browsingActivityType)
    }
}

extension SpotlightHelper: NSUserActivityDelegate {
    @objc func userActivityWasContinued(userActivity: NSUserActivity) {
        if let url = userActivity.webpageURL {
            createNewTab?(url: url)
        }
    }
}

extension SpotlightHelper: BrowserHelper {
    static func name() -> String {
        return "SpotlightHelper"
    }

    func scriptMessageHandlerName() -> String? {
        return "spotlightMessageHandler"
    }

    func userContentController(userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        if let tab = self.tab,
            let url = tab.url,
            let payload = message.body as? [String: String] {
                update(payload, forURL: url)
        }
    }
}
