/* This Source Code Form is subject to the terms of the Mozilla
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */
import Foundation

/// A small protocol to get the feature variables out of the Nimbus SDK.
///
/// This is intended to be standalone to allow for testing the Nimbus FML.
public protocol FeaturesInterface: AnyObject {
    var userDefaults: UserDefaults? { get }

    /// Get the variables needed to configure the feature given by `featureId`.
    ///
    /// - Parameters:
    ///     - featureId The string feature id that identifies to the feature under experiment.
    ///     - recordExposureEvent Passing `true` to this parameter will record the exposure
    ///         event automatically if the client is enrolled in an experiment for the given `featureId`.
    ///         Passing `false` here indicates that the application will manually record the exposure
    ///         event by calling `recordExposureEvent`.
    ///
    /// See `recordExposureEvent` for more information on manually recording the event.
    ///
    /// - Returns a `Variables` object used to configure the feature.
    func getVariables(featureId: String, sendExposureEvent: Bool) -> Variables

    /// Records the `exposure` event in telemetry.
    ///
    /// This is a manual function to accomplish the same purpose as passing `true` as the
    /// `recordExposureEvent` property of the `getVariables` function. It is intended to be used
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
    func recordExposureEvent(featureId: String, experimentSlug: String?)

    /// Records an event signifying a malformed feature configuration, or part of one.
    ///
    /// - Parameter featureId string representing the id of the feature which app code has found to
    ///     malformed.
    /// - Parameter partId string representing the card id or message id of the part of the feature that
    ///     is malformed, providing more detail to experiment owners of where to look for the problem.
    func recordMalformedConfiguration(featureId: String, with partId: String)
}

public extension FeaturesInterface {
    var userDefaults: UserDefaults? {
        nil
    }
}
