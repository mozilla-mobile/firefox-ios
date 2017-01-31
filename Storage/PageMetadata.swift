/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

/*
 * Value types representing a page's metadata
 */
public struct PageMetadata {
    public let id: Int?
    public let siteURL: String
    public let mediaURL: String?
    public let title: String?
    public let description: String?
    public let type: String?
    public let providerName: String?

    public init(id: Int?, siteURL: String, mediaURL: String?, title: String?, description: String?, type: String?, providerName: String?) {
        self.id = id
        self.siteURL = siteURL
        self.mediaURL = mediaURL
        self.title = title
        self.description = description
        self.type = type
        self.providerName = providerName
    }

    public static func fromDictionary(_ dict: [String: Any]) -> PageMetadata? {
        guard let siteURL = dict["url"] as? String else {
            return nil
        }

        return PageMetadata(id: nil, siteURL: siteURL, mediaURL: dict["image_url"] as? String,
                            title: dict["title"] as? String, description: dict["description"] as? String,
                            type: dict["type"] as? String, providerName: dict["provider_name"] as? String)
    }
}
