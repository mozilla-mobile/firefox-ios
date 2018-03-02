/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import WebKit
import Shared
import Deferred

@available(iOS 11.0, *)
extension ContentBlockerHelper {

    static func whitelistFileURL() -> URL? {
        guard let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            Sentry.shared.send(message: "Failed to get doc dir for whitelist file.")
            return nil
        }
        return dir.appendingPathComponent("whitelist")
    }

    func pageLoad(navigationAction: WKNavigationAction) {
        guard let url = navigationAction.request.mainDocumentURL else {
            return
        }
        
        setupTabTrackingProtection(forUrl: url)
    }

    func whitelist(enable: Bool, url: URL) {
        guard let domain = url.baseDomain else { return }
        if enable {
            ContentBlockerHelper.whitelistedDomains.insert(domain)
        } else {
            ContentBlockerHelper.whitelistedDomains.remove(domain)
        }

        updateWhitelist()
    }

    private func updateWhitelist() {
        guard let fileURL = ContentBlockerHelper.whitelistFileURL() else { return }
        if ContentBlockerHelper.whitelistedDomains.isEmpty {
            try? FileManager.default.removeItem(at: fileURL)
            return
        }

        let list = ContentBlockerHelper.whitelistedDomains.joined(separator: "\n")
        do {
            try list.write(to: fileURL, atomically: true, encoding: .utf8)
        } catch {
            Sentry.shared.send(message: "Failed to save whitelist file")
        }
    }

    static func isWhitelisted(url: URL) -> Bool {
        guard let domain = url.baseDomain, !domain.isEmpty else {
            return false
        }
        return ContentBlockerHelper.whitelistedDomains.contains(domain)
    }

    func readWhitelistFile() -> [String]? {
        guard let fileURL = ContentBlockerHelper.whitelistFileURL() else { return nil }
        let text = try? String(contentsOf: fileURL, encoding: .utf8)
        if let text = text, !text.isEmpty {
            return text.components(separatedBy: .newlines)
        }

        return nil
    }

    func clearWhitelist() {
        ContentBlockerHelper.whitelistedDomains = Set<String>()
        updateWhitelist()
    }
}
