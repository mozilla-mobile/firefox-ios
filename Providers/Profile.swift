/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Account
import ReadingList
import Shared
import Storage
import Sync

public class NoAccountError: SyncError {
    public var description: String {
        return "No account configured."
    }
}

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
    var prefs: Prefs { get }
    var searchEngines: SearchEngines { get }
    var files: FileAccessor { get }
    var history: History { get }
    var favicons: Favicons { get }
    var readingList: ReadingListService? { get }
    var passwords: Passwords { get }
    var thumbnails: Thumbnails { get }

    // I got really weird EXC_BAD_ACCESS errors on a non-null reference when I made this a getter.
    // Similar to <http://stackoverflow.com/questions/26029317/exc-bad-access-when-indirectly-accessing-inherited-member-in-swift>.
    func localName() -> String

    // URLs and account configuration.
    var accountConfiguration: FirefoxAccountConfiguration { get }

    func getAccount() -> FirefoxAccount?
    func setAccount(account: FirefoxAccount?)

    func getClients() -> Deferred<Result<[RemoteClient]>>
    func getClientsAndTabs() -> Deferred<Result<[ClientAndTabs]>>
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

    lazy var db: BrowserDB = {
        return BrowserDB(files: self.files)
    } ()

    lazy var bookmarks: protocol<BookmarksModelFactory, ShareToDestination> = {
        return BookmarksSqliteFactory(db: self.db)
    }()

    lazy var searchEngines: SearchEngines = {
        return SearchEngines(prefs: self.prefs)
    } ()

    func makePrefs() -> Prefs {
        return NSUserDefaultsProfilePrefs(profile: self)
    }

    lazy var favicons: Favicons = {
        return SQLiteFavicons(db: self.db)
    }()

    // lazy var ReadingList readingList

    lazy var prefs: Prefs = {
        return self.makePrefs()
    }()

    lazy var history: History = {
        return SQLiteHistory(db: self.db)
    }()

    lazy var readingList: ReadingListService? = {
        return ReadingListService(profileStoragePath: self.files.rootPath)
    }()

    private lazy var remoteClientsAndTabs: RemoteClientsAndTabs = {
        return SQLiteRemoteClientsAndTabs(db: self.db)
    }()

    private class func syncClientsToStorage(storage: RemoteClientsAndTabs, prefs: Prefs, ready: Ready) -> Deferred<Result<Ready>> {
        let clientSynchronizer = ready.synchronizer(ClientsSynchronizer.self, prefs: prefs)
        let success = clientSynchronizer.synchronizeLocalClients(storage, withServer: ready.client, info: ready.info)
        return success >>== always(ready)
    }

    public func getClients() -> Deferred<Result<[RemoteClient]>> {
        if let account = self.account {
            let authState = account.syncAuthState
            let syncPrefs = self.prefs.branch("sync")
            let storage = self.remoteClientsAndTabs

            let ready = SyncStateMachine.toReady(authState, prefs: syncPrefs)

            let syncClients = curry(BrowserProfile.syncClientsToStorage)(storage, syncPrefs)

            return ready
              >>== syncClients
               >>> { return storage.getClients() }
        }

        return deferResult(NoAccountError())
    }

    public func getClientsAndTabs() -> Deferred<Result<[ClientAndTabs]>> {

        func syncTabsToStorage(storage: RemoteClientsAndTabs, prefs: Prefs, ready: Ready) -> Deferred<Result<RemoteClientsAndTabs>> {
            let tabSynchronizer = ready.synchronizer(TabsSynchronizer.self, prefs: prefs)
            let success = tabSynchronizer.synchronizeLocalTabs(storage, withServer: ready.client, info: ready.info)
            return success >>== always(storage)
        }

        if let account = self.account {
            let authState = account.syncAuthState
            let syncPrefs = self.prefs.branch("sync")
            let storage = self.remoteClientsAndTabs

            let ready = SyncStateMachine.toReady(authState, prefs: syncPrefs)

            let syncClients = curry(BrowserProfile.syncClientsToStorage)(storage, syncPrefs)
            let syncTabs = curry(syncTabsToStorage)(storage, syncPrefs)

            return ready
              >>== syncClients
              >>== syncTabs
               >>> { return storage.getClientsAndTabs() }
        }

        return deferResult(NoAccountError())
    }

    lazy var passwords: Passwords = {
        return SQLitePasswords(db: self.db)
    }()

    lazy var thumbnails: Thumbnails = {
        return SDWebThumbnails(files: self.files)
    }()

    let accountConfiguration: FirefoxAccountConfiguration = ProductionFirefoxAccountConfiguration()

    private lazy var account: FirefoxAccount? = {
        if let dictionary = KeychainWrapper.objectForKey(self.name + ".account") as? [String: AnyObject] {
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
