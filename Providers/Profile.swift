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

public protocol SyncManager {
    func syncClients() -> Success
    func syncClientsAndTabs() -> Success
    func syncHistory() -> Success
    func onRemovedAccount(account: FirefoxAccount?) -> Success
    func onAddedAccount() -> Success
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
    func removeAccount()
    func setAccount(account: FirefoxAccount)

    func getClients() -> Deferred<Result<[RemoteClient]>>
    func getClientsAndTabs() -> Deferred<Result<[ClientAndTabs]>>

    var syncManager: SyncManager { get }
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

    lazy var syncManager: SyncManager = {
        return BrowserSyncManager(profile: self)
    }()

    private func getSyncDelegate() -> SyncDelegate {
        if let app = self.app {
            return BrowserProfileSyncDelegate(app: app)
        }
        return CommandDiscardingSyncDelegate()
    }

    public func getClients() -> Deferred<Result<[RemoteClient]>> {
        return self.syncManager.syncClients()
           >>> { self.remoteClientsAndTabs.getClients() }
    }

    public func getClientsAndTabs() -> Deferred<Result<[ClientAndTabs]>> {
        return self.syncManager.syncClientsAndTabs()
           >>> { self.remoteClientsAndTabs.getClientsAndTabs() }
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

    func removeAccount() {
        let old = self.account

        KeychainWrapper.removeObjectForKey(name + ".account")
        self.account = nil

        // Trigger cleanup. Pass in the account in case we want to try to remove
        // client-specific data from the server.
        self.syncManager.onRemovedAccount(old)
    }

    func setAccount(account: FirefoxAccount) {
        KeychainWrapper.setObject(account.asDictionary(), forKey: name + ".account")
        self.account = account

        self.syncManager.onAddedAccount()
    }

    class BrowserSyncManager: SyncManager {
        unowned private let profile: BrowserProfile

        init(profile: BrowserProfile) {
            self.profile = profile
        }

        var prefsForSync: Prefs {
            return self.profile.prefs.branch("sync")
        }

        func onAddedAccount() -> Success {
            return self.syncEverything()
        }

        func onRemovedAccount(account: FirefoxAccount?) -> Success {
            let h: SyncableHistory = self.profile.history
            let flagHistory = h.onRemovedAccount()
            let clearTabs = self.profile.remoteClientsAndTabs.onRemovedAccount()
            let done = allSucceed(flagHistory, clearTabs)

            // Clear prefs after we're done clearing everything else -- just in case
            // one of them needs the prefs and we race. Clear regardless of success
            // or failure.
            done.upon { result in
                // This will remove keys from the Keychain if they exist, as well
                // as wiping the Sync prefs.
                SyncStateMachine.clearStateFromPrefs(self.prefsForSync)
            }
            return done
        }

        private func syncClientsWithDelegate(delegate: SyncDelegate, prefs: Prefs, ready: Ready) -> Success {
            log.debug("Syncing clients to storage.")
            let clientSynchronizer = ready.synchronizer(ClientsSynchronizer.self, delegate: delegate, prefs: prefs)
            return clientSynchronizer.synchronizeLocalClients(self.profile.remoteClientsAndTabs, withServer: ready.client, info: ready.info)
        }

        private func syncTabsWithDelegate(delegate: SyncDelegate, prefs: Prefs, ready: Ready) -> Success {
            let storage = self.profile.remoteClientsAndTabs
            let tabSynchronizer = ready.synchronizer(TabsSynchronizer.self, delegate: delegate, prefs: prefs)
            return tabSynchronizer.synchronizeLocalTabs(storage, withServer: ready.client, info: ready.info)
        }

        private func syncHistoryWithDelegate(delegate: SyncDelegate, prefs: Prefs, ready: Ready) -> Success {
            log.debug("Syncing history to storage.")
            let historySynchronizer = ready.synchronizer(HistorySynchronizer.self, delegate: delegate, prefs: prefs)
            return historySynchronizer.synchronizeLocalHistory(self.profile.history, withServer: ready.client, info: ready.info)
        }

        func ignoreContinuableErrorInDeferred(deferred: Success) -> Success {
            return deferred.bind() { result in
                if let failure = result.failureValue where failure is ContinuableError {
                    log.debug("Got continuable error \(failure); pretending that nothing failed.")
                    return succeed()
                }
                return deferred
            }
        }

        func doSync(label: String, synchronizers: (SyncDelegate, Prefs, Ready) -> Success ...) -> Success {
            if let account = profile.account {
                log.info("Syncing \(label).")

                let authState = account.syncAuthState
                let syncPrefs = profile.prefs.branch("sync")

                let readyDeferred = SyncStateMachine.toReady(authState, prefs: syncPrefs)
                let delegate = profile.getSyncDelegate()

                // Run them sequentially, ignoring continuable errors.
                // TODO: find a better way to do this. We want to report if tab sync is disabled, for
                // example.
                return readyDeferred >>== { ready in
                    let tasks = synchronizers.map { f in
                        { self.ignoreContinuableErrorInDeferred(f(delegate, syncPrefs, ready)) }
                    }

                    return walk(tasks, { $0() })
                }
            }

            log.warning("No account; can't sync \(label).")
            return deferResult(NoAccountError())
        }

        func syncEverything() -> Success {
            return self.doSync("everything", synchronizers:
                self.syncClientsWithDelegate,
                self.syncTabsWithDelegate,
                self.syncHistoryWithDelegate)
        }

        func syncClients() -> Success {
            return self.doSync("clients", synchronizers: syncClientsWithDelegate)
        }

        func syncClientsAndTabs() -> Success {
            return self.doSync("clients and tabs", synchronizers: self.syncClientsWithDelegate, self.syncTabsWithDelegate)
        }

        func syncHistory() -> Success {
            return self.doSync("history", synchronizers: syncHistoryWithDelegate)
        }
    }
}
