// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

class Account {
    private let credential: NSURLCredential
    private let logoutCallback: () -> ()

    init(credential: NSURLCredential, logoutCallback: () -> ()) {
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
        logoutCallback()
    }

    lazy var bookmarks: Bookmarks = {
        return Bookmarks(account: self)
    } ()

    lazy var clients: Clients = {
        return Clients(account: self)
    } ()

    //        lazy var ReadingList readingList
    //        lazy var History history
    //        lazy var Favicons favicons;
}
