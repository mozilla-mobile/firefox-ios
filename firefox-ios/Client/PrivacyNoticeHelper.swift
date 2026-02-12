// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Shared

protocol PrivacyNoticeHelperProtocol {
    func shouldShowPrivacyNotice() -> Bool
}

struct PrivacyNoticeHelper: PrivacyNoticeHelperProtocol {
    // Date of the last privacy notice update in miliseconds since epoch
    // Update this value to the latest privacy notice release date when you want to show users the
    // homepage privacy notice card
    var privacyNoticeUpdateInMilliseconds: UInt64 {
        let isDebugOverride = prefs.boolForKey(PrefsKeys.PrivacyNotice.privacyNoticeUpdateDebugOverride) ?? false
        if isDebugOverride { return UInt64(Date().timeIntervalSince1970 * 1000) }

        let components = DateComponents(timeZone: TimeZone(secondsFromGMT: 0), year: 2025, month: 12, day: 17)
        let calendar = Calendar(identifier: .gregorian)
        let date = calendar.date(from: components) ?? .distantPast
        return UInt64(date.timeIntervalSince1970 * 1000)
    }

    private let prefs: Prefs

    init(prefs: Prefs) {
        self.prefs = prefs
    }

    func shouldShowPrivacyNotice() -> Bool {
        // 1. User has already accepted ToU (via onboarding or bottom sheet)
        // Use TermsOfUseAcceptedDate (migrated from TermsOfServiceAcceptedDate)
        guard let acceptedDate = prefs.timestampForKey(PrefsKeys.TermsOfUseAcceptedDate) else { return false }

        // 2. User has accepted ToS (via onboarding or bottom sheet) before the last privacy notice update
        //    AND has not since seen the homepage privacy notice card since the privacy notice was updated
        let isAcceptanceOutdated = acceptedDate < privacyNoticeUpdateInMilliseconds
        let privacyNoticeNotifiedDate = prefs.timestampForKey(PrefsKeys.PrivacyNotice.notifiedDate)
        let isPrivacyNoticeOutdated = privacyNoticeNotifiedDate.map { $0 < privacyNoticeUpdateInMilliseconds } ?? true
        guard isPrivacyNoticeOutdated, isAcceptanceOutdated else { return false }

        prefs.setTimestamp(Date().toTimestamp(), forKey: PrefsKeys.PrivacyNotice.notifiedDate)
        prefs.setBool(false, forKey: PrefsKeys.PrivacyNotice.privacyNoticeUpdateDebugOverride)

        return true
    }
}
