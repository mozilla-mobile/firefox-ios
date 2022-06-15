// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

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

    private static var studiesSetting: Bool?
    private static var telemetrySetting: Bool?

    static func setStudiesSetting(_ setting: Bool) {
        studiesSetting = setting
        updateGlobalUserParticipation()
    }

    static func setTelemetrySetting(_ setting: Bool) {
        telemetrySetting = setting
        if !setting {
            shared.resetTelemetryIdentifiers()
        }
        updateGlobalUserParticipation()
    }

    private static func updateGlobalUserParticipation() {
        // we only want to reset the globalUserParticipation flag if both settings have been
        // initialized.
        if let studiesSetting = studiesSetting, let telemetrySetting = telemetrySetting {
            // we only enable experiments if users are opting in BOTH
            // telemetry and studies. If either is opted-out, we make
            // sure users are not enrolled in any experiments
            shared.globalUserParticipation = studiesSetting && telemetrySetting
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
            SentryIntegration.shared.sendWithStacktrace(
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
