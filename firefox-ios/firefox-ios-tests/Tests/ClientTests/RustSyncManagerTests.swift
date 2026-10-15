// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client
import MozillaAppServices
import Shared
import Sync
import TestKit
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

    private var logins: MockLoginProvider!
    private var autofill: MockAutofill!
    private var places: MockPlaces!
    private var tabs: MockRemoteTabs!

    override func setUp() {
        super.setUp()
        logins = MockLoginProvider()
        autofill = MockAutofill()
        places = MockPlaces()
        tabs = MockRemoteTabs()

        profile = MockBrowserProfile(localName: "RustSyncManagerTests")
        rustSyncManager = RustSyncManager(profile: profile,
                                          creditCardAutofillEnabled: true,
                                          logger: MockLogger(),
                                          logins: logins,
                                          autofill: autofill,
                                          places: places,
                                          tabs: tabs,
                                          notificationCenter: MockNotificationCenter())
        rustSyncManager.syncManagerAPI = RustSyncManagerAPI(dispatchQueue: MockDispatchQueue())
        profile.syncManager = rustSyncManager
    }

    override func tearDown() {
        rustSyncManager = nil
        UserDefaults.standard.removeObject(forKey: "fxa.cwts.declinedSyncEngines")
        profile.prefs.clearAll()
        profile.removeDirectory()
        profile = nil
        super.tearDown()
    }

    func testGetEnginesAndKeys_withLoginsVerified() {
        logins.loginsVerified = true
        let engines: [RustSyncManagerAPI.TogglableEngine] = [
            .bookmarks,
            .creditcards,
            .history,
            .passwords,
            .tabs,
            .addresses
        ]

        rustSyncManager.getEnginesAndKeys(engines: engines) { [tabs, logins, autofill, places] (engines, keys) in
            XCTAssertEqual(engines.count, 6)

            XCTAssertEqual(engines[safe: 0], "bookmarks")
            XCTAssertEqual(engines[safe: 1], "creditcards")
            XCTAssertEqual(engines[safe: 2], "history")
            XCTAssertEqual(engines[safe: 3], "passwords")
            XCTAssertEqual(engines[safe: 4], "tabs")
            XCTAssertEqual(engines[safe: 5], "addresses")
            XCTAssertFalse(keys.isEmpty)

            XCTAssertNotNil(keys["creditcards"])

            XCTAssertEqual(tabs?.registerWithSyncManagerCalled, 1)
            XCTAssertEqual(logins?.registerWithSyncManagerCalled, 1)
            XCTAssertEqual(autofill?.registerWithSyncManagerCalled, 1)
            XCTAssertEqual(places?.registerWithSyncManagerCalled, 1)
        }
    }

    func testGetEnginesWithRetrievedKeys() {
        let enginesToSync = rustSyncManager
            .getEnginesWithRetrievedKeys("testCCKey",
                                         "testLoginsKey",
                                         rustSyncManager.syncManagerAPI.rustTogglableEngines)
        XCTAssertEqual(enginesToSync.count, 6)
        XCTAssertTrue(enginesToSync.contains(.creditcards))
        XCTAssertTrue(enginesToSync.contains(.passwords))

        let enginesToSync2 = rustSyncManager
            .getEnginesWithRetrievedKeys(nil, nil, rustSyncManager.syncManagerAPI.rustTogglableEngines)
        XCTAssertEqual(enginesToSync2.count, 4)
        XCTAssertFalse(enginesToSync2.contains(.creditcards))
        XCTAssertFalse(enginesToSync2.contains(.passwords))

        let enginesToSync3 = rustSyncManager
            .getEnginesWithRetrievedKeys("testCCKey",
                                         nil,
                                         rustSyncManager.syncManagerAPI.rustTogglableEngines)
        XCTAssertEqual(enginesToSync3.count, 5)
        XCTAssertTrue(enginesToSync3.contains(.creditcards))
        XCTAssertFalse(enginesToSync3.contains(.passwords))

        let enginesToSync4 = rustSyncManager
            .getEnginesWithRetrievedKeys(nil,
                                         "testLoginsKey",
                                         rustSyncManager.syncManagerAPI.rustTogglableEngines)
        XCTAssertEqual(enginesToSync4.count, 5)
        XCTAssertFalse(enginesToSync4.contains(.creditcards))
        XCTAssertTrue(enginesToSync4.contains(.passwords))
    }

    func testGetEnginesAndKeys_withOutLoginsVerified() {
        logins.loginsVerified = false
        let engines: [RustSyncManagerAPI.TogglableEngine] = [
            .bookmarks,
            .creditcards,
            .history,
            .passwords,
            .tabs,
            .addresses
        ]

        rustSyncManager.getEnginesAndKeys(engines: engines) { [tabs, logins, autofill, places] (engines, keys) in
            XCTAssertEqual(engines.count, 5)

            XCTAssertEqual(engines[safe: 0], "bookmarks")
            XCTAssertEqual(engines[safe: 1], "creditcards")
            XCTAssertEqual(engines[safe: 2], "history")
            XCTAssertEqual(engines[safe: 3], "tabs")
            XCTAssertEqual(engines[safe: 4], "addresses")
            XCTAssertFalse(keys.isEmpty)

            XCTAssertNotNil(keys["creditcards"])

            XCTAssertEqual(tabs?.registerWithSyncManagerCalled, 1)
            XCTAssertEqual(logins?.registerWithSyncManagerCalled, 0)
            XCTAssertEqual(autofill?.registerWithSyncManagerCalled, 1)
            XCTAssertEqual(places?.registerWithSyncManagerCalled, 1)
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

    func testGetEngineChoices_withPerDeviceSyncEnabled_returnsDeviceModel() {
        let model = rustSyncManager.getEngineChoices(perDeviceSyncEnabled: true)

        XCTAssertEqual(model, .device)
    }

    func testGetEngineChoices_withPerDeviceSyncEnabledAndRecentChanges_returnsDeviceModel() {
        profile.prefs.setBool(true, forKey: Keys.bookmarksStateChangedPrefKey)
        profile.prefs.setBool(false, forKey: Keys.bookmarksEnabledPrefKey)

        let model = rustSyncManager.getEngineChoices(perDeviceSyncEnabled: true)

        XCTAssertEqual(model, .device)
    }

    func testGetEngineChoices_withPerDeviceSyncEnabledAndNewAccount_returnsDeviceModel() {
        UserDefaults.standard.set(["tabs", "creditcards"], forKey: "fxa.cwts.declinedSyncEngines")

        let model = rustSyncManager.getEngineChoices(perDeviceSyncEnabled: true)

        XCTAssertEqual(model, .device)
    }

    func testGetEngineChoices_withPerDeviceSyncDisabledAndNoChanges_returnsEmptyAccountModel() {
        let model = rustSyncManager.getEngineChoices(perDeviceSyncEnabled: false)

        XCTAssertEqual(model, .account(enabledChanges: [:]))
    }

    func testGetEngineChoices_withPerDeviceSyncDisabledAndNoRecentChanges_returnsEmptyAccountModel() {
        profile.prefs.setBool(true, forKey: Keys.bookmarksEnabledPrefKey)
        profile.prefs.setBool(false, forKey: Keys.tabsEnabledPrefKey)

        let model = rustSyncManager.getEngineChoices(perDeviceSyncEnabled: false)

        XCTAssertEqual(model, .account(enabledChanges: [:]))
    }

    func testGetEngineChoices_withPerDeviceSyncDisabledAndRecentChanges_returnsAccountModelWithChanges() {
        profile.prefs.setBool(true, forKey: Keys.bookmarksStateChangedPrefKey)
        profile.prefs.setBool(true, forKey: Keys.bookmarksEnabledPrefKey)
        profile.prefs.setBool(true, forKey: Keys.tabsStateChangedPrefKey)
        profile.prefs.setBool(false, forKey: Keys.tabsEnabledPrefKey)
        profile.prefs.setBool(true, forKey: Keys.historyEnabledPrefKey)

        let model = rustSyncManager.getEngineChoices(perDeviceSyncEnabled: false)

        XCTAssertEqual(model, .account(enabledChanges: ["bookmarks": true, "tabs": false]))
    }

    func testGetEngineChoices_withPerDeviceSyncDisabledAndNewAccount_returnsAccountModelWithAllEngines() {
        UserDefaults.standard.set(["tabs", "creditcards"], forKey: "fxa.cwts.declinedSyncEngines")

        let model = rustSyncManager.getEngineChoices(perDeviceSyncEnabled: false)

        let expectedChanges = [
            "bookmarks": true,
            "creditcards": false,
            "history": true,
            "passwords": true,
            "tabs": false,
            "addresses": true
        ]
        XCTAssertEqual(model, .account(enabledChanges: expectedChanges))
    }

    func testGetEngineChoices_withPerDeviceSyncDisabledAndNewAccount_ignoresRecentChanges() {
        UserDefaults.standard.set(["tabs"], forKey: "fxa.cwts.declinedSyncEngines")
        profile.prefs.setBool(true, forKey: Keys.tabsStateChangedPrefKey)
        profile.prefs.setBool(true, forKey: Keys.tabsEnabledPrefKey)

        let model = rustSyncManager.getEngineChoices(perDeviceSyncEnabled: false)

        guard case .account(let enabledChanges) = model else {
            XCTFail("Expected account model")
            return
        }
        XCTAssertEqual(enabledChanges["tabs"], false)
        XCTAssertEqual(enabledChanges.count, 6)
    }

    func testGetEngineChoices_withNewAccount_doesNotClearDeclinedEngines() {
        UserDefaults.standard.set(["tabs"], forKey: "fxa.cwts.declinedSyncEngines")

        _ = rustSyncManager.getEngineChoices(perDeviceSyncEnabled: false)
        _ = rustSyncManager.getEngineChoices(perDeviceSyncEnabled: true)

        XCTAssertEqual(UserDefaults.standard.stringArray(forKey: "fxa.cwts.declinedSyncEngines"), ["tabs"])
    }

    func testApplyDeclinedEnginesIfNeeded_withDeclinedEngines_setsEnginePrefs() {
        UserDefaults.standard.set(["tabs", "creditcards"], forKey: "fxa.cwts.declinedSyncEngines")

        rustSyncManager.applyDeclinedEnginesIfNeeded()

        XCTAssertEqual(profile.prefs.boolForKey(Keys.tabsEnabledPrefKey), false)
        XCTAssertEqual(profile.prefs.boolForKey(Keys.creditcardsEnabledPrefKey), false)
        XCTAssertEqual(profile.prefs.boolForKey(Keys.bookmarksEnabledPrefKey), true)
        XCTAssertEqual(profile.prefs.boolForKey(Keys.historyEnabledPrefKey), true)
        XCTAssertEqual(profile.prefs.boolForKey(Keys.passwordsEnabledPrefKey), true)
        XCTAssertEqual(profile.prefs.boolForKey(Keys.addressesEnabledPrefKey), true)
    }

    func testApplyDeclinedEnginesIfNeeded_withEmptyDeclinedEngines_enablesAllEngines() {
        UserDefaults.standard.set([String](), forKey: "fxa.cwts.declinedSyncEngines")

        rustSyncManager.applyDeclinedEnginesIfNeeded()

        XCTAssertEqual(profile.prefs.boolForKey(Keys.tabsEnabledPrefKey), true)
        XCTAssertEqual(profile.prefs.boolForKey(Keys.creditcardsEnabledPrefKey), true)
        XCTAssertEqual(profile.prefs.boolForKey(Keys.bookmarksEnabledPrefKey), true)
        XCTAssertEqual(profile.prefs.boolForKey(Keys.historyEnabledPrefKey), true)
        XCTAssertEqual(profile.prefs.boolForKey(Keys.passwordsEnabledPrefKey), true)
        XCTAssertEqual(profile.prefs.boolForKey(Keys.addressesEnabledPrefKey), true)
    }

    func testApplyDeclinedEnginesIfNeeded_withoutDeclinedEngines_doesNotChangeEnginePrefs() {
        profile.prefs.setBool(false, forKey: Keys.bookmarksEnabledPrefKey)
        profile.prefs.setBool(true, forKey: Keys.tabsEnabledPrefKey)

        rustSyncManager.applyDeclinedEnginesIfNeeded()

        XCTAssertEqual(profile.prefs.boolForKey(Keys.bookmarksEnabledPrefKey), false)
        XCTAssertEqual(profile.prefs.boolForKey(Keys.tabsEnabledPrefKey), true)
        XCTAssertNil(profile.prefs.boolForKey(Keys.historyEnabledPrefKey))
        XCTAssertNil(profile.prefs.boolForKey(Keys.passwordsEnabledPrefKey))
        XCTAssertNil(profile.prefs.boolForKey(Keys.creditcardsEnabledPrefKey))
        XCTAssertNil(profile.prefs.boolForKey(Keys.addressesEnabledPrefKey))
    }

    func testApplyDeclinedEnginesIfNeeded_withDeclinedEngines_overwritesExistingEnginePrefs() {
        profile.prefs.setBool(true, forKey: Keys.tabsEnabledPrefKey)
        profile.prefs.setBool(false, forKey: Keys.bookmarksEnabledPrefKey)
        UserDefaults.standard.set(["tabs"], forKey: "fxa.cwts.declinedSyncEngines")

        rustSyncManager.applyDeclinedEnginesIfNeeded()

        XCTAssertEqual(profile.prefs.boolForKey(Keys.tabsEnabledPrefKey), false)
        XCTAssertEqual(profile.prefs.boolForKey(Keys.bookmarksEnabledPrefKey), true)
    }

    func testApplyDeclinedEnginesIfNeeded_withUnknownDeclinedEngine_ignoresIt() {
        UserDefaults.standard.set(["tabs", "unknownEngine"], forKey: "fxa.cwts.declinedSyncEngines")

        rustSyncManager.applyDeclinedEnginesIfNeeded()

        XCTAssertEqual(profile.prefs.boolForKey(Keys.tabsEnabledPrefKey), false)
        XCTAssertEqual(profile.prefs.boolForKey(Keys.bookmarksEnabledPrefKey), true)
        XCTAssertNil(profile.prefs.boolForKey("sync.engine.unknownEngine.enabled"))
    }

    func testApplyDeclinedEnginesIfNeeded_doesNotClearDeclinedEngines() {
        UserDefaults.standard.set(["tabs"], forKey: "fxa.cwts.declinedSyncEngines")

        rustSyncManager.applyDeclinedEnginesIfNeeded()

        XCTAssertEqual(UserDefaults.standard.stringArray(forKey: "fxa.cwts.declinedSyncEngines"), ["tabs"])
    }

    func testApplyDeclinedEnginesIfNeeded_doesNotChangeStateChangedPrefs() {
        profile.prefs.setBool(true, forKey: Keys.bookmarksStateChangedPrefKey)
        UserDefaults.standard.set(["tabs"], forKey: "fxa.cwts.declinedSyncEngines")

        rustSyncManager.applyDeclinedEnginesIfNeeded()

        XCTAssertEqual(profile.prefs.boolForKey(Keys.bookmarksStateChangedPrefKey), true)
        XCTAssertNil(profile.prefs.boolForKey(Keys.tabsStateChangedPrefKey))
    }

    func testUpdateEngineStateChangePrefsPostSync_clearsAllStateChangedPrefs() {
        profile.prefs.setBool(true, forKey: Keys.bookmarksStateChangedPrefKey)
        profile.prefs.setBool(true, forKey: Keys.historyStateChangedPrefKey)
        profile.prefs.setBool(true, forKey: Keys.tabsStateChangedPrefKey)
        profile.prefs.setBool(false, forKey: Keys.passwordsStateChangedPrefKey)
        profile.prefs.setBool(true, forKey: Keys.creditcardsStateChangedPrefKey)
        profile.prefs.setBool(false, forKey: Keys.addressesStateChangedPrefKey)

        rustSyncManager.updateEngineStateChangePrefsPostSync()

        XCTAssertNil(profile.prefs.boolForKey(Keys.bookmarksStateChangedPrefKey))
        XCTAssertNil(profile.prefs.boolForKey(Keys.historyStateChangedPrefKey))
        XCTAssertNil(profile.prefs.boolForKey(Keys.tabsStateChangedPrefKey))
        XCTAssertNil(profile.prefs.boolForKey(Keys.passwordsStateChangedPrefKey))
        XCTAssertNil(profile.prefs.boolForKey(Keys.creditcardsStateChangedPrefKey))
        XCTAssertNil(profile.prefs.boolForKey(Keys.addressesStateChangedPrefKey))
    }

    func testUpdateEngineStateChangePrefsPostSync_doesNotChangeEnabledPrefs() {
        profile.prefs.setBool(true, forKey: Keys.bookmarksStateChangedPrefKey)
        profile.prefs.setBool(true, forKey: Keys.bookmarksEnabledPrefKey)
        profile.prefs.setBool(true, forKey: Keys.tabsStateChangedPrefKey)
        profile.prefs.setBool(false, forKey: Keys.tabsEnabledPrefKey)

        rustSyncManager.updateEngineStateChangePrefsPostSync()

        XCTAssertEqual(profile.prefs.boolForKey(Keys.bookmarksEnabledPrefKey), true)
        XCTAssertEqual(profile.prefs.boolForKey(Keys.tabsEnabledPrefKey), false)
        XCTAssertNil(profile.prefs.boolForKey(Keys.historyEnabledPrefKey))
    }

    func testUpdateEngineStateChangePrefsPostSync_withNoStateChangedPrefs_leavesPrefsUnset() {
        rustSyncManager.updateEngineStateChangePrefsPostSync()

        XCTAssertNil(profile.prefs.boolForKey(Keys.bookmarksStateChangedPrefKey))
        XCTAssertNil(profile.prefs.boolForKey(Keys.historyStateChangedPrefKey))
        XCTAssertNil(profile.prefs.boolForKey(Keys.tabsStateChangedPrefKey))
        XCTAssertNil(profile.prefs.boolForKey(Keys.passwordsStateChangedPrefKey))
        XCTAssertNil(profile.prefs.boolForKey(Keys.creditcardsStateChangedPrefKey))
        XCTAssertNil(profile.prefs.boolForKey(Keys.addressesStateChangedPrefKey))
    }

    func testUpdateEngineStateChangePrefsPostSync_resetsEngineEnablementChanges() {
        profile.prefs.setBool(true, forKey: Keys.bookmarksStateChangedPrefKey)
        profile.prefs.setBool(true, forKey: Keys.bookmarksEnabledPrefKey)
        profile.prefs.setBool(true, forKey: Keys.tabsStateChangedPrefKey)
        profile.prefs.setBool(false, forKey: Keys.tabsEnabledPrefKey)
        XCTAssertEqual(rustSyncManager.getEngineEnablementChangesForAccount(), ["bookmarks": true, "tabs": false])

        rustSyncManager.updateEngineStateChangePrefsPostSync()

        XCTAssertTrue(rustSyncManager.getEngineEnablementChangesForAccount().isEmpty)
    }

    func testUpdateEngineStateChangePrefsPostSync_doesNotClearDeclinedEngines() {
        UserDefaults.standard.set(["tabs"], forKey: "fxa.cwts.declinedSyncEngines")

        rustSyncManager.updateEngineStateChangePrefsPostSync()

        XCTAssertEqual(UserDefaults.standard.stringArray(forKey: "fxa.cwts.declinedSyncEngines"), ["tabs"])
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

    func testCreateDeviceSettings_setsDeviceDetails() {
        let settings = rustSyncManager.createDeviceSettings(deviceId: "deviceId",
                                                            accountManager: makeAccountManager(),
                                                            perDeviceSyncEnabled: true)

        XCTAssertEqual(settings.fxaDeviceId, "deviceId")
        XCTAssertEqual(settings.name, "Test Device")
        XCTAssertEqual(settings.kind, .mobile)
    }

    func testCreateDeviceSettings_withPerDeviceSyncEnabledAndNoEnginePrefs_enablesAllEngines() {
        let settings = rustSyncManager.createDeviceSettings(deviceId: "deviceId",
                                                            accountManager: makeAccountManager(),
                                                            perDeviceSyncEnabled: true)

        XCTAssertEqual(Set(settings.enabledEngines), allEngines)
    }

    func testCreateDeviceSettings_withPerDeviceSyncEnabled_excludesDisabledEngines() {
        profile.prefs.setBool(true, forKey: Keys.bookmarksEnabledPrefKey)
        profile.prefs.setBool(false, forKey: Keys.tabsEnabledPrefKey)
        profile.prefs.setBool(false, forKey: Keys.passwordsEnabledPrefKey)

        let settings = rustSyncManager.createDeviceSettings(deviceId: "deviceId",
                                                            accountManager: makeAccountManager(),
                                                            perDeviceSyncEnabled: true)

        XCTAssertEqual(Set(settings.enabledEngines), ["bookmarks", "history", "creditcards", "addresses"])
    }

    func testCreateDeviceSettings_withPerDeviceSyncEnabledAfterApplyingDeclinedEngines_excludesDeclinedEngines() {
        UserDefaults.standard.set(["tabs", "creditcards"], forKey: "fxa.cwts.declinedSyncEngines")
        rustSyncManager.applyDeclinedEnginesIfNeeded()

        let settings = rustSyncManager.createDeviceSettings(deviceId: "deviceId",
                                                            accountManager: makeAccountManager(),
                                                            perDeviceSyncEnabled: true)

        XCTAssertEqual(Set(settings.enabledEngines), ["bookmarks", "history", "passwords", "addresses"])
    }

    func testCreateDeviceSettings_withPerDeviceSyncDisabledAndNoDeclinedEngines_usesEnginePrefs() {
        profile.prefs.setBool(true, forKey: Keys.bookmarksEnabledPrefKey)
        profile.prefs.setBool(false, forKey: Keys.tabsEnabledPrefKey)
        profile.prefs.setBool(false, forKey: Keys.historyEnabledPrefKey)

        let settings = rustSyncManager.createDeviceSettings(deviceId: "deviceId",
                                                            accountManager: makeAccountManager(),
                                                            perDeviceSyncEnabled: false)

        XCTAssertEqual(Set(settings.enabledEngines), ["bookmarks", "passwords", "creditcards", "addresses"])
    }

    func testCreateDeviceSettings_withPerDeviceSyncDisabledAndNoEnginePrefs_enablesAllEngines() {
        let settings = rustSyncManager.createDeviceSettings(deviceId: "deviceId",
                                                            accountManager: makeAccountManager(),
                                                            perDeviceSyncEnabled: false)

        XCTAssertEqual(Set(settings.enabledEngines), allEngines)
    }

    private let allEngines: Set<String> = ["bookmarks", "history", "tabs", "passwords", "creditcards", "addresses"]

    private func makeAccountManager() -> FxAccountManager {
        return FxAccountManager(
            config: FxAConfig(server: .release, clientId: "clientId", redirectUri: "redirectUri"),
            deviceConfig: DeviceConfig(name: "Test Device", deviceType: .mobile, capabilities: [])
        )
    }
}
