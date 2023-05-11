// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client
import Storage
import XCTest

private typealias MZSyncResult = MozillaAppServices.SyncResult

class RustSyncManagerTests: XCTestCase {
    let bookmarksStateChangedPrefKey = "sync.engine.bookmarks.enabledStateChanged"
    let bookmarksEnabledPrefKey = "sync.engine.bookmarks.enabled"
    let historyStateChangedPrefKey = "sync.engine.history.enabledStateChanged"
    let historyEnabledPrefKey = "sync.engine.history.enabled"
    let passwordsStateChangedPrefKey = "sync.engine.passwords.enabledStateChanged"
    let passwordsEnabledPrefKey = "sync.engine.passwords.enabled"
    let tabsStateChangedPrefKey = "sync.engine.tabs.enabledStateChanged"
    let tabsEnabledPrefKey = "sync.engine.tabs.enabled"
    var rustSyncManager: RustSyncManager!
    var profile: MockBrowserProfile!

    override func setUp() {
        super.setUp()
        profile = MockBrowserProfile(localName: "RustSyncManagerTests")
        rustSyncManager = RustSyncManager(profile: profile,
                                          logger: MockLogger(),
                                          notificationCenter: MockNotificationCenter())
    }

    override func tearDown() {
        super.tearDown()
        rustSyncManager = nil
        UserDefaults.standard.removeObject(forKey: "fxa.cwts.declinedSyncEngines")
        profile.prefs.removeObjectForKey(bookmarksStateChangedPrefKey)
        profile.prefs.removeObjectForKey(bookmarksEnabledPrefKey)
        profile.prefs.removeObjectForKey(historyStateChangedPrefKey)
        profile.prefs.removeObjectForKey(historyEnabledPrefKey)
        profile.prefs.removeObjectForKey(passwordsStateChangedPrefKey)
        profile.prefs.removeObjectForKey(passwordsEnabledPrefKey)
        profile.prefs.removeObjectForKey(tabsStateChangedPrefKey)
        profile.prefs.removeObjectForKey(tabsEnabledPrefKey)
        profile = nil
    }

    func testGetEnginesAndKeys() {
        let engines = ["bookmarks", "history", "passwords", "tabs"]
        rustSyncManager.getEnginesAndKeys(engines: engines) { (engines, keys) in
            XCTAssertEqual(engines.count, 4)
            XCTAssertTrue(engines.contains("bookmarks"))
            XCTAssertTrue(engines.contains("history"))
            XCTAssertTrue(engines.contains("passwords"))
            XCTAssertTrue(engines.contains("tabs"))
            XCTAssertFalse(keys.isEmpty)
        }
    }

    func testGetEnginesAndKeysWithNoKey() {
        rustSyncManager.getEnginesAndKeys(engines: ["tabs"]) { (engines, keys) in
            XCTAssertEqual(engines.count, 1)
            XCTAssertTrue(engines.contains("tabs"))
            XCTAssertTrue(keys.isEmpty)
        }
    }

    func testGetEngineEnablementChangesForAccountWithNewAccount() {
        let declinedEngines = ["tabs"]
        UserDefaults.standard.set(declinedEngines, forKey: "fxa.cwts.declinedSyncEngines")
        let changes = rustSyncManager.getEngineEnablementChangesForAccount()
        XCTAssertFalse(changes["tabs"]!)
    }

    func testGetEngineEnablementChangesForAccountWithNoChanges() {
        let changes = rustSyncManager.getEngineEnablementChangesForAccount()
        XCTAssertTrue(changes.isEmpty)
    }

    func testGetEngineEnablementChangesForAccountWithNoRecentChanges() {
        profile.prefs.setBool(true, forKey: bookmarksEnabledPrefKey)

        let changes = rustSyncManager.getEngineEnablementChangesForAccount()
        XCTAssertTrue(changes.isEmpty)
    }

    func testGetEngineEnablementChangesForAccountWithRecentChanges() {
        profile.prefs.setBool(true, forKey: bookmarksStateChangedPrefKey)
        profile.prefs.setBool(true, forKey: bookmarksEnabledPrefKey)

        let changes = rustSyncManager.getEngineEnablementChangesForAccount()
        XCTAssertTrue(changes["bookmarks"]!)
    }

    func testUpdateEnginePrefs() {
        profile.prefs.setBool(true, forKey: bookmarksEnabledPrefKey)
        profile.prefs.setBool(true, forKey: historyEnabledPrefKey)
        profile.prefs.setBool(false, forKey: passwordsEnabledPrefKey)
        profile.prefs.setBool(false, forKey: tabsEnabledPrefKey)

        profile.prefs.setBool(true, forKey: bookmarksStateChangedPrefKey)
        profile.prefs.setBool(false, forKey: historyStateChangedPrefKey)
        profile.prefs.setBool(false, forKey: passwordsStateChangedPrefKey)
        profile.prefs.setBool(true, forKey: tabsStateChangedPrefKey)

        let declined = ["bookmarks", "passwords"]
        rustSyncManager.updateEnginePrefs(declined: declined)

        XCTAssertFalse(profile.prefs.boolForKey(bookmarksEnabledPrefKey)!)
        XCTAssertTrue(profile.prefs.boolForKey(historyEnabledPrefKey)!)
        XCTAssertFalse(profile.prefs.boolForKey(passwordsEnabledPrefKey)!)
        XCTAssertTrue(profile.prefs.boolForKey(tabsEnabledPrefKey)!)

        XCTAssertNil(profile.prefs.boolForKey(bookmarksStateChangedPrefKey))
        XCTAssertNil(profile.prefs.boolForKey(historyStateChangedPrefKey))
        XCTAssertNil(profile.prefs.boolForKey(passwordsStateChangedPrefKey))
        XCTAssertNil(profile.prefs.boolForKey(tabsStateChangedPrefKey))
    }
}
