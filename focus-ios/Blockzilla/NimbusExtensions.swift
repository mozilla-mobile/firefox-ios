/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Nimbus

private let NimbusServerURLKey = "NimbusServerURL"
private let NimbusAppNameKey = "NimbusAppName"
private let NimbusAppChannelKey = "NimbusAppChannel"

let NimbusDefaultDatabaseName = "nimbus.db"

extension NimbusServerSettings {
    /// Create a `NimbusServerSettings` struct by looking up the server URL in the `Info.plist`. If the value is missing
    /// from the `Info.plist`, or if it failes to parse as a valid URL, then `nil` is returned.
    /// - Returns: NimbusServerSettings
    static func createFromInfoDictionary() -> NimbusServerSettings? {
        guard let serverURLString = Bundle.main.object(forInfoDictionaryKey: NimbusServerURLKey) as? String, let serverURL = URL(string: serverURLString) else {
            return nil
        }
        return NimbusServerSettings(url: serverURL)
    }
}

extension NimbusAppSettings {
    /// Create a `NimbusAsppSettings` struct by looking up the application name and channel in the `Info.plist`. If the values are missing
    /// from the `Info.plist` or if they fail to parse, then `nil` is returned.
    /// - Returns: NimbusAppSettings
    static func createFromInfoDictionary() -> NimbusAppSettings? {
        guard let appName = Bundle.main.object(forInfoDictionaryKey: NimbusAppNameKey) as? String, let channel = Bundle.main.object(forInfoDictionaryKey: NimbusAppChannelKey) as? String else {
            return nil
        }
        return NimbusAppSettings(appName: appName, channel: channel)
    }
}

extension Nimbus {
    /// Return the default path of the nimbus database. Which is stored in the application support directory and named `nimbus.db`.
    /// - Returns: The path in a String or nil if the the support directory could not be found.
    static func defaultDatabasePath() -> String? {
        let paths = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        if paths.count == 0 {
            return nil
        }
        return paths[0].appendingPathComponent(NimbusDefaultDatabaseName).path
    }
}

/// Additional methods to allow us to use an application specific `FeatureId` enum.
extension NimbusApi {
    /// This gives you access to the branch name of any experiment acting upon the given feature.
    ///
    /// This is considerably less useful than the corresponding `withVariables` API. You probably want that
    /// API.
    ///
    /// This may be called from any thread.
    ///
    /// - Parameters:
    ///      - featureId: the id of the feature, as it is known by `Experimenter`.
    ///      - transform: the mapping between the experiment branch the user is in and something
    ///      useful for the feature. If the user is not enrolled in the experiment, the branch is `nil`.
    func withExperiment<T>(featureId: FeatureId, transform: (String?) -> T) -> T {
        // While nimbus allows us to look up a branch by featureId, its
        // actual use is to resolve the experiment branch via experiment slug.
        let branch = getExperimentBranch(experimentId: featureId.rawValue)
        return transform(branch)
    }

    /// Get a block of variables to configure the feature you're working on right now.
    ///
    /// Note: a `Variables` object is _always_ returned: from this call, there is no way of knowing
    /// if the feature is under experiment or not.
    ///
    /// If `sendExposureEvent` is `false`, you should call `recordExposureEvent` manually.
    ///
    /// - Parameters:
    ///      - featureId: the id of the feature as it appears in `Experimenter`
    ///      - sendExposureEvent: by default `true`. This logs an event that the user was exposed to an experiment
    ///      involving this feature.
    /// - Returns:
    ///      - a `Variables` object providing typed accessors to a remotely configured JSON object.
    func getVariables(featureId: FeatureId, sendExposureEvent: Bool = true) -> Variables {
        return getVariables(featureId: featureId.rawValue, sendExposureEvent: sendExposureEvent)
    }

    /// A synonym for `getVariables(featureId, sendExposureEvent)`.
    ///
    /// This exists as a complement to the `withVariable(featureId, sendExposureEvent, transform)` method.
    ///
    /// - Parameters:
    ///      - featureId: the id of the feature as it appears in `Experimenter`
    ///      - sendExposureEvent: by default `true`. This logs an event that the user was exposed to an experiment
    ///      involving this feature.
    /// - Returns:
    ///      - a `Variables` object providing typed accessors to a remotely configured JSON object.
    func withVariables(featureId: FeatureId, sendExposureEvent: Bool = true) -> Variables {
        return getVariables(featureId: featureId, sendExposureEvent: sendExposureEvent)
    }

    /// Get a `Variables` object for this feature and use that to configure the feature itself or a more type safe configuration object.
    /// - Parameters:
    ///      - featureId: the id of the feature as it appears in `Experimenter`
    ///      - sendExposureEvent: by default `true`. This logs an event that the user was exposed to an experiment
    ///      involving this feature.
    func withVariables<T>(featureId: FeatureId, sendExposureEvent: Bool = true, transform: (Variables) -> T) -> T {
        let variables = getVariables(featureId: featureId, sendExposureEvent: sendExposureEvent)
        return transform(variables)
    }

    /// Records the `exposure` event in telemetry.
    ///
    /// This is a manual function to accomplish the same purpose as passing `true` as the
    /// `sendExposureEvent` property of the `getVariables` function. It is intended to be used
    /// when requesting feature variables must occur at a different time than the actual user's
    /// exposure to the feature within the app.
    ///
    /// - Examples:
    ///     - If the `Variables` are needed at a different time than when the exposure to the feature
    ///         actually happens, such as constructing a menu happening at a different time than the
    ///         user seeing the menu.
    ///     - If `getVariables` is required to be called multiple times for the same feature and it is
    ///         desired to only record the exposure once, such as if `getVariables` were called
    ///         with every keystroke.
    ///
    /// In the case where the use of this function is required, then the `getVariables` function
    /// should be called with `false` so that the exposure event is not recorded when the variables
    /// are fetched.
    ///
    /// This function is safe to call even when there is no active experiment for the feature. The SDK
    /// will ensure that an event is only recorded for active experiments.
    ///
    /// - Parameter featureId string representing the id of the feature for which to record the exposure
    ///     event.
    ///
    func recordExposureEvent(featureId: FeatureId) {
        recordExposureEvent(featureId: featureId.rawValue)
    }
}
