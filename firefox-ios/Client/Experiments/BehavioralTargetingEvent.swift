// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

// This events are used for behavioral targeting for our experiments
// https://experimenter.info/mobile-behavioral-targeting
struct BehavioralTargetingEvent {
    static let appForeground = "app_cycle.foreground"
    static let homepageViewed = "homepage_viewed"
    static let performedSearch = "performed_search"
    static let syncLoginCompletion = "sync.login_completed_view"
}
