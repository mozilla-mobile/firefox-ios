/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import MozillaAppServices
import Shared
import XCGLogger

private let log = Logger.browserLogger
private let nimbusAppName = "firefox_ios"

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
///      ExperimentBranch.treatment -> return "Ok then"
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

    static var remoteSettingsURL: String? {
        // TODO: get URL from build secret. https://jira.mozilla.com/browse/SDK-212
        return "https://firefox.settings.services.mozilla.com/"
    }

    /// The `NimbusApi` object. This is the entry point to do anything with the Nimbus SDK on device.
    public static var shared: NimbusApi = {
        guard AppConstants.NIMBUS_ENABLED else {
            return NimbusDisabled.shared
        }

        guard let dbPath = Experiments.dbPath else {
            log.error("Nimbus didn't get to create, because of a nil dbPath")
            return NimbusDisabled.shared
        }

        // If no URL is specified, or it's not valid continue with as if
        // we're enabled. This to allow testing of the app, without standing
        // up a `RemoteSettings` server.
        let serverSettings = Experiments.remoteSettingsURL.flatMap {
            URL(string: $0)
        }.flatMap {
            NimbusServerSettings(url: $0)
        }

        // App settings, to allow experiments to target the app name and the
        // channel. The values given here should match what `Experimenter`
        // thinks it is.
        let appSettings = NimbusAppSettings(
            appName: nimbusAppName,
            channel: AppConstants.BuildChannel.nimbusString
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
                dbPath: dbPath, errorReporter: errorReporter
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
    public static func intialize(with fileURL: URL?, firstRun: Bool) {
        let nimbus = Experiments.shared

        nimbus.initialize()

        if let fileURL = fileURL, firstRun {
            nimbus.setExperimentsLocally(fileURL)
        }
        // We should immediately calculate the experiment enrollments
        // that we've just acquired from the fileURL, or we fetched last run.
        nimbus.applyPendingExperiments()

        // In the background, we should download the next version of the experiments
        // document.
        nimbus.fetchExperiments()

        log.info("Nimbus is initializing!")
    }
}

extension NimbusApi {
    /// The entry point for feature developers configuring their feature with an experiment.
    ///
    /// This may be called from any thread.
    ///
    /// - Parameters:
    ///      - featureId: the id of the feature, as it is known by `Experimenter`.
    ///      - transform: the mapping between the experiment branch the user is in and something
    ///      useful for the feature. If the user is not enrolled in the experiment, the branch is `nil`.
    func withExperiment<T>(featureId: FeatureId, transform: (String?) -> T) -> T {
        let branch = getExperimentBranch(featureId: featureId.rawValue)
        return transform(branch)
    }
}

private extension AppBuildChannel {
    var nimbusString: String {
        switch self {
        case .release: return "release"
        case .beta: return "beta"
        case .developer: return "nightly"
        }
    }
}
