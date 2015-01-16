/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

typealias LogoutCallback = (profile: AccountProfile) -> ()

/**
 * A Profile manages access to the user's data.
 */
protocol Profile {
    var bookmarks: protocol<BookmarksModelFactory, ShareToDestination> { get }
    var favicons: Favicons { get }
    var clients: Clients { get }
    var prefs: ProfilePrefs { get }
    var searchEngines: SearchEngines { get }
    var files: FileAccessor { get }
    var history: History { get }

    // Because we can't test for whether this is an AccountProfile.
    // TODO: probably Profile should own an Account.
    func logout()

    // I got really weird EXC_BAD_ACCESS errors on a non-null reference when I made this a getter.
    // Similar to <http://stackoverflow.com/questions/26029317/exc-bad-access-when-indirectly-accessing-inherited-member-in-swift>.
    func localName() -> String
}

protocol AccountProfile: Profile {
    var accountName: String { get }

    func basicAuthorizationHeader() -> String
    func makeAuthRequest(request: String, success: (data: AnyObject?) -> (), error: (error: RequestError) -> ())
}

public class MockAccountProfile: Profile, AccountProfile {
    private let name: String = "mockaccount"

    func localName() -> String {
        return name
    }

    var accountName: String {
        get {
            return "tester@mozilla.org"
        }
    }

    lazy var bookmarks: protocol<BookmarksModelFactory, ShareToDestination> = {
        // Eventually this will be a SyncingBookmarksModel or an OfflineBookmarksModel, perhaps.
        return MockMemoryBookmarksStore()
    } ()

    lazy var favicons: Favicons = {
        return BasicFavicons()
    } ()

    lazy var clients: Clients = {
        return MockClients(profile: self)
    } ()

    lazy var searchEngines: SearchEngines = {
        return SearchEngines()
    } ()

    lazy var prefs: ProfilePrefs = {
        return MockProfilePrefs()
    } ()

    lazy var files: FileAccessor = {
        return ProfileFileAccessor(profile: self)
    } ()

    func basicAuthorizationHeader() -> String {
        return ""
    }

    func makeAuthRequest(request: String, success: (data: AnyObject?) -> (), error: (error: RequestError) -> ()) {
        success(data: nil)
    }

    func logout() {
    }

    lazy var history: History = {
        return SqliteHistory(profile: self)
    }()

}

public class RESTAccountProfile: Profile, AccountProfile {
    private let name: String
    let credential: NSURLCredential

    private let logoutCallback: LogoutCallback

    init(localName: String, credential: NSURLCredential, logoutCallback: LogoutCallback) {
        self.name = localName
        self.credential = credential
        self.logoutCallback = logoutCallback

        let notificationCenter = NSNotificationCenter.defaultCenter()
        let mainQueue = NSOperationQueue.mainQueue()
        notificationCenter.addObserver(self, selector: Selector("onLocationChange:"), name: "LocationChange", object: nil)
    }

    @objc
    func onLocationChange(notification: NSNotification) {
        if let url = notification.userInfo!["url"] as? NSURL {
            if let title = notification.userInfo!["title"] as? NSString {
                history.addVisit(Site(url: url.absoluteString!, title: title), options: nil, complete: { (success) -> Void in
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

    var accountName: String {
        return credential.user!
    }

    var files: FileAccessor {
        return ProfileFileAccessor(profile: self)
    }

    func basicAuthorizationHeader() -> String {
        let userPasswordString = "\(credential.user!):\(credential.password!)"
        let userPasswordData = userPasswordString.dataUsingEncoding(NSUTF8StringEncoding)
        let base64EncodedCredential = userPasswordData!.base64EncodedStringWithOptions(nil)
        return "Basic \(base64EncodedCredential)"
    }

    func makeAuthRequest(request: String, success: (data: AnyObject?) -> (), error: (error: RequestError) -> ()) {
        RestAPI.sendRequest(
            credential,
            request: request,
            success: success,
            error: { err in
                if err == .BadAuth {
                    self.logout()
                }
                error(error: err)
        })
    }

    func logout() {
        logoutCallback(profile: self)
    }

    var _bookmarks: protocol<BookmarksModelFactory, ShareToDestination>? = nil
    var bookmarks: protocol<BookmarksModelFactory, ShareToDestination> {
        if (_bookmarks == nil) {
            // Stubbed out to populate data from server.
            // Eventually this will be a SyncingBookmarksModel or an OfflineBookmarksModel, perhaps.
            _bookmarks = BookmarksRESTModelFactory(profile: self)
        }
        return _bookmarks!
    }


    lazy var favicons: Favicons = {
        return BasicFavicons()
    } ()

    lazy var searchEngines: SearchEngines = {
        return SearchEngines()
    } ()

    func makePrefs() -> ProfilePrefs {
        return NSUserDefaultsProfilePrefs(profile: self)
    }

    var _clients: Clients? = nil
    var clients: Clients {
        if _clients == nil {
            _clients = RESTClients(profile: self)
        }
        return _clients!
    }

    // lazy var ReadingList readingList

    lazy var prefs: ProfilePrefs = {
        return self.makePrefs()
    }()

    lazy var history: History = {
        return SqliteHistory(profile: self)
    }()
}
