// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Alamofire

class Client {
    var id: String!
    var name: String!
    
    init(id: String, name: String) {
        self.id = id
        self.name = name
    }
    
    init?(fromJSON dict: NSDictionary) {
        if let id = dict.valueForKey("id") as? String {
            if let name = dict.valueForKey("name") as? String {
                self.id = id
                self.name = name
                return
            }
        }
        return nil
    }
}

class Clients: NSObject {
    class func getAll(handler: ([Client]) -> Void) {
        RestAPI.sendRequest("clients", callback: { (response: AnyObject?) -> Void in
            // TODO: We should cache these locally so that we don't have to query the server all the time
            handler(self.parseResponse(response));
        });
    }
    
    class func parseResponse(response: AnyObject?) -> [Client] {
        var resp : [Client] = [];
        
        if let response: NSArray = response as? NSArray {
            for dict in response as [NSDictionary] {
                if let client = Client(fromJSON: dict) {
                    resp.append(client)
                }
            }
        }
        
        return resp;
    }
};