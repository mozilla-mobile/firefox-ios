/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
#if canImport(MozillaRustComponents)
    import MozillaRustComponents
#endif

/**
 Represents a set of properties which uniquely identify a history metadata. In database terms this is a compound key.
 */
public struct HistoryMetadataKey: Codable {
    public let url: String
    public let searchTerm: String?
    public let referrerUrl: String?

    public init(url: String, searchTerm: String?, referrerUrl: String?) {
        self.url = url
        self.searchTerm = searchTerm
        self.referrerUrl = referrerUrl
    }
}
