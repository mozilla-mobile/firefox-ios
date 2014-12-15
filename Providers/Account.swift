// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

typealias LogoutCallback = (account: Account) -> ()

protocol Account {
    var user: String { get }
    func logout()
    func basicAuthorizationHeader() -> String
    func makeAuthRequest(request: String, success: (data: AnyObject?) -> (), error: (error: RequestError) -> ())
    var bookmarks: protocol<BookmarksModelFactory, ShareToDestination> { get }
    var clients: Clients { get }
}

class MockAccount: Account {
    init() {
    }

    var user: String {
        return "tester"
    }

    lazy var bookmarks: protocol<BookmarksModelFactory, ShareToDestination> = {
        // Eventually this will be a SyncingBookmarksModel or an OfflineBookmarksModel, perhaps.
        return MockMemoryBookmarksStore()
    } ()

    lazy var clients: Clients = {
        return Clients(account: self)
    } ()

    func basicAuthorizationHeader() -> String {
        return ""
    }

    func makeAuthRequest(request: String, success: (data: AnyObject?) -> (), error: (error: RequestError) -> ()) {
    }

    func logout() {
    }
}

class RESTAccount: Account {
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
        logoutCallback(account: self)
    }

    lazy var bookmarks: protocol<BookmarksModelFactory, ShareToDestination> = {
        // Stubbed out to populate data from server.
        // Eventually this will be a SyncingBookmarksModel or an OfflineBookmarksModel, perhaps.
        return BookmarksRESTModelFactory(account: self)
    } ()

    lazy var clients: Clients = {
        return Clients(account: self)
    } ()

    var user: String {
        return credential.user!
    }

    //        lazy var ReadingList readingList
    //        lazy var History history
    //        lazy var Favicons favicons;
}
