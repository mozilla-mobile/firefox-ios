// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// One real history visit exchanged with another browser: the visited URL, its title when known,
/// and the time of the visit. Aggregate counts are never expanded into extra visits.
///
/// Platform-independent counterpart of Apple's `BEBrowserDataHistoryVisit`.
/// https://developer.apple.com/documentation/browserkit/bebrowserdatahistoryvisit
///
/// Note: Not preserved from `BEBrowserDataHistoryVisit`: visit counts, redirect source and
/// destination, load success, and HTTP method.
public struct BrowserTransferHistoryVisit: Sendable, Equatable {
    public let url: URL
    public let title: String?
    /// A `Date`, like Apple's `dateOfLastVisit`. Storage.Places uses `Int64` milliseconds since 1970.
    public let visitDate: Date

    public init(url: URL, title: String?, visitDate: Date) {
        self.url = url
        self.title = title
        self.visitDate = visitDate
    }

    /// Creates a visit from a Places timestamp in milliseconds since 1970.
    public init(url: URL, title: String?, millisecondsSince1970: Int64) {
        self.init(url: url, title: title, visitDate: Date(timeIntervalSince1970: Double(millisecondsSince1970) / 1000))
    }

    /// The visit time as a Places timestamp in milliseconds since 1970. Dates before 1970 clamp to zero,
    /// and dates beyond the representable range clamp to the maximum.
    public var millisecondsSince1970: Int64 {
        let milliseconds = (visitDate.timeIntervalSince1970 * 1000).rounded()
        guard milliseconds > 0 else { return 0 }
        guard milliseconds < Double(Int64.max) else { return Int64.max }
        return Int64(milliseconds)
    }
}
