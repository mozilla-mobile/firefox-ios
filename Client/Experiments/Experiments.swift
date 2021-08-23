/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import MozillaAppServices
import Shared
import XCGLogger

private let log = Logger.browserLogger
private let nimbusAppName = "firefox_ios"
private let NIMBUS_URL_KEY = "NimbusURL"
private let NIMBUS_LOCAL_DATA_KEY = "nimbus_local_data"
private let NIMBUS_USE_PREVIEW_COLLECTION_KEY = "nimbus_use_preview_collection"

/// `Experiments` is the main entry point to use the `Nimbus` experimentation platform in Firefox for iOS.
///
/// This class is a application specific holder for a the singleton `NimbusApi` class.
///
/// It is needed to be initialized early in the startup of the app, so a lot of the heavy lifting of calculating where the
/// database should live, and deriving the `Remote Settings` URL for itself. This should be done with the
/// `initialize(with:,firstRun:)` method.
///
/// Most usage with be made of `Nimbus` by feature developers who wish to make decisions about how
/// to configure their features.
///
/// This should be done with the `withExperiment(featureId:)` method.
/// ```
/// button.text = Exeriments.shared.withExperiment(featureId: .submitButton) { branchId in
///    switch branchId {
///      NimbusExperimentBranch.treatment -> return "Ok then"
///      else -> return "OK"
///    }
/// }
/// ```
///
/// Possible values for `featureId` correspond to the application features under experiment, and are
/// enumerated  in the `FeatureId` `enum` in `ExperimentConstants.swift`.
///
/// Branches are left as `String`s as they are an unbounded set of values, but commonly used
/// constants are also defined in `ExperimentConstants`.
///
/// The server components of Nimbus are: `RemoteSettings` which serves the experiment definitions to
/// clients, and `Experimenter`, which is the user interface for creating and administering experiments.
///
/// Rust errors are not expected, but will be reported via Sentry.
enum Experiments {

    /// `InitializationOptions` controls how we initially initialize Nimbus.
    ///
    /// - **preload**: includes a file URL that stores the initial experiments document.
    ///     This will preload Nimbus with experiment data and also fetch new data from the remote server
    /// - **normal**: initialize Nimbus with no custom configuration.
    /// - **testing**: initialize Nimbus with custom experiments data.
    enum InitializationOptions {
        case preload(fileUrl: URL)
        case normal
        case testing(localPayload: String)

        var isTesting: Bool {
            switch self {
            case .testing: return true
            default: return false
            }
        }
    }

    static func setLocalExperimentData(payload: String?, storage: UserDefaults = .standard) {
        guard let payload = payload else {
            storage.removeObject(forKey: NIMBUS_LOCAL_DATA_KEY)
            return
        }

        storage.setValue(payload, forKey: NIMBUS_LOCAL_DATA_KEY)
    }

    static func getLocalExperimentData(storage: UserDefaults = .standard) -> String? {
        return storage.string(forKey: NIMBUS_LOCAL_DATA_KEY)
    }

    static var dbPath: String? {
        let profilePath: String?
        if AppConstants.IsRunningTest || AppConstants.IsRunningPerfTest {
            profilePath = (UIApplication.shared.delegate as? TestAppDelegate)?.dirForTestProfile
        } else {
            profilePath = FileManager.default.containerURL(
                forSecurityApplicationGroupIdentifier: AppInfo.sharedContainerIdentifier
            )?
                .appendingPathComponent("profile.profile")
                .path
        }
        let dbPath = profilePath.flatMap {
            URL(fileURLWithPath: $0).appendingPathComponent("nimbus.db").path
        }

        if let dbPath = dbPath, Logger.logPII {
            log.info("Nimbus database: \(dbPath)")
        }
        return dbPath
    }

    static let remoteSettingsURL: String? = {
        guard let url = Bundle.main.object(forInfoDictionaryKey: NIMBUS_URL_KEY) as? String,
              !url.isEmptyOrWhitespace() else {
            log.error("No Nimbus URL found in Info.plist")
            return nil
        }

        return url
    }()

    static func setUsePreviewCollection(enabled: Bool, storage: UserDefaults = .standard) {
        storage.setValue(enabled, forKey: NIMBUS_USE_PREVIEW_COLLECTION_KEY)
    }

    static func usePreviewCollection(storage: UserDefaults = .standard) -> Bool {
        storage.bool(forKey: NIMBUS_USE_PREVIEW_COLLECTION_KEY)
    }
    
    static var customTargetingAttributes: [String: String] = [:]

    static var serverSettings: NimbusServerSettings? = {
        // If no URL is specified, or it's not valid continue with as if
        // we're enabled. This to allow testing of the app, without standing
        // up a `RemoteSettings` server.
        guard let urlString = Experiments.remoteSettingsURL else {
            return nil
        }

        guard let url = URL(string: urlString) else {
            return nil
        }

        if usePreviewCollection() {
            return NimbusServerSettings(url: url, collection: "nimbus-preview")
        } else {
            return NimbusServerSettings(url: url)
        }
    }()

    /// The `NimbusApi` object. This is the entry point to do anything with the Nimbus SDK on device.
    public static var shared: NimbusApi = {
        guard FeatureFlagsManager.shared.isFeatureActive(.nimbus) else {
            return NimbusDisabled.shared
        }

        guard let dbPath = Experiments.dbPath else {
            log.error("Nimbus didn't get to create, because of a nil dbPath")
            return NimbusDisabled.shared
        }

        // App settings, to allow experiments to target the app name and the
        // channel. The values given here should match what `Experimenter`
        // thinks it is.
        let appSettings = NimbusAppSettings(
            appName: nimbusAppName,
            channel: AppConstants.BuildChannel.nimbusString,
            customTargetingAttributes: Experiments.customTargetingAttributes
        )

        let errorReporter: NimbusErrorReporter = { err in
            Sentry.shared.sendWithStacktrace(
                message: "Error in Nimbus SDK",
                tag: SentryTag.nimbus,
                severity: .error,
                description: err.localizedDescription
            )
        }

        do {
            let nimbus = try Nimbus.create(
                serverSettings,
                appSettings: appSettings,
                dbPath: dbPath,
                resourceBundles: [Strings.bundle, Bundle.main],
                errorReporter: errorReporter
            )
            log.info("Nimbus is now available!")
            return nimbus
        } catch {
            errorReporter(error)
            log.error("Nimbus errored during create")
            return NimbusDisabled.shared
        }
    }()

    /// A convenience method to initialize the `NimbusApi` object at startup.
    ///
    /// This includes opening the database, connecting to the Remote Settings server, and downloading
    /// and applying changes.
    ///
    /// All this is set to run off the main thread.
    ///
    /// - Parameters:
    ///     - fireURL: an optional file URL that stores the initial experiments document.
    ///     - firstRun: a flag indicating that this is the first time that the app has been run.
    public static func intialize(_ options: InitializationOptions) {
        let nimbus = Experiments.shared

        nimbus.initialize()

        switch options {
        case .preload(let url): nimbus.setExperimentsLocally(url)
        case .testing(let payload): nimbus.setExperimentsLocally(payload)
        default: break /* noop */
        }

        // We should immediately calculate the experiment enrollments
        // that we've just acquired from the fileURL, or we fetched last run.
        nimbus.applyPendingExperiments()

        // if we're not testing, we should download the next version of the experiments
        // document. This happens in the background
        if !options.isTesting {
            nimbus.fetchExperiments()
        }

        log.info("Nimbus is initializing!")
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
    func withExperiment<T>(featureId: NimbusFeatureId, transform: (String?) -> T) -> T {
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
    func getVariables(featureId: NimbusFeatureId, sendExposureEvent: Bool = true) -> Variables {
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
    func withVariables(featureId: NimbusFeatureId, sendExposureEvent: Bool = true) -> Variables {
        return getVariables(featureId: featureId, sendExposureEvent: sendExposureEvent)
    }

    /// Get a `Variables` object for this feature and use that to configure the feature itself or a more type safe configuration object.
    /// - Parameters:
    ///      - featureId: the id of the feature as it appears in `Experimenter`
    ///      - sendExposureEvent: by default `true`. This logs an event that the user was exposed to an experiment
    ///      involving this feature.
    func withVariables<T>(featureId: NimbusFeatureId, sendExposureEvent: Bool = true, transform: (Variables) -> T) -> T {
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
    func recordExposureEvent(featureId: NimbusFeatureId) {
        recordExposureEvent(featureId: featureId.rawValue)
    }
}

private extension AppBuildChannel {
    var nimbusString: String {
        switch self {
        case .release: return "release"
        case .beta: return "beta"
        case .developer: return "nightly"
        case .other: return "other"
        }
    }
}
