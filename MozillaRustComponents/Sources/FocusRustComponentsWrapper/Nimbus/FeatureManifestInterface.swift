/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

public protocol FeatureManifestInterface {
    // The `associatedtype``, and the `features`` getter require existential types, in Swift 5.7.
    // associatedtype Features

    // Accessor object for generated configuration classes extracted from Nimbus, with built-in
    // default values.
    // The `associatedtype``, and the `features`` getter require existential types, in Swift 5.7.
    // var features: Features { get }

    /// This method should be called as early in the startup sequence of the app as possible.
    /// This is to connect the Nimbus SDK (and thus server) with the `{{ nimbus_object }}`
    /// class.
    ///
    /// The lambda MUST be threadsafe in its own right.
    ///
    /// This happens automatically if you use the `NimbusBuilder` pattern of initialization.
    func initialize(with getSdk: @escaping () -> FeaturesInterface?)

    /// Refresh the cache of configuration objects.
    ///
    /// For performance reasons, the feature configurations are constructed once then cached.
    /// This method is to clear that cache for all features configured with Nimbus.
    ///
    /// It must be called whenever the Nimbus SDK finishes the `applyPendingExperiments()` method.
    ///
    /// This happens automatically if you use the `NimbusBuilder` pattern of initialization.
    func invalidateCachedValues()

    /// Get a feature configuration. This is of limited use for most uses of the FML, though
    /// is quite useful for introspection.
    func getFeature(featureId: String) -> FeatureHolderAny?

    func getCoenrollingFeatureIds() -> [String]
}
