/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

typealias LogoutCallback = (profile: AccountProfile) -> ()

/**
 * A Profile manages access to the user's data.
 */
public protocol Profile {
    var bookmarks: protocol<BookmarksModelFactory, ShareToDestination> { get }
    var favicons: Favicons { get }
    var clients: Clients { get }
    var prefs: ProfilePrefs { get }
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

    public func localName() -> String {
        return name
    }

    public var accountName: String {
        get {
            return "tester@mozilla.org"
        }
    }

    public var history: History {
        return SqliteHistory(profile: self)
    }
    public var bookmarks: protocol<BookmarksModelFactory, ShareToDestination> { return MockMemoryBookmarksStore() }
    public var favicons: Favicons  { return BasicFavicons() }
    public var clients: Clients    { return MockClients(profile: self) }
    lazy public var prefs: ProfilePrefs = {
        return MockProfilePrefs()
    }()
    public var files: FileAccessor { return ProfileFileAccessor(profile: self) }

    public func logout() { }

    func basicAuthorizationHeader() -> String { return "" }
    func makeAuthRequest(request: String, success: (data: AnyObject?) -> (), error: (error: RequestError) -> ()) {
        success(data: nil)
    }

}

public class RESTAccountProfile: Profile, AccountProfile {
    var accountName: String { return credential.user! }
    let name: String
    let credential: NSURLCredential
    public func localName() -> String { return name }
    private let logoutCallback: LogoutCallback

    // Eventually this will be a SyncingBookmarksModel or an OfflineBookmarksModel, perhaps.
    lazy public var bookmarks: protocol<BookmarksModelFactory, ShareToDestination> = { return MockMemoryBookmarksStore() }()
    lazy public var history: History = { return SqliteHistory(profile: self) }()
    lazy public var prefs: ProfilePrefs = { return NSUserDefaultsProfilePrefs(profile: self) }()
    lazy public var favicons: Favicons = { return BasicFavicons() }()
    lazy public var clients: Clients = { return RESTClients(profile: self) }()
    lazy public var files: FileAccessor = { return ProfileFileAccessor(profile: self) }()
    // lazy var ReadingList readingList

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
                println("on location change \(url) \(title)")
                history.addVisit(Site(url: url.absoluteString!, title: title), options: nil, complete: { (success) -> Void in
                    // nothing to do
                    println("stored = \(success)")
                })
            }
        }
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
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

    public func logout() {
        logoutCallback(profile: self)
    }
}
