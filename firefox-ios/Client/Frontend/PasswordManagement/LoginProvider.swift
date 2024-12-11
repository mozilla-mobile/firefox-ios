// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import MozillaAppServices
import Storage

protocol LoginProvider: AnyObject {
    func searchLoginsWithQuery(
        _ query: String?,
        completionHandler: @escaping (Result<[Login], Error>) -> Void)
    func addLogin(login: LoginEntry, completionHandler: @escaping (Result<Login?, Error>) -> Void)
}

extension RustLogins: LoginProvider {}
