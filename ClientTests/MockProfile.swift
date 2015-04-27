/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Account
import ReadingList
import Shared
import Storage
import Sync
import XCTest

public class MockSyncManager: SyncManager {
    public func syncClients() -> Success { return succeed() }
    public func syncClientsAndTabs() -> Success { return succeed() }
    public func syncHistory() -> Success { return succeed() }
}

public class MockProfile: Profile {
    private let name: String = "mockaccount"

    func localName() -> String {
        return name
    }

    lazy var db: BrowserDB = {
        return BrowserDB(files: self.files)
    }()

    /**
     * Favicons, history, and bookmarks are all stored in one intermeshed
     * collection of tables.
     */
    private lazy var places: protocol<BrowserHistory, Favicons, SyncableHistory> = {
        return SQLiteHistory(db: self.db)
    }()

    var favicons: Favicons {
        return self.places
    }

    var history: protocol<BrowserHistory, SyncableHistory> {
        return self.places
    }

    lazy var syncManager: SyncManager = {
        return MockSyncManager()
    }()

    lazy var bookmarks: protocol<BookmarksModelFactory, ShareToDestination> = {
        return SQLiteBookmarks(db: self.db, favicons: self.places)
    }()

    lazy var searchEngines: SearchEngines = {
        return SearchEngines(prefs: self.prefs)
    }()

    lazy var prefs: Prefs = {
        return MockProfilePrefs()
    }()

    lazy var files: FileAccessor = {
        return ProfileFileAccessor(profile: self)
    }()

    lazy var readingList: ReadingListService? = {
        return ReadingListService(profileStoragePath: self.files.rootPath)
    }()

    private lazy var remoteClientsAndTabs: RemoteClientsAndTabs = {
        return SQLiteRemoteClientsAndTabs(db: self.db)
    }()

    lazy var passwords: Passwords = {
        return MockPasswords(files: self.files)
    }()

    lazy var thumbnails: Thumbnails = {
        return SDWebThumbnails(files: self.files)
    }()

    let accountConfiguration: FirefoxAccountConfiguration = ProductionFirefoxAccountConfiguration()
    var account: FirefoxAccount? = nil

    func getAccount() -> FirefoxAccount? {
        return account
    }

    func setAccount(account: FirefoxAccount?) {
        self.account = account
    }

    func getClients() -> Deferred<Result<[RemoteClient]>> {
        return deferResult([])
    }

    func getClientsAndTabs() -> Deferred<Result<[ClientAndTabs]>> {
        return deferResult([])
    }
}