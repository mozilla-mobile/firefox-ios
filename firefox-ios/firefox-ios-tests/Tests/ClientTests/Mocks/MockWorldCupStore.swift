// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

@testable import Client

final class MockWorldCupStore: WorldCupStoreProtocol {
    var isFeatureEnabled = true
    var isHomepageSectionEnabled = true
    var selectedTeam: String?
    var isMilestone2 = false

    var setIsHomepageSectionEnabledCalled = 0
    var lastSetIsHomepageSectionEnabledValue: Bool?

    var setSelectedTeamCalled = 0
    var lastSetSelectedTeamCountryId: String?

    var isFeatureEnabledAndSectionEnabled: Bool {
        return isFeatureEnabled && isHomepageSectionEnabled
    }

    func setIsHomepageSectionEnabled(_ isEnabled: Bool) {
        setIsHomepageSectionEnabledCalled += 1
        lastSetIsHomepageSectionEnabledValue = isEnabled
        isHomepageSectionEnabled = isEnabled
    }

    func setSelectedTeam(countryId: String?) {
        setSelectedTeamCalled += 1
        lastSetSelectedTeamCountryId = countryId
        selectedTeam = countryId
    }
}
