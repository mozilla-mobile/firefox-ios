// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UIKit

import enum MozillaAppServices.Suggestion

/// Additional information about a Firefox Suggestion to record
/// in telemetry when the user interacts with the suggestion
public enum RustFirefoxSuggestionTelemetryInfo {
    case amp(
        blockId: Int64,
        advertiser: String,
        iabCategory: String,
        impressionReportingURL: URL?,
        clickReportingURL: URL?
    )
    case wikipedia
}
/// A Firefox Suggest search suggestion. This struct is a Swiftier
/// representation of the Rust `Suggestion` enum.
public struct RustFirefoxSuggestion: Equatable {
    public static func == (lhs: RustFirefoxSuggestion, rhs: RustFirefoxSuggestion) -> Bool {
        return lhs.title == rhs.title &&
        lhs.url == rhs.url &&
        lhs.isSponsored == rhs.isSponsored &&
        lhs.iconImage == rhs.iconImage
    }

    public let title: String
    public let url: URL
    public let isSponsored: Bool
    public let iconImage: UIImage?
    public let telemetryInfo: RustFirefoxSuggestionTelemetryInfo?

    public init(title: String, url: URL, isSponsored: Bool, iconImage: UIImage?) {
        self.title = title
        self.url = url
        self.isSponsored = isSponsored
        self.iconImage = iconImage
        self.telemetryInfo = nil
    }

    internal init?(_ suggestion: Suggestion) {
        // This code is intentionally written as a chain of `if-case-let`s
        // instead of a `switch`, because we don't want new `Suggestion` cases
        // added in Rust to be source-breaking changes in Firefox. A `switch`
        // with a `default` or `@unknown default` case would emit a "default
        // will never be executed" warning, because Swift treats `Suggestion`
        // as frozen, since we can't build Application Services with library
        // evolution support.
        if case let .amp(
            title,
            urlString,
            _,
            iconBytes,
            _,
            _,
            blockId,
            advertiser,
            iabCategory,
            impressionUrlString,
            clickUrlString,
            _,
            _
        ) = suggestion {
            // This use of `URL(string:)` is OK; we don't need to use
            // `URL(string:encodingInvalidCharacters:)` here.
            guard let url = URL(string: urlString) else { return nil }
            self.title = title
            self.url = url
            self.isSponsored = true
            self.iconImage = iconBytes.flatMap { UIImage(data: Data($0)) }
            self.telemetryInfo = .amp(
                blockId: blockId,
                advertiser: advertiser.lowercased(),
                iabCategory: iabCategory,
                impressionReportingURL: URL(string: impressionUrlString),
                clickReportingURL: URL(string: clickUrlString)
            )
        } else if case let .wikipedia(title, urlString, iconBytes, _, _) = suggestion {
            // This use of `URL(string:)` is OK.
            guard let url = URL(string: urlString) else { return nil }
            self.title = title
            self.url = url
            self.isSponsored = false
            self.iconImage = iconBytes.flatMap { UIImage(data: Data($0)) }
            self.telemetryInfo = .wikipedia
        } else {
            return nil
        }
    }
}
