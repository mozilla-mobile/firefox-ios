/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

extension Tab {
    class ChangeUserAgent {
        // Track these in-memory only
        static var privateModeHostList = Set<String>()

        private static let file: URL = {
            let root = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            return root.appendingPathComponent("changed-ua-set-of-hosts.xcarchive")
        } ()

        private static var baseDomainList: Set<String> = {
            if let hosts = NSKeyedUnarchiver.unarchiveObject(withFile: ChangeUserAgent.file.path) as? Set<String> {
                return hosts
            }
            return Set<String>()
        } ()

        static func clear() {
            try? FileManager.default.removeItem(at: Tab.ChangeUserAgent.file)
            baseDomainList.removeAll()
        }

        static func contains(url: URL) -> Bool {
            guard let baseDomain = url.baseDomain else { return false }
            return privateModeHostList.contains(baseDomain) || baseDomainList.contains(baseDomain)
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
            }

            if isChangedUA, !baseDomainList.contains(baseDomain) {
                baseDomainList.insert(baseDomain)
            } else if !isChangedUA, baseDomainList.contains(baseDomain) {
                baseDomainList.remove(baseDomain)
            } else {
                // Don't save to disk, return early
                return
            }

            // At this point, saving to disk takes place.
            do {
                let data = try NSKeyedArchiver.archivedData(withRootObject: baseDomainList, requiringSecureCoding: false)
                try data.write(to: ChangeUserAgent.file)
            } catch {
                print("Couldn't write file: \(error)")
            }
        }

    }
}
