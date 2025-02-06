// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public final class UnleashRefreshConfigurator {

    public init() {}

    @discardableResult
    public func withAppUpdateCheckRule(appVersion: String) -> Self {
        let appUpdateRule = AppUpdateRule(appVersion: appVersion)
        Unleash.addRule(appUpdateRule)
        return self
    }

    @discardableResult
    public func withTwentyFourHoursCacheExpirationRule() -> Self {
        let timeRule = TimeBasedRefreshingRule(interval: TimeInterval.twentyFourHoursTimeInterval)
        Unleash.addRule(timeRule)
        return self
    }

    @discardableResult
    public func withDeviceRegionUpdateCheckRule(localeProvider: RegionLocatable = Locale.current) -> Self {
        let regionRule = DeviceRegionChangeRule(localeProvider: localeProvider)
        Unleash.addRule(regionRule)
        return self
    }
}
