// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Shared
import WebKit

/// The activity representing in the Share sheet the action to add a website to the iOS homepage.
///
/// - Note: the activity is a `WKWebView` cause the frameworks generates the add to home page activity only
/// when passing a `WKWebView`. This `WKWebView` subclass gives the ability to modify the content of the activity,
/// by modifying the title and/or the url.
class HomePageActivity: WKWebView {
    private let stubbedURL: URL?
    private let stubbedTitle: String?

    init(url: URL?, title: String?) {
        if let internalURL = InternalURL(url) {
            stubbedURL = internalURL.extractedUrlParam
        } else {
            stubbedURL = url
        }
        stubbedTitle = title
        super.init(frame: .zero, configuration: .init())
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var url: URL? {
        return stubbedURL
    }

    override var title: String? {
        return stubbedTitle
    }
}
