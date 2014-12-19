/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

typealias LogoutCallback = (profile: AccountProfile) -> ()

/**
 * A Profile manages access to the user's data.
 */
protocol Profile {
    var localName: String { get }

    var bookmarks: protocol<BookmarksModelFactory, ShareToDestination> { get }
    var favicons: Favicons { get }
    var clients: Clients { get }

    // Because we can't test for whether this is an AccountProfile.
    // TODO: probably Profile should own an Account.
    func logout()
}

protocol AccountProfile: Profile {
    var accountName: String { get }

    func basicAuthorizationHeader() -> String
    func makeAuthRequest(request: String, success: (data: AnyObject?) -> (), error: (error: RequestError) -> ())
}

class MockAccountProfile: AccountProfile {
    init() {
    }

    var localName: String {
        return "tester"
    }

    var accountName: String {
        return "tester@mozilla.org"
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

    func basicAuthorizationHeader() -> String {
        return ""
    }

    func makeAuthRequest(request: String, success: (data: AnyObject?) -> (), error: (error: RequestError) -> ()) {
    }

    func logout() {
    }
}

class RESTAccountProfile: AccountProfile {
    let credential: NSURLCredential
    private let logoutCallback: LogoutCallback

    init(credential: NSURLCredential, logoutCallback: LogoutCallback) {
        self.credential = credential
        self.logoutCallback = logoutCallback
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

    lazy var bookmarks: protocol<BookmarksModelFactory, ShareToDestination> = {
        // Stubbed out to populate data from server.
        // Eventually this will be a SyncingBookmarksModel or an OfflineBookmarksModel, perhaps.
        return BookmarksRESTModelFactory(profile: self)
    } ()

    lazy var clients: Clients = {
        return RESTClients(profile: self)
    } ()

    var localName: String {
        return "default"
    }

    var accountName: String {
        return credential.user!
    }

    //        lazy var ReadingList readingList
    //        lazy var History

    lazy var favicons: Favicons = {
        return BasicFavicons()
    }()
}
