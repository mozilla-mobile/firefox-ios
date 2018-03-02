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

    static func whitelist(enable: Bool, url: URL) {
        guard let domain = whitelistableDomain(fromUrl: url) else { return }

        if enable {
            whitelistedDomains.insert(domain)
        } else {
            whitelistedDomains.remove(domain)
        }

        updateWhitelist()
    }

    private static func updateWhitelist() {
        guard let fileURL = whitelistFileURL() else { return }
        if whitelistedDomains.isEmpty {
            try? FileManager.default.removeItem(at: fileURL)
            return
        }

        let list = whitelistedDomains.joined(separator: "\n")
        do {
            try list.write(to: fileURL, atomically: true, encoding: .utf8)
        } catch {
            Sentry.shared.send(message: "Failed to save whitelist file")
        }
    }

    // Ensure domains used for whitelisting are standardized by using this function.
    static func whitelistableDomain(fromUrl url: URL) -> String? {
        guard let domain = url.host, !domain.isEmpty else {
            return nil
        }
        return domain
    }

    static func isWhitelisted(url: URL) -> Bool {
        guard let domain = whitelistableDomain(fromUrl: url) else {
            return false
        }
        return whitelistedDomains.contains(domain)
    }

    func readWhitelistFile() -> [String]? {
        guard let fileURL = ContentBlockerHelper.whitelistFileURL() else { return nil }
        let text = try? String(contentsOf: fileURL, encoding: .utf8)
        if let text = text, !text.isEmpty {
            return text.components(separatedBy: .newlines)
        }

        return nil
    }

    static func clearWhitelist() {
        whitelistedDomains = Set<String>()
        updateWhitelist()
    }
}
