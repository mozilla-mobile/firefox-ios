/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Account
import ReadingList
import Shared
import Storage
import Sync
import XCGLogger

// TODO: same comment as for SyncAuthState.swift!
private let log = XCGLogger.defaultInstance()

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

class CommandDiscardingSyncDelegate: SyncDelegate {
    func displaySentTabForURL(URL: NSURL, title: String) {
        // TODO: do something else.
        log.info("Discarding sent URL \(URL.absoluteString)")
    }
}

/**
 * This exists because the Sync code is extension-safe, and thus doesn't get
 * direct access to UIApplication.sharedApplication, which it would need to
 * display a notification.
 * This will also likely be the extension point for wipes, resets, and
 * getting access to data sources during a sync.
 */
class BrowserProfileSyncDelegate: SyncDelegate {
    let app: UIApplication

    init(app: UIApplication) {
        self.app = app
    }

    // SyncDelegate
    func displaySentTabForURL(URL: NSURL, title: String) {
        log.info("Displaying notification for URL \(URL.absoluteString)")

        app.registerUserNotificationSettings(UIUserNotificationSettings(forTypes: UIUserNotificationType.Alert, categories: nil))
        app.registerForRemoteNotifications()

        // TODO: localize.
        let notification = UILocalNotification()

        /* actions
        notification.identifier = "tab-" + Bytes.generateGUID()
        notification.activationMode = UIUserNotificationActivationMode.Foreground
        notification.destructive = false
        notification.authenticationRequired = true
        */

        notification.alertTitle = "New tab: \(title)"
        notification.alertBody = URL.absoluteString!
        notification.alertAction = nil

        // TODO: categories
        // TODO: put the URL into the alert userInfo.
        // TODO: application:didFinishLaunchingWithOptions:
        // TODO:
        // TODO: set additionalActions to bookmark or add to reading list.
        self.app.presentLocalNotificationNow(notification)
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
    var history: protocol<BrowserHistory, SyncableHistory> { get }
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
    weak private var app: UIApplication?

    init(localName: String, app: UIApplication?) {
        self.name = localName
        self.app = app

        let notificationCenter = NSNotificationCenter.defaultCenter()
        let mainQueue = NSOperationQueue.mainQueue()
        notificationCenter.addObserver(self, selector: Selector("onLocationChange:"), name: "LocationChange", object: nil)
    }

    // Extensions don't have a UIApplication.
    convenience init(localName: String) {
        self.init(localName: localName, app: nil)
    }

    @objc
    func onLocationChange(notification: NSNotification) {
        if let v = notification.userInfo!["visitType"] as? Int,
           let visitType = VisitType(rawValue: v),
           let url = notification.userInfo!["url"] as? NSURL,
           let title = notification.userInfo!["title"] as? NSString {

            // We don't record a visit if no type was specified -- that means "ignore me".
            let site = Site(url: url.absoluteString!, title: title as String)
            let visit = SiteVisit(site: site, date: NSDate.nowMicroseconds(), type: visitType)
            log.debug("Recording visit for \(url) with type \(v).")
            history.addLocalVisit(visit)
        } else {
            let url = notification.userInfo!["url"] as? NSURL
            log.debug("Ignoring navigation for \(url).")
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

    lazy var bookmarks: protocol<BookmarksModelFactory, ShareToDestination> = {
        return SQLiteBookmarks(db: self.db, favicons: self.places)
    }()

    lazy var searchEngines: SearchEngines = {
        return SearchEngines(prefs: self.prefs)
    }()

    func makePrefs() -> Prefs {
        return NSUserDefaultsPrefs(prefix: self.localName())
    }

    lazy var prefs: Prefs = {
        return self.makePrefs()
    }()


    lazy var readingList: ReadingListService? = {
        return ReadingListService(profileStoragePath: self.files.rootPath)
    }()

    private lazy var remoteClientsAndTabs: RemoteClientsAndTabs = {
        return SQLiteRemoteClientsAndTabs(db: self.db)
    }()

    private class func syncClientsToStorage(storage: RemoteClientsAndTabs, delegate: SyncDelegate, prefs: Prefs, ready: Ready) -> Deferred<Result<Ready>> {
        log.debug("Syncing clients to storage.")
        let clientSynchronizer = ready.synchronizer(ClientsSynchronizer.self, delegate: delegate, prefs: prefs)
        let success = clientSynchronizer.synchronizeLocalClients(storage, withServer: ready.client, info: ready.info)
        return success >>== always(ready)
    }

    private class func syncTabsToStorage(storage: RemoteClientsAndTabs, delegate: SyncDelegate, prefs: Prefs, ready: Ready) -> Deferred<Result<RemoteClientsAndTabs>> {
        let tabSynchronizer = ready.synchronizer(TabsSynchronizer.self, delegate: delegate, prefs: prefs)
        let success = tabSynchronizer.synchronizeLocalTabs(storage, withServer: ready.client, info: ready.info)
        return success >>== always(storage)
    }

    private func getSyncDelegate() -> SyncDelegate {
        if let app = self.app {
            return BrowserProfileSyncDelegate(app: app)
        }
        return CommandDiscardingSyncDelegate()
    }

    public func getClients() -> Deferred<Result<[RemoteClient]>> {
        if let account = self.account {
            let authState = account.syncAuthState

            let syncPrefs = self.prefs.branch("sync")
            let storage = self.remoteClientsAndTabs

            let ready = SyncStateMachine.toReady(authState, prefs: syncPrefs)

            let delegate = self.getSyncDelegate()
            let syncClients = curry(BrowserProfile.syncClientsToStorage)(storage, delegate, syncPrefs)

            return ready
              >>== syncClients
               >>> { return storage.getClients() }
        }

        log.warning("No account; can't fetch clients.")
        return deferResult(NoAccountError())
    }

    public func getClientsAndTabs() -> Deferred<Result<[ClientAndTabs]>> {
        log.info("Account is \(self.account), app is \(self.app)")

        if let account = self.account {
            log.debug("Fetching clients and tabs.")

            let authState = account.syncAuthState
            let syncPrefs = self.prefs.branch("sync")
            let storage = self.remoteClientsAndTabs

            let ready = SyncStateMachine.toReady(authState, prefs: syncPrefs)

            let delegate = self.getSyncDelegate()
            let syncClients = curry(BrowserProfile.syncClientsToStorage)(storage, delegate, syncPrefs)
            let syncTabs = curry(BrowserProfile.syncTabsToStorage)(storage, delegate, syncPrefs)

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
