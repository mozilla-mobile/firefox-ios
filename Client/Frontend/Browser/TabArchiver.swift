//
//  TabArchiver.swift
//  Client
//
//  Created by Sawyer Blatz on 8/19/20.
//  Copyright © 2020 Mozilla. All rights reserved.
//

import Foundation

struct TabArchiver {
    // Has a TabManagerStoreArchiver that handles tabsToRestore
    // This will allow me to de-dup in the OpenTabsWidget
    // TODO: Make this and have it be static
    static func tabsToRestore(tabsStateArchivePath: String?) -> [SavedTab] {
        guard let tabStateArchivePath = tabsStateArchivePath,
              FileManager.default.fileExists(atPath: tabStateArchivePath),
              let tabData = try? Data(contentsOf: URL(fileURLWithPath: tabStateArchivePath)) else {
            return [SavedTab]()
        }
        
        let unarchiver = NSKeyedUnarchiver(forReadingWith: tabData)
        unarchiver.decodingFailurePolicy = .setErrorAndReturn
        guard let tabs = unarchiver.decodeObject(forKey: "tabs") as? [SavedTab] else {
            // TODO: Handle error
            //            Sentry.shared.send(
            //                message: "Failed to restore tabs",
            //                tag: SentryTag.tabManager,
            //                severity: .error,
            //                description: "\(unarchiver.error ??? "nil")")
            return [SavedTab]()
        }
        return tabs
    }
}
