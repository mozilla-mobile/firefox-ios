// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Issue categories for the "Report a Website Issue" form. Raw values and
/// `subOptionIDs` are Glean `broken-site-report` reason keys, not display copy.
enum WebCompatIssueCategory: String, CaseIterable, Identifiable {
    case siteNotUsable
    case designBroken
    case videoOrAudio
    case other

    var id: String { rawValue }

    var subOptionIDs: [String] {
        switch self {
        case .siteNotUsable:
            return ["browser_blocked", "page_not_loading", "missing_items", "buttons_not_working"]
        case .designBroken:
            return ["images_not_loaded", "items_overlapped", "items_misaligned", "items_not_visible"]
        case .videoOrAudio:
            return ["no_video", "no_audio", "media_controls_broken", "playback_fails", "captions_missing"]
        case .other:
            return []
        }
    }
}
