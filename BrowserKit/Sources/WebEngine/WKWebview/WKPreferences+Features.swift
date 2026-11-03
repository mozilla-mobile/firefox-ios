// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import WebKit

/// Toggles WebKit features that have no public API through the private `_features` SPI.
/// `key` is the feature's WebKit preference name, e.g. `WebTransportEnabled`.
/// Unknown keys are ignored, so a WebKit rename degrades to a no-op.
extension WKPreferences {
    private typealias SetEnabledForFeature = @convention(c) (AnyObject, Selector, Bool, AnyObject) -> Void
    private typealias IsEnabledForFeature = @convention(c) (AnyObject, Selector, AnyObject) -> Bool

    func setFeature(_ key: String, enabled: Bool) {
        let selector = Selector(("_setEnabled:forFeature:"))
        guard responds(to: selector), let feature = Self.feature(forKey: key) else { return }
        // BOOL must be passed through a typed IMP; `perform` would box it as a non-nil NSNumber.
        let setEnabled = unsafeBitCast(method(for: selector), to: SetEnabledForFeature.self)
        setEnabled(self, selector, enabled, feature)
    }

    /// Returns nil when the feature or SPI is unavailable.
    func isFeatureEnabled(_ key: String) -> Bool? {
        let selector = Selector(("_isEnabledForFeature:"))
        guard responds(to: selector), let feature = Self.feature(forKey: key) else { return nil }
        let isEnabled = unsafeBitCast(method(for: selector), to: IsEnabledForFeature.self)
        return isEnabled(self, selector, feature)
    }

    private static func feature(forKey key: String) -> NSObject? {
        let selector = Selector(("_features"))
        guard responds(to: selector),
              let features = perform(selector)?.takeUnretainedValue() as? [NSObject]
        else { return nil }
        return features.first { $0.value(forKey: "key") as? String == key }
    }
}
