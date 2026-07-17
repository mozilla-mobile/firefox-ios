// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Issue categories for the "Report a Website Issue" form — a grouping for the
/// sub-options, not display copy. The Glean `broken-site-report` reason keys
/// live on `WebCompatSubOption.rawValue`.
enum WebCompatIssueCategory: String, CaseIterable, Identifiable {
    case siteNotUsable
    case designBroken
    case videoOrAudio
    case other

    var id: String { rawValue }

    var subOptions: [WebCompatSubOption] {
        switch self {
        case .siteNotUsable:
            return [.browserBlocked, .pageNotLoading, .missingItems, .buttonsNotWorking]
        case .designBroken:
            return [.imagesNotLoaded, .itemsOverlapped, .itemsMisaligned, .itemsNotVisible]
        case .videoOrAudio:
            return [.noVideo, .noAudio, .mediaControlsBroken, .playbackFails, .captionsMissing]
        case .other:
            return []
        }
    }
}

/// A sub-option under a `WebCompatIssueCategory`. Raw values are Glean
/// `broken-site-report` reason keys, not display copy.
enum WebCompatSubOption: String, CaseIterable, Identifiable {
    case browserBlocked = "browser_blocked"
    case pageNotLoading = "page_not_loading"
    case missingItems = "missing_items"
    case buttonsNotWorking = "buttons_not_working"
    case imagesNotLoaded = "images_not_loaded"
    case itemsOverlapped = "items_overlapped"
    case itemsMisaligned = "items_misaligned"
    case itemsNotVisible = "items_not_visible"
    case noVideo = "no_video"
    case noAudio = "no_audio"
    case mediaControlsBroken = "media_controls_broken"
    case playbackFails = "playback_fails"
    case captionsMissing = "captions_missing"

    var id: String { rawValue }
}
