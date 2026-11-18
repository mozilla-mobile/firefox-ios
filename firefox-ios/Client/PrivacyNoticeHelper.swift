// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Shared

protocol PrivacyNoticeHelperProtocol {
    func shouldShowPrivacyNotice() -> Bool
}

struct PrivacyNoticeHelper: PrivacyNoticeHelperProtocol {
    private let nimbus: FxNimbus

    // Date of the last privacy notice update in milliseconds since epoch
    // Update this value to the latest privacy notice release date when you want to show users the
    // homepage privacy notice card
    var privacyNoticeUpdateInMilliseconds: UInt64 {
        let isDebugOverride = prefs.boolForKey(PrefsKeys.PrivacyNotice.privacyNoticeUpdateDebugOverride) ?? false
        if isDebugOverride { return UInt64(Date().timeIntervalSince1970 * 1000) }

        let timestamp = nimbus.features.touFeature.value().notificationTimestamp
        return UInt64(timestamp)
    }

    private let prefs: Prefs

    init(prefs: Prefs, nimbus: FxNimbus = FxNimbus.shared) {
        self.prefs = prefs
        self.nimbus = nimbus
    }

    func shouldShowPrivacyNotice() -> Bool {
        // 1. User has already accepted ToU (via onboarding or bottom sheet)
        // Use TermsOfUseAcceptedDate (migrated from TermsOfServiceAcceptedDate)
        guard let acceptedDate = prefs.timestampForKey(PrefsKeys.TermsOfUseAcceptedDate) else { return false }

        // 2. User has accepted ToS (via onboarding or bottom sheet) before the last privacy notice update
        //    AND has not since seen the homepage privacy notice card since the privacy notice was updated
        //    AND the privacy notice date is in the past
        let hasPrivacyNoticeUpdateTimePassed = UInt64(Date().toTimestamp()) >= privacyNoticeUpdateInMilliseconds
        let isAcceptanceOutdated = acceptedDate < privacyNoticeUpdateInMilliseconds
        let privacyNoticeNotifiedDate = prefs.timestampForKey(PrefsKeys.PrivacyNotice.notifiedDate)
        let isPrivacyNoticeOutdated = privacyNoticeNotifiedDate.map { $0 < privacyNoticeUpdateInMilliseconds } ?? true
        guard hasPrivacyNoticeUpdateTimePassed, isPrivacyNoticeOutdated, isAcceptanceOutdated else { return false }

        prefs.setTimestamp(Date().toTimestamp(), forKey: PrefsKeys.PrivacyNotice.notifiedDate)
        prefs.setBool(false, forKey: PrefsKeys.PrivacyNotice.privacyNoticeUpdateDebugOverride)

        return true
    }
}
