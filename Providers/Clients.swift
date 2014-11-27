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

    /// Send a ShareItem to the specified clients.
    ///
    /// :param: item    the item to be sent
    /// :param: clients the clients that need to display the item
    ///
    /// The UX for the sharing dialog is incomplete. At this point sharing only
    /// works with a single destination client. That is why this code makes no
    /// effort to send to multiple clients. Multiple clients will also need
    /// a change in the REST API, since extensions can make only one final HTTP
    /// call when they finish.
    ///
    /// Note that this code currently uses NSURLSession directly because AlamoFire
    /// does not work from an Extension. (Bug 1104884)
    func sendItem(item: ExtensionUtils.ShareItem, toClients clients: [Client]) {
        if clients.count > 0 {
            let request = NSMutableURLRequest(URL: NSURL(string: "https://moz-syncapi.sateh.com/1.0/clients/\(clients[0].id)/tab")!)
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("application/json", forHTTPHeaderField: "Accept")
            request.HTTPMethod = "POST"
            
            var object = NSMutableDictionary()
            object["url"] = item.url
            object["title"] = item.title ?? ""
            
            var jsonError: NSError?
            let data = NSJSONSerialization.dataWithJSONObject(object, options: nil, error: &jsonError)
            if data != nil {
                request.HTTPBody = data
            }
            
            let configuration = NSURLSessionConfiguration.backgroundSessionConfigurationWithIdentifier("Clients/sendItem")
            configuration.HTTPAdditionalHeaders = ["Authorization" : account.basicAuthorizationHeader()]
            configuration.sharedContainerIdentifier = ExtensionUtils.sharedContainerIdentifier()
            
            let session = NSURLSession(configuration: configuration, delegate: nil, delegateQueue: nil)
            let task = session.dataTaskWithRequest(request)
            task.resume()
        }
    }
}