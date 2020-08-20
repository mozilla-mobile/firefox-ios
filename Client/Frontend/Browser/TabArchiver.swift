/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

struct TabArchiver {
    static func tabsToRestore(tabsStateArchivePath: String?) -> [SavedTab] {
        print("tabs to restore")
        guard let tabStateArchivePath = tabsStateArchivePath,
              FileManager.default.fileExists(atPath: tabStateArchivePath),
              let tabData = try? Data(contentsOf: URL(fileURLWithPath: tabStateArchivePath)) else {
            return [SavedTab]()
        }
        
        let unarchiver = NSKeyedUnarchiver(forReadingWith: tabData)
        unarchiver.setClass(SavedTab.self, forClassName: "Client.SavedTab")
        unarchiver.setClass(SessionData.self, forClassName: "Client.SessionData")
        
        print("unarchiver decoding...")

        unarchiver.decodingFailurePolicy = .setErrorAndReturn
        guard let tabs = unarchiver.decodeObject(forKey: "tabs") as? [SavedTab] else {
            print("error", unarchiver.error)
            // TODO: Handle error
            //            Sentry.shared.send(
            //                message: "Failed to restore tabs",
            //                tag: SentryTag.tabManager,
            //                severity: .error,
            //                description: "\(unarchiver.error ??? "nil")")
            return [SavedTab]()
        }
        
        for tab in tabs {
            print("restoring: \(tab.url)")
        }
        return tabs
    }
}
