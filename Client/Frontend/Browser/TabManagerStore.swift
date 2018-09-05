/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit
import Storage
import Shared
import XCGLogger

private let log = Logger.browserLogger

class TabManagerStore {
    var isRestoring = false
    fileprivate let imageStore: DiskImageStore?
    fileprivate var fileManager: FileManager!

    init(imageStore: DiskImageStore?, _ fileManager: FileManager = FileManager.default) {
        self.fileManager = fileManager
        self.imageStore = imageStore
    }

    fileprivate func tabsStateArchivePath() -> String {
        guard let profilePath = fileManager.containerURL(
            forSecurityApplicationGroupIdentifier: AppInfo.sharedContainerIdentifier)?
            .appendingPathComponent("profile.profile").path else {
                let documentsPath =
                    NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
                return URL(fileURLWithPath: documentsPath).appendingPathComponent("tabsState.archive").path
        }
        
        return URL(fileURLWithPath: profilePath).appendingPathComponent("tabsState.archive").path
    }
    
    fileprivate func migrateTabsStateArchive() {
        guard let oldPath = try? fileManager.url(
            for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            .appendingPathComponent("tabsState.archive").path,
            fileManager.fileExists(atPath: oldPath) else {
                return
        }
        
        log.info("Migrating tabsState.archive from ~/Documents to shared container")
        
        guard let profilePath = fileManager.containerURL(
            forSecurityApplicationGroupIdentifier: AppInfo.sharedContainerIdentifier)?
            .appendingPathComponent("profile.profile").path else {
                log.error("Unable to get profile path in shared container to move tabsState.archive")
                return
        }
        
        let newPath = URL(fileURLWithPath: profilePath).appendingPathComponent("tabsState.archive").path
        
        do {
            try fileManager.createDirectory(atPath: profilePath, withIntermediateDirectories: true, attributes: nil)
            try fileManager.moveItem(atPath: oldPath, toPath: newPath)
            
            log.info("Migrated tabsState.archive to shared container successfully")
        } catch let error as NSError {
            log.error("Unable to move tabsState.archive to shared container: \(error.localizedDescription)")
        }
    }
    
    func tabArchiveData() -> Data? {
        migrateTabsStateArchive()
        
        let tabStateArchivePath = tabsStateArchivePath()
        return
            fileManager.fileExists(atPath: tabStateArchivePath)
                ? try? Data(contentsOf: URL(fileURLWithPath: tabStateArchivePath))
                : nil
    }
    
    func tabsToRestore(fromData data: Data?) -> [SavedTab]? {
        guard let tabData = data else {
            return nil
        }
        let unarchiver = NSKeyedUnarchiver(forReadingWith: tabData)
        unarchiver.decodingFailurePolicy = .setErrorAndReturn
        guard let tabs = unarchiver.decodeObject(forKey: "tabs") as? [SavedTab] else {
            Sentry.shared.send(
                message: "Failed to restore tabs",
                tag: SentryTag.tabManager,
                severity: .error,
                description: "\(unarchiver.error ??? "nil")")
            return nil
        }
        return tabs
    }
    
    func prepareSavedTabs(fromTabs tabs: [Tab], selectedTab: Tab?) -> [SavedTab]? {
        var savedTabs = [SavedTab]()
        var savedUUIDs = Set<String>()
        for tab in tabs {
            if let savedTab = SavedTab(tab: tab, isSelected: tab === selectedTab) {
                savedTabs.append(savedTab)
                
                if let screenshot = tab.screenshot,
                    let screenshotUUID = tab.screenshotUUID {
                    savedUUIDs.insert(screenshotUUID.uuidString)
                    imageStore?.put(screenshotUUID.uuidString, image: screenshot)
                }
            }
        }
        // Clean up any screenshots that are no longer associated with a tab.
        _ = imageStore?.clearExcluding(savedUUIDs)
        return savedTabs.isEmpty ? nil : savedTabs
    }
    
    func preserveTabsInternal(_ tabs: [Tab], selectedTab: Tab?) {
        assert(Thread.isMainThread)
        guard !isRestoring, let savedTabs = prepareSavedTabs(
            fromTabs: tabs, selectedTab: selectedTab) else { return }
        preserveTabsToFile(savedTabs)
    }
    
    func preserveTabsToFile(_ savedTabs: [SavedTab]) {
        let path = tabsStateArchivePath()
        let tabStateData = NSMutableData()

        let archiver = NSKeyedArchiver(forWritingWith: tabStateData)
        archiver.encode(savedTabs, forKey: "tabs")
        archiver.finishEncoding()
        tabStateData.write(toFile: path, atomically: true)
    }

    func restoreInternal(savedTabs: [SavedTab], clearPrivateTabs: Bool, tabManager: TabManager) -> Tab? {
        guard savedTabs.count > 0 else { return nil }
        var savedTabs = savedTabs
        // Make sure to wipe the private tabs if the user has the pref turned on
        if clearPrivateTabs {
            savedTabs = savedTabs.filter { !$0.isPrivate }
        }
        
        var tabToSelect: Tab?
        for savedTab in savedTabs {
            // Provide an empty request to prevent a new tab from loading the home screen
            var tab = tabManager.addTab(flushToDisk: false, zombie: true, isPrivate: savedTab.isPrivate)
            tab = savedTab.configureSavedTabUsing(tab, imageStore: imageStore)

            if savedTab.isSelected {
                tabToSelect = tab
            }
        }
        
        if tabToSelect == nil {
            tabToSelect = tabManager.tabs.first(where: { $0.isPrivate == false })
        }

        return tabToSelect
    }
}
