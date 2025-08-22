/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

/// Shim class for injecting JSON feature configs, as typed into the experimenter branch config page,
/// straight into the application.
///
/// This is suitable for unit testing and ui testing.
/// <code>
///     let hardcodedNimbus = HardcodedNimbus(with: [
///          "my-feature": """{
///              "enabled": true
///          }"""
///      ])
///      hardcodedNimbus.connect(with: FxNimbus.shared)
/// </code>
///
/// Once the `hardcodedNimbus` is connected to the `FxNimbus.shared`, then
/// calling `FxNimbus.shared.features.myFeature.value()` will behave as if the given JSON
/// came from an experiment.
///
public class HardcodedNimbusFeatures {
    let features: [String: [String: Any]]
    let bundles: [Bundle]
    var exposureCounts = [String: Int]()
    var malformedFeatures = [String: String]()

    public init(bundles: [Bundle] = [.main], with features: [String: [String: Any]]) {
        self.features = features
        self.bundles = bundles
    }

    public convenience init(bundles: [Bundle] = [.main], with jsons: [String: String] = [String: String]()) {
        let features = jsons.mapValuesNotNull {
            try? Dictionary.parse(jsonString: $0)
        }
        self.init(bundles: bundles, with: features)
    }

    /// Reports how many times the feature has had {recordExposureEvent} on it.
    public func getExposureCount(featureId: String) -> Int {
        return exposureCounts[featureId] ?? 0
    }

    /// Helper function for testing if the exposure count for this feature is greater than zero.
    public func isExposed(featureId: String) -> Bool {
        return getExposureCount(featureId: featureId) > 0
    }

    /// Helper function for testing if app code has reported that any of the feature
    /// configuration is malformed.
    public func isMalformed(featureId: String) -> Bool {
        return malformedFeatures[featureId] != nil
    }

    /// Getter method for the last part of the given feature was reported malformed.
    public func getMalformed(for featureId: String) -> String? {
        return malformedFeatures[featureId]
    }

    /// Utility function for {isUnderTest} to detect if the feature is under test.
    public func has(featureId: String) -> Bool {
        return features[featureId] != nil
    }

    /// Use this `NimbusFeatures` instance to populate the passed feature configurations.
    public func connect(with fm: FeatureManifestInterface) {
        fm.initialize { self }
    }
}

extension HardcodedNimbusFeatures: FeaturesInterface {
    public func getVariables(featureId: String, sendExposureEvent: Bool) -> Variables {
        if let json = features[featureId] {
            if sendExposureEvent {
                recordExposureEvent(featureId: featureId)
            }
            return JSONVariables(with: json, in: bundles)
        }
        return NilVariables.instance
    }

    public func recordExposureEvent(featureId: String, experimentSlug _: String? = nil) {
        if features[featureId] != nil {
            exposureCounts[featureId] = getExposureCount(featureId: featureId) + 1
        }
    }

    public func recordMalformedConfiguration(featureId: String, with partId: String) {
        malformedFeatures[featureId] = partId
    }
}
