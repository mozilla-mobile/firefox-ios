// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

/// Gates Sentry crash reporting for a gradual rollout. `public` since it's read from `AppLaunchUtil`
/// in the `Client` target, not just within `Ecosia`.
public struct SentryReportingExperiment {

    private init() {}

    public static var isEnabled: Bool {
        Unleash.isEnabled(.sentryReporting)
    }
}
