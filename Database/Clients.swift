// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Alamofire

let SharedContainerIdentifier = "group.org.allizom.Client" // TODO: Can we grab this from the .entitlements file instead?

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
    
    class func sendURL(url: String, toClient client: Client) {
        let request = NSMutableURLRequest(URL: NSURL(string: "https://moz-syncapi.sateh.com/1.0/clients/" + client.id + "/tab")!)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.HTTPMethod = "POST"
        
        var object = NSMutableDictionary()
        object["url"] = url
        object["title"] = ""
        
        var jsonError: NSError?
        let data = NSJSONSerialization.dataWithJSONObject(object, options: nil, error: &jsonError)
        if data != nil {
            request.HTTPBody = data
        }
        
        let userPasswordString = "sarentz+syncapi@mozilla.com:q1w2e3r4"
        let userPasswordData = userPasswordString.dataUsingEncoding(NSUTF8StringEncoding)
        let base64EncodedCredential = userPasswordData!.base64EncodedStringWithOptions(nil)
        let authString = "Basic \(base64EncodedCredential)"
        
        let configuration = NSURLSessionConfiguration.backgroundSessionConfigurationWithIdentifier("org.allizom.Client.SendTo")
        configuration.HTTPAdditionalHeaders = ["Authorization" : authString]
        configuration.sharedContainerIdentifier = SharedContainerIdentifier
        
        let session = NSURLSession(configuration: configuration, delegate: nil, delegateQueue: nil)
        let task = session.dataTaskWithRequest(request)
        task.resume()
    }
};