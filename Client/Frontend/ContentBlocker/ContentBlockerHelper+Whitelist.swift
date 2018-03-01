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

    // Get the whitelist domain array as a JSON fragment that can be inserted at the end of a blocklist.
    func whitelistAsJSON() -> String {
        if ContentBlockerHelper.whitelistedDomains.isEmpty {
            return ""
        }
        // Note that * is added to the front of domains, so foo.com becomes *foo.com
        let list = "'*" + ContentBlockerHelper.whitelistedDomains.joined(separator: "','*") + "'"
        return ", {'action': { 'type': 'ignore-previous-rules' }, 'trigger': { 'url-filter': '.*', 'unless-domain': [\(list)] }}".replacingOccurrences(of: "'", with: "\"")
    }

    func whitelist(enable: Bool, url: URL, completion: (() -> Void)? = nil) {
        guard let domain = url.baseDomain else { return }
        if enable {
            ContentBlockerHelper.whitelistedDomains.insert(domain)
        } else {
            ContentBlockerHelper.whitelistedDomains.remove(domain)
        }

        updateWhitelist(completion: completion)
    }

    private func updateWhitelist(completion: (() -> Void)?) {
        TPStatsBlocklistChecker.shared.updateWhitelistedDomains(Array(ContentBlockerHelper.whitelistedDomains))

        removeAllRulesInStore {
            self.compileListsNotInStore {
                NotificationCenter.default.post(name: .ContentBlockerUpdateNeeded, object: nil)
                completion?()
            }
        }

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

    func isURLWhitelisted(url: URL) -> Bool {
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

    func clearWhitelist(completion: (() -> Void)? = nil) {
        ContentBlockerHelper.whitelistedDomains = Set<String>()
        updateWhitelist(completion: completion)
    }
}
