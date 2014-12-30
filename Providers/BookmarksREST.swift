/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Alamofire

public class BookmarksRESTModelFactory: BookmarksModelFactory, ShareToDestination {
    private let profile: RESTAccountProfile
    private let sink: MemoryBookmarksSink = MemoryBookmarksSink()

    init(profile: RESTAccountProfile) {
        self.profile = profile
    }

    func modelForFolder(folder: BookmarkFolder, success: (BookmarksModel) -> (), failure: (Any) -> ()) {
        failure("Not supported")
    }

    func modelForFolder(guid: String, success: (BookmarksModel) -> (), failure: (Any) -> ()) {
        failure("Not supported")
    }


    func modelForRoot(success: (BookmarksModel) -> (), failure: (Any) -> ()) {
        self.profile.makeAuthRequest(
            "bookmarks/recent",
            success: { data in
                success(self.parseResponse(data))
            },
            error: { error in
                // TODO
                failure(error)
        })
    }

    // Return synchronously to allow for init. You can asynchronously reinit through the returned model.
    // Better would be for the view controller to be prepared for this to arrive later.
    var nullModel: BookmarksModel {
        let f = MemoryBookmarkFolder(id: "stub", name: "", children: [])
        return BookmarksModel(modelFactory: self, root: f)
    }

    func parseResponse(response: AnyObject?) -> BookmarksModel {
        var resp : [BookmarkItem] = [];

        if let response: NSArray = response as? NSArray {
            for bookmark in response {
                var title: String = ""
                var url: String = ""
                var guid: String

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

                if let id = bookmark.valueForKey("id") as? String {
                    guid = id
                } else {
                    continue;
                }

                resp.append(BookmarkItem(id: guid, title: title, url: url))
            }
        }

        let f = MemoryBookmarkFolder(id: "unsorted", name: "Unsorted", children: resp)
        return BookmarksModel(modelFactory: self, root: f)
    }

    // Don't do uploading yet. We want to exercise merging.
    func shareItem(item: ShareItem) {
        sink.shareItem(item)
    }
}

/**
 * Send a ShareItem to this user's bookmarks
 *
 * Note that this code currently uses NSURLSession directly because AlamoFire
 * does not work from an Extension. (Bug 1104884)
 *
 * Note that the bookmark will end up in Unsorted Bookmarks. We have Bug
 * 1094233 open for the REST API to store the incoming item in the Mobile
 * Bookmarks instead.
 *
 * Eventually this code will go away altogether as we talk directly to Sync.
 */
func sendBookmarkREST(profile: RESTAccountProfile, item: BookmarkItem) {
    let request = NSMutableURLRequest(URL: NSURL(string: "https://moz-syncapi.sateh.com/1.0/bookmarks")!)
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    request.addValue("application/json", forHTTPHeaderField: "Accept")
    request.HTTPMethod = "POST"

    var object = NSMutableDictionary()
    object["url"] = item.url
    object["title"] = item.title

    var jsonError: NSError?
    let data = NSJSONSerialization.dataWithJSONObject(object, options: nil, error: &jsonError)
    if data != nil {
        request.HTTPBody = data
    }

    let configuration = NSURLSessionConfiguration.backgroundSessionConfigurationWithIdentifier("Bookmarks/shareItem")
    configuration.HTTPAdditionalHeaders = ["Authorization" : profile.basicAuthorizationHeader()]
    configuration.sharedContainerIdentifier = ExtensionUtils.sharedContainerIdentifier()

    let session = NSURLSession(configuration: configuration, delegate: nil, delegateQueue: nil)
    let task = session.dataTaskWithRequest(request)
    task.resume()
}
