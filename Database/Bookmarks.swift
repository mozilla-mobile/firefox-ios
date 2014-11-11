//
//  BookmarksDB.swift
//  Client
//
//  Created by Wes Johnston on 11/5/14.
//  Copyright (c) 2014 Mozilla. All rights reserved.
//

import Foundation
import Alamofire

class Bookmark
{
    var title: String
    var url: String
    
    init(title: String, url: String) {
        self.title = title
        self.url = url
    }
}

class Bookmarks: NSObject {
    class func getAll(handler: ([Bookmark]) -> Void) {
        RestAPI.sendRequest("bookmarks/recent", callback: { (response: AnyObject?) -> Void in
            // TODO: We should cache these locally so that we don't have to query the server all the time
            handler(self.parseResponse(response));
        });
    }

    class func parseResponse(response: AnyObject?) -> [Bookmark] {
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
};