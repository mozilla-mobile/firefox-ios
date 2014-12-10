// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Alamofire

class Bookmark {
    var title: String
    var url: String

    init(title: String, url: String) {
        self.title = title
        self.url = url
    }
}

class TestBookmarksProvider : BookmarksREST {
    override func getAll(success: ([Bookmark]) -> (), error: (RequestError) -> ()) {
        var res = [Bookmark]()
        for i in 0...10 {
            var b = Bookmark(title: "Title \(i)", url: "http://www.example.com/\(i)")
            res.append(b)
        }
        success(res)
    }
}

class BookmarksREST: NSObject {
    private let account: Account

    init(account: Account) {
        self.account = account
    }

    func getAll(success: ([Bookmark]) -> (), error: (RequestError) -> ()) {
        account.makeAuthRequest(
            "bookmarks/recent",
            success: { data in
                 success(self.parseResponse(data));
            },
            error: error)
    }

    private func parseResponse(response: AnyObject?) -> [Bookmark] {
        var resp : [Bookmark] = [];

        if let response: NSArray = response as? NSArray {
            for bookmark in response {
                var title: String = ""
                var url: String = ""

                if let t = bookmark.valueForKey("title") as? String {
                    title = t
                } else {
                    continue;
                }

                if let u = bookmark.valueForKey("bmkUri") as? String {
                    url = u
                } else {
                    continue;
                }

                resp.append(Bookmark(title: title, url: url))
            }
        }

        return resp;
    }
    
    /// Send a ShareItem to this user's bookmarks
    ///
    /// :param: item    the item to be sent
    ///
    /// Note that this code currently uses NSURLSession directly because AlamoFire
    /// does not work from an Extension. (Bug 1104884)
    ///
    /// Note that the bookmark will end up in the Unsorted Bookmarks. We have Bug
    /// 1094233 open for the REST API to store the incoming item in the Mobile
    /// Bookmarks instead.
    
    func shareItem(item: ExtensionUtils.ShareItem) {
        let request = NSMutableURLRequest(URL: NSURL(string: "https://moz-syncapi.sateh.com/1.0/bookmarks")!)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.HTTPMethod = "POST"
        
        var object = NSMutableDictionary()
        object["url"] = item.url
        object["title"] = item.title == nil ? "" : item.title
        
        var jsonError: NSError?
        let data = NSJSONSerialization.dataWithJSONObject(object, options: nil, error: &jsonError)
        if data != nil {
            request.HTTPBody = data
        }
        
        let configuration = NSURLSessionConfiguration.backgroundSessionConfigurationWithIdentifier("Bookmarks/shareItem")
        configuration.HTTPAdditionalHeaders = ["Authorization" : account.basicAuthorizationHeader()]
        configuration.sharedContainerIdentifier = ExtensionUtils.sharedContainerIdentifier()
        
        let session = NSURLSession(configuration: configuration, delegate: nil, delegateQueue: nil)
        let task = session.dataTaskWithRequest(request)
        task.resume()
    }
}
