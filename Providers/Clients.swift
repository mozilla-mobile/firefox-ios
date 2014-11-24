// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Alamofire

class Client {
    var id: String
    var name: String
    
    init(id: String, name: String) {
        self.id = id
        self.name = name
    }
}

class Clients: NSObject {
    private let account: Account

    init(account: Account) {
        self.account = account
    }

    func getAll(success: ([Client]) -> (), error: (RequestError) -> ()) {
        account.makeAuthRequest(
            "clients",
            success: { data in
                success(self.parseResponse(data));
            },
            error: error)
    }

    private func parseResponse(response: AnyObject?) -> [Client] {
        var resp : [Client] = [];

        if let response: NSArray = response as? NSArray {
            for client in response {
                var id: String = ""
                var name: String = ""

                if let t = client.valueForKey("id") as? String {
                    id = t
                } else {
                    continue;
                }

                if let t = client.valueForKey("name") as? String {
                    name = t
                } else {
                    continue;
                }

                resp.append(Client(id: id, name: name))
            }
        }

        return resp;
    }

    class func sendItem(item: ShareItem, toClients clients: [Client]) {
        for client in clients {
            println("TODO Sending \(item.url) to \(client.name)")
        }
    }
};