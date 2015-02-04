/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Alamofire
import Storage

class Client {
    var id: String
    var name: String
    
    init(id: String, name: String) {
        self.id = id
        self.name = name
    }
}

protocol Clients {
    func getAll(success: ([Client]) -> (), error: (RequestError) -> ())
    func sendItem(item: ShareItem, toClients clients: [Client])
}

class MockClients: Clients {
    private let profile: Profile

    init(profile: Profile) {
        self.profile = profile
    }

    func getAll(success: ([Client]) -> (), error: (RequestError) -> ()) {
        success([])
    }

    func sendItem(item: ShareItem, toClients clients: [Client]) {
    }
}
