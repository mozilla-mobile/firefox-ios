// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public struct SponsoredSiteInfo: Equatable, Codable, Hashable {
    public let tileId: Int
    public let impressionURL: String
    public let clickURL: String
    public let imageURL: String

    public init(tileId: Int, impressionURL: String, clickURL: String, imageURL: String) {
        self.tileId = tileId
        self.impressionURL = impressionURL
        self.clickURL = clickURL
        self.imageURL = imageURL
    }
}
