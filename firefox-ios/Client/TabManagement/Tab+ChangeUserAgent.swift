// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common

extension Tab {
    class ChangeUserAgent {
        // Track these in-memory only
        // TODO: FXIOS-12594 This global property is not concurrency safe
        nonisolated(unsafe) private static var privateModeHostList = Set<String>()

        // Default to prod filename; tests can override it
        // Not concurrency safe, this should only ever be changed for tests
        nonisolated(unsafe) static var pathComponent = "changed-ua-set-of-hosts.xcarchive"

        private static let file: URL = {
            let root = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            return root.appendingPathComponent(pathComponent)
        }()

        private static let oldUAFileLocation: URL = {
            let root = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            return root.appendingPathComponent(pathComponent)
        }()

        // TODO: FXIOS-12594 This global property is not concurrency safe
        nonisolated(unsafe) private static var baseDomainList: Set<String> = {
            if let data = getDataFromFile(),
               let hosts = try? NSKeyedUnarchiver.unarchivedObject(
                ofClasses: [NSSet.self, NSArray.self, NSString.self],
                from: data
               ) as? Set<String> {
                return hosts
            }
            return Set<String>()
        }()

        static func clear() {
            try? FileManager.default.removeItem(at: Tab.ChangeUserAgent.file)
            baseDomainList.removeAll()
        }

        static func contains(url: URL, isPrivate: Bool) -> Bool {
            guard let baseDomain = url.baseDomain else { return false }
            return isPrivate ? privateModeHostList.contains(baseDomain) : baseDomainList.contains(baseDomain)
        }

        static func performMigration(fileManager: FileManagerProtocol = FileManager.default) {
            guard fileManager.fileExists(atPath: oldUAFileLocation.path) else { return }
            do {
                try fileManager.moveItem(at: oldUAFileLocation, to: file)
            } catch {
                DefaultLogger.shared.log("Migration of changed UA file failed", level: .info, category: .tabs)
            }
        }

        static func updateDomainList(forUrl url: URL, isChangedUA: Bool, isPrivate: Bool) {
            guard let baseDomain = url.baseDomain, !baseDomain.isEmpty else { return }

            if isPrivate {
                if isChangedUA {
                    ChangeUserAgent.privateModeHostList.insert(baseDomain)
                    return
                } else {
                    ChangeUserAgent.privateModeHostList.remove(baseDomain)
                    // Continue to next section and try remove it from `hostList` also.
                }
            } else {
                if isChangedUA, !baseDomainList.contains(baseDomain) {
                    baseDomainList.insert(baseDomain)
                } else if !isChangedUA, baseDomainList.contains(baseDomain) {
                    baseDomainList.remove(baseDomain)
                } else {
                    // Don't save to disk, return early
                    return
                }
            }

            // At this point, saving to disk takes place.
            do {
                let data = try NSKeyedArchiver.archivedData(
                    withRootObject: baseDomainList,
                    requiringSecureCoding: false
                )
                try data.write(to: ChangeUserAgent.file)
            } catch {}
        }

        // Returns a URL without a mobile prefix (`"m."` or `"mobile."`)
        func removeMobilePrefixFrom(url: URL) -> URL {
            let subDomainsToRemove: Set<String> = ["m", "mobile"]

            guard var components = URLComponents(url: url, resolvingAgainstBaseURL: true) else { return url }
            guard let parts = components.host?
                .split(separator: ".")
                .filter({ !subDomainsToRemove.contains(String($0)) })
            else { return url }

            let host = parts.joined(separator: ".")

            guard host != url.publicSuffix else { return url }
            components.host = host

            return components.url ?? url
        }

        private static func getDataFromFile() -> Data? {
            return try? Data(contentsOf: ChangeUserAgent.file)
        }
    }
}
