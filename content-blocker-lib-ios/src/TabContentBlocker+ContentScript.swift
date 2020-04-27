/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import WebKit

extension TabContentBlocker {
    func clearPageStats() {
        stats = TPPageStats()
    }

    func userContentController(_ userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        guard isEnabled,
            let body = message.body as? [String: Any],
            let urls = body["urls"] as? [String],
            let mainDocumentUrl = tab?.currentURL()
        else {
            return
        }

        // Reset the pageStats to make sure the trackingprotection shield icon knows that a page was whitelisted
        guard !ContentBlocker.shared.isWhitelisted(url: mainDocumentUrl) else {
            clearPageStats()
            return
        }

        // The JS sends the urls in batches for better performance. Iterate the batch and check the urls.
        for urlString in urls {
            guard var components = URLComponents(string: urlString) else { return }
            components.scheme = "http"
            guard let url = components.url else { return }

            TPStatsBlocklistChecker.shared.isBlocked(url: url, mainDocumentURL: mainDocumentUrl).uponQueue(.main) { listItem in
                if let listItem = listItem {
                    self.stats = self.stats.create(matchingBlocklist: listItem, host: url.host ?? "")
                }
            }
        }
    }
}
