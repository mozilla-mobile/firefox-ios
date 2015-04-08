/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Account
import Foundation
import Storage
import Shared

class ProfileFileAccessor: FileAccessor {
    init(profile: Profile) {
        let profileDirName = "profile.\(profile.localName())"
        let manager = NSFileManager.defaultManager()
        // Bug 1147262: First option is for device, second is for simulator.
        let url =
            manager.containerURLForSecurityApplicationGroupIdentifier(ExtensionUtils.sharedContainerIdentifier()) ??
            manager .URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0] as? NSURL
        let profilePath = url!.path!.stringByAppendingPathComponent(profileDirName)
        super.init(rootPath: profilePath)
    }
}

/**
 * A Profile manages access to the user's data.
 */
protocol Profile {
    var bookmarks: protocol<BookmarksModelFactory, ShareToDestination> { get }
    // var favicons: Favicons { get }
    var clients: Clients { get }
    var prefs: Prefs { get }
    var searchEngines: SearchEngines { get }
    var files: FileAccessor { get }
    var history: History { get }
    var favicons: Favicons { get }
    var readingList: ReadingList { get }
    var remoteClientsAndTabs: RemoteClientsAndTabs { get }
    var passwords: Passwords { get }
    var thumbnails: Thumbnails { get }

    // I got really weird EXC_BAD_ACCESS errors on a non-null reference when I made this a getter.
    // Similar to <http://stackoverflow.com/questions/26029317/exc-bad-access-when-indirectly-accessing-inherited-member-in-swift>.
    func localName() -> String

    // URLs and account configuration.
    var accountConfiguration: FirefoxAccountConfiguration { get }

    func getAccount() -> FirefoxAccount?
    func setAccount(account: FirefoxAccount?)
}

public class MockProfile: Profile {
    private let name: String = "mockaccount"

    func localName() -> String {
        return name
    }

    lazy var bookmarks: protocol<BookmarksModelFactory, ShareToDestination> = {
        // Eventually this will be a SyncingBookmarksModel or an OfflineBookmarksModel, perhaps.
        return BookmarksSqliteFactory(files: self.files)
    } ()

    lazy var clients: Clients = {
        return MockClients(files: self.files)
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
        return SQLiteFavicons(files: self.files)
    }()

    lazy var history: History = {
        return SQLiteHistory(files: self.files)
    }()

    lazy var readingList: ReadingList = {
        return SQLiteReadingList(files: self.files)
    }()

    lazy var remoteClientsAndTabs: RemoteClientsAndTabs = {
        return SQLiteRemoteClientsAndTabs(files: self.files)
    }()

    lazy var passwords: Passwords = {
        return MockPasswords(files: self.files)
    }()

    lazy var thumbnails: Thumbnails = {
        return SDWebThumbnails(files: self.files)
    }()

    let accountConfiguration: FirefoxAccountConfiguration = LatestDevFirefoxAccountConfiguration()
    var account: FirefoxAccount? = nil

    func getAccount() -> FirefoxAccount? {
        return account
    }

    func setAccount(account: FirefoxAccount?) {
        self.account = account
    }
}

public class BrowserProfile: Profile {
    private let name: String

    init(localName: String) {
        self.name = localName

        let notificationCenter = NSNotificationCenter.defaultCenter()
        let mainQueue = NSOperationQueue.mainQueue()
        notificationCenter.addObserver(self, selector: Selector("onLocationChange:"), name: "LocationChange", object: nil)
    }

    @objc
    func onLocationChange(notification: NSNotification) {
        if let url = notification.userInfo!["url"] as? NSURL {
            var site: Site!
            if let title = notification.userInfo!["title"] as? NSString {
                site = Site(url: url.absoluteString!, title: title as String)
                let visit = Visit(site: site, date: NSDate())
                history.addVisit(visit, complete: { (success) -> Void in
                    // nothing to do
                })
            }
        }
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    func localName() -> String {
        return name
    }

    var files: FileAccessor {
        return ProfileFileAccessor(profile: self)
    }

    lazy var bookmarks: protocol<BookmarksModelFactory, ShareToDestination> = {
        return BookmarksSqliteFactory(files: self.files)
    }()

    lazy var searchEngines: SearchEngines = {
        return SearchEngines(prefs: self.prefs)
    } ()

    func makePrefs() -> Prefs {
        return NSUserDefaultsProfilePrefs(profile: self)
    }

    lazy var clients: Clients = {
        return MockClients(files: self.files)
    } ()

    lazy var favicons: Favicons = {
        return SQLiteFavicons(files: self.files)
    }()

    // lazy var ReadingList readingList

    lazy var prefs: Prefs = {
        return self.makePrefs()
    }()

    lazy var history: History = {
        return SQLiteHistory(files: self.files)
    }()

    lazy var readingList: ReadingList = {
        return SQLiteReadingList(files: self.files)
    }()

    lazy var remoteClientsAndTabs: RemoteClientsAndTabs = {
        // TODO: Sync!
        return SQLiteRemoteClientsAndTabs(files: self.files)
    }()

    lazy var passwords: Passwords = {
        return SQLitePasswords(files: self.files)
    }()

    lazy var thumbnails: Thumbnails = {
        return SDWebThumbnails(files: self.files)
    }()

    let accountConfiguration: FirefoxAccountConfiguration = LatestDevFirefoxAccountConfiguration()

    private lazy var account: FirefoxAccount? = {
        if let dictionary = KeychainWrapper.objectForKey(self.name + ".account") as? [String:AnyObject] {
            return FirefoxAccount.fromDictionary(dictionary)
        }
        return nil
    }()

    func getAccount() -> FirefoxAccount? {
        return account
    }

    func setAccount(account: FirefoxAccount?) {
        if account == nil {
            KeychainWrapper.removeObjectForKey(name + ".account")
        } else {
            KeychainWrapper.setObject(account!.asDictionary(), forKey: name + ".account")
        }
        self.account = account
    }
}
