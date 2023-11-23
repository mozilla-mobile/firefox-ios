// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/*
 The Pocket class is used to fetch stories from the Pocked API.
 Right now this only supports the global feed

 For a sample feed item check ClientTests/pocketglobalfeed.json
 */

struct PocketFeedStory {
    let title: String
    let url: URL
    let domain: String
    let timeToRead: Int64?
    let storyDescription: String
    let imageURL: URL

    static func parseJSON(list: [[String: Any]]) -> [PocketFeedStory] {
        return list.compactMap({ (storyDict) -> PocketFeedStory? in
            guard let urlS = storyDict["url"] as? String,
                  let domain = storyDict["domain"] as? String,
                  let imageURLS = storyDict["image_src"] as? String,
                  let title = storyDict["title"] as? String,
                  let description = storyDict["excerpt"] as? String else {
                      return nil
                  }

            guard let url = URL(string: urlS, invalidCharacters: false),
                  let imageURL = URL(string: imageURLS, invalidCharacters: false)
            else { return nil }

            return PocketFeedStory(
                title: title,
                url: url,
                domain: domain,
                timeToRead: storyDict["time_to_read"] as? Int64,
                storyDescription: description,
                imageURL: imageURL
            )
        })
    }
}
