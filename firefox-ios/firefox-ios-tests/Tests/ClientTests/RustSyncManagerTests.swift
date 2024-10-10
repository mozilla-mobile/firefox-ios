// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client
import Sync
import Storage
import Shared
import XCTest

class RustSyncManagerTests: XCTestCase {
    struct Keys {
        static let bookmarksStateChangedPrefKey = "sync.engine.bookmarks.enabledStateChanged"
        static let bookmarksEnabledPrefKey = "sync.engine.bookmarks.enabled"
        static let creditcardsStateChangedPrefKey = "sync.engine.creditcards.enabledStateChanged"
        static let creditcardsEnabledPrefKey = "sync.engine.creditcards.enabled"
        static let addressesStateChangedPrefKey = "sync.engine.addresses.enabledStateChanged"
        static let addressesEnabledPrefKey = "sync.engine.addresses.enabled"
        static let historyStateChangedPrefKey = "sync.engine.history.enabledStateChanged"
        static let historyEnabledPrefKey = "sync.engine.history.enabled"
        static let passwordsStateChangedPrefKey = "sync.engine.passwords.enabledStateChanged"
        static let passwordsEnabledPrefKey = "sync.engine.passwords.enabled"
        static let tabsStateChangedPrefKey = "sync.engine.tabs.enabledStateChanged"
        static let tabsEnabledPrefKey = "sync.engine.tabs.enabled"
    }

    private var rustSyncManager: RustSyncManager!
    private var profile: MockBrowserProfile!

    override func setUp() {
        super.setUp()
        profile = MockBrowserProfile(localName: "RustSyncManagerTests")
        rustSyncManager = RustSyncManager(profile: profile,
                                          creditCardAutofillEnabled: true,
                                          logger: MockLogger(),
                                          notificationCenter: MockNotificationCenter())
        rustSyncManager.syncManagerAPI = RustSyncManagerAPI()
        profile.syncManager = rustSyncManager
    }

    override func tearDown() {
        rustSyncManager = nil
        UserDefaults.standard.removeObject(forKey: "fxa.cwts.declinedSyncEngines")
        profile.prefs.removeObjectForKey(Keys.bookmarksStateChangedPrefKey)
        profile.prefs.removeObjectForKey(Keys.bookmarksEnabledPrefKey)
        profile.prefs.removeObjectForKey(Keys.creditcardsStateChangedPrefKey)
        profile.prefs.removeObjectForKey(Keys.creditcardsEnabledPrefKey)
        profile.prefs.removeObjectForKey(Keys.historyStateChangedPrefKey)
        profile.prefs.removeObjectForKey(Keys.historyEnabledPrefKey)
        profile.prefs.removeObjectForKey(Keys.passwordsStateChangedPrefKey)
        profile.prefs.removeObjectForKey(Keys.passwordsEnabledPrefKey)
        profile.prefs.removeObjectForKey(Keys.tabsStateChangedPrefKey)
        profile.prefs.removeObjectForKey(Keys.tabsEnabledPrefKey)
        profile.prefs.removeObjectForKey(Keys.addressesEnabledPrefKey)
        profile.prefs.removeObjectForKey(Keys.addressesStateChangedPrefKey)

        profile = nil
        super.tearDown()
    }

    func testGetEnginesAndKeys() {
        let engines: [RustSyncManagerAPI.TogglableEngine] = [
            .bookmarks,
            .creditcards,
            .history,
            .passwords,
            .tabs,
            .addresses
        ]

        rustSyncManager.getEnginesAndKeys(engines: engines) { (engines, keys) in
            XCTAssertEqual(engines.count, 6)

            XCTAssertTrue(engines.contains("bookmarks"))
            XCTAssertTrue(engines.contains("history"))
            XCTAssertTrue(engines.contains("passwords"))
            XCTAssertTrue(engines.contains("tabs"))
            XCTAssertTrue(engines.contains("addresses"))
            XCTAssertFalse(keys.isEmpty)

            XCTAssertEqual(keys.count, 2)
            XCTAssertNotNil(keys["creditcards"])
            XCTAssertNotNil(keys["passwords"])
        }
    }

    // Temp. Disabled: https://mozilla-hub.atlassian.net/browse/FXIOS-7505
    func testGetEnginesAndKeysWithNoKey() {
        rustSyncManager.getEnginesAndKeys(engines: [.tabs]) { (engines, keys) in
            XCTAssertEqual(engines.count, 1)
            XCTAssertTrue(engines.contains("tabs"))
            XCTAssertTrue(keys.isEmpty)
        }
    }

    func testGetEngineEnablementChangesForAccountWithNewAccount() {
        let declinedEngines = ["tabs", "creditcards"]
        UserDefaults.standard.set(declinedEngines, forKey: "fxa.cwts.declinedSyncEngines")
        let changes = rustSyncManager.getEngineEnablementChangesForAccount()
        XCTAssertFalse(changes["tabs"]!)
        XCTAssertFalse(changes["creditcards"]!)
    }

    func testGetEngineEnablementChangesForAccountWithNoChanges() {
        let changes = rustSyncManager.getEngineEnablementChangesForAccount()
        XCTAssertTrue(changes.isEmpty)
    }

    func testGetEngineEnablementChangesForAccountWithNoRecentChanges() {
        profile.prefs.setBool(true, forKey: Keys.bookmarksEnabledPrefKey)

        let changes = rustSyncManager.getEngineEnablementChangesForAccount()
        XCTAssertTrue(changes.isEmpty)
    }

    func testGetEngineEnablementChangesForAccountWithRecentChanges() {
        profile.prefs.setBool(true, forKey: Keys.bookmarksStateChangedPrefKey)
        profile.prefs.setBool(true, forKey: Keys.bookmarksEnabledPrefKey)
        profile.prefs.setBool(true, forKey: Keys.creditcardsStateChangedPrefKey)
        profile.prefs.setBool(false, forKey: Keys.creditcardsEnabledPrefKey)

        let changes = rustSyncManager.getEngineEnablementChangesForAccount()
        XCTAssertTrue(changes["bookmarks"]!)
        XCTAssertFalse(changes["creditcards"]!)
    }

    // Temp. Disabled: https://mozilla-hub.atlassian.net/browse/FXIOS-7505
    func testUpdateEnginePrefs_bookmarksEnabled() throws {
        profile.prefs.setBool(true, forKey: Keys.bookmarksEnabledPrefKey)
        profile.prefs.setBool(true, forKey: Keys.bookmarksStateChangedPrefKey)

        let declined = ["bookmarks", "creditcards", "passwords"]
        rustSyncManager.updateEnginePrefs(declined: declined)

        let key = try XCTUnwrap(profile.prefs.boolForKey(Keys.bookmarksEnabledPrefKey))
        XCTAssertFalse(key)
        XCTAssertNil(profile.prefs.boolForKey(Keys.bookmarksStateChangedPrefKey))
    }

    func testUpdateEnginePrefs_creditCardEnabled() throws {
        profile.prefs.setBool(true, forKey: Keys.creditcardsEnabledPrefKey)
        profile.prefs.setBool(true, forKey: Keys.creditcardsStateChangedPrefKey)

        let declined = ["bookmarks", "creditcards", "passwords"]
        rustSyncManager.updateEnginePrefs(declined: declined)

        let key = try XCTUnwrap(profile.prefs.boolForKey(Keys.creditcardsEnabledPrefKey))
        XCTAssertFalse(key)
        XCTAssertNil(profile.prefs.boolForKey(Keys.creditcardsStateChangedPrefKey))
    }

    func testUpdateEnginePrefs_historyEnabled() throws {
        profile.prefs.setBool(true, forKey: Keys.historyEnabledPrefKey)
        profile.prefs.setBool(false, forKey: Keys.historyStateChangedPrefKey)

        let declined = ["bookmarks", "creditcards", "passwords"]
        rustSyncManager.updateEnginePrefs(declined: declined)

        let key = try XCTUnwrap(profile.prefs.boolForKey(Keys.historyEnabledPrefKey))
        XCTAssertTrue(key)
        XCTAssertNil(profile.prefs.boolForKey(Keys.historyStateChangedPrefKey))
    }

    func testUpdateEnginePrefs_passwordsEnabled() throws {
        profile.prefs.setBool(false, forKey: Keys.passwordsEnabledPrefKey)
        profile.prefs.setBool(false, forKey: Keys.passwordsStateChangedPrefKey)

        let declined = ["bookmarks", "creditcards", "passwords"]
        rustSyncManager.updateEnginePrefs(declined: declined)

        let key = try XCTUnwrap(profile.prefs.boolForKey(Keys.passwordsEnabledPrefKey))
        XCTAssertFalse(key)
        XCTAssertNil(profile.prefs.boolForKey(Keys.passwordsStateChangedPrefKey))
    }

    func testUpdateEnginePrefs_tabsEnabled() throws {
        profile.prefs.setBool(false, forKey: Keys.tabsEnabledPrefKey)
        profile.prefs.setBool(true, forKey: Keys.tabsStateChangedPrefKey)

        let declined = ["bookmarks", "creditcards", "passwords"]
        rustSyncManager.updateEnginePrefs(declined: declined)

        let key = try XCTUnwrap(profile.prefs.boolForKey(Keys.tabsEnabledPrefKey))
        XCTAssertTrue(key)
        XCTAssertNil(profile.prefs.boolForKey(Keys.tabsStateChangedPrefKey))
    }

    // FXIOS-8331: Disable History Highlight tests while FXIOS-8059 (Epic) is in progress
    // FXIOS-8367: Added a ticket to enable these tests when we re-enable history highlights
    func testUpdateEnginePrefs_addressesEnabled() throws {
        profile.prefs.setBool(true, forKey: Keys.addressesEnabledPrefKey)
        profile.prefs.setBool(true, forKey: Keys.addressesStateChangedPrefKey)

        let declined = ["bookmarks", "creditcards", "passwords"]
        rustSyncManager.updateEnginePrefs(declined: declined)

        let key = try XCTUnwrap(profile.prefs.boolForKey(Keys.addressesEnabledPrefKey))
        XCTAssertTrue(key)
        XCTAssertNil(profile.prefs.boolForKey(Keys.addressesStateChangedPrefKey))
    }

    // FXIOS-8331: Disable History Highlight tests while FXIOS-8059 (Epic) is in progress
    // FXIOS-8367: Added a ticket to enable these tests when we re-enable history highlights
    func testUpdateEnginePrefs_addressesDisabled() throws {
        profile.prefs.setBool(false, forKey: Keys.addressesEnabledPrefKey)
        profile.prefs.setBool(false, forKey: Keys.addressesStateChangedPrefKey)

        let declined = ["bookmarks", "addresses", "passwords"]
        rustSyncManager.updateEnginePrefs(declined: declined)

        let key = try XCTUnwrap(profile.prefs.boolForKey(Keys.addressesEnabledPrefKey))
        XCTAssertFalse(key)
        XCTAssertNil(profile.prefs.boolForKey(Keys.addressesStateChangedPrefKey))
    }

    func test_applicationDidBecomeActive_updateSignInPrefs() throws {
        rustSyncManager.applicationDidBecomeActive()
        let value = try XCTUnwrap(profile.prefs.boolForKey(PrefsKeys.Sync.signedInFxaAccount))
        XCTAssertFalse(value)
    }

    func test_onRemovedAccount_updatePrefs() throws {
        _ = rustSyncManager.onRemovedAccount()
        let signedInStatus = try XCTUnwrap(profile.prefs.boolForKey(PrefsKeys.Sync.signedInFxaAccount))
        let syncedDevicesCount = try XCTUnwrap(profile.prefs.intForKey(PrefsKeys.Sync.numberOfSyncedDevices))
        XCTAssertFalse(signedInStatus)
        XCTAssertEqual(syncedDevicesCount, 0)
    }
}
