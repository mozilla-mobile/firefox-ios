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

public class MockProfile: Profile {
    private let name: String = "mockaccount"

    func localName() -> String {
        return name
    }

    lazy var db: BrowserDB = {
        return BrowserDB(files: self.files)
    } ()

    lazy var bookmarks: protocol<BookmarksModelFactory, ShareToDestination> = {
        // Eventually this will be a SyncingBookmarksModel or an OfflineBookmarksModel, perhaps.
        return BookmarksSqliteFactory(db: self.db)
        } ()

    lazy var searchEngines: SearchEngines = {
        return SearchEngines(prefs: self.prefs)
        } ()

    lazy var prefs: Prefs = {
        return MockProfilePrefs()
        } ()

    lazy var files: FileAccessor = {
        return ProfileFileAccessor(profile: self)
        } ()

    lazy var favicons: Favicons = {
        return SQLiteFavicons(db: self.db)
        }()

    lazy var history: BrowserHistory = {
        return SQLiteHistory(db: self.db)
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