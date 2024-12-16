// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared

import class MozillaAppServices.NimbusBuilder
import class MozillaAppServices.NimbusDisabled
import protocol MozillaAppServices.NimbusEventStore
import protocol MozillaAppServices.NimbusInterface
import protocol MozillaAppServices.NimbusMessagingHelperProtocol
import struct MozillaAppServices.NimbusAppSettings
import typealias MozillaAppServices.NimbusErrorReporter

private let nimbusAppName = "firefox_ios"
private let NIMBUS_URL_KEY = "NimbusURL"
private let NIMBUS_LOCAL_DATA_KEY = "nimbus_local_data"
private let NIMBUS_USE_PREVIEW_COLLECTION_KEY = "nimbus_use_preview_collection"
private let NIMBUS_IS_FIRST_RUN_KEY = "NimbusFirstRun"

/// `Experiments` is the main entry point to use the `Nimbus` experimentation platform in Firefox for iOS.
///
/// This class is a application specific holder for a the singleton `NimbusApi` class.
///
/// It is needed to be initialized early in the startup of the app, so a lot of the heavy lifting of
/// calculating where the database should live, and deriving the `Remote Settings` URL for itself.
/// This should be done with the `initialize(with:,firstRun:)` method.
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
/// Rust errors are not expected, but will be reported via logger.
enum Experiments {
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
        if AppConstants.isRunningUITests || AppConstants.isRunningPerfTests {
            profilePath = (UIApplication.shared.delegate as? UITestAppDelegate)?.dirForTestProfile
        } else if AppConstants.isRunningUnitTest {
            let dir = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            profilePath = dir.path
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

        return dbPath
    }

    static let remoteSettingsURL: String? = {
        guard let url = Bundle.main.object(forInfoDictionaryKey: NIMBUS_URL_KEY) as? String,
              !url.isEmptyOrWhitespace()
        else {
            DefaultLogger.shared.log("No Nimbus URL found in Info.plist",
                                     level: .warning,
                                     category: .experiments)
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

    /// The `NimbusApi` object. This is the entry point to do anything with the Nimbus SDK on device.
    public static var shared: NimbusInterface = {
        let defaults = UserDefaults.standard
        let isFirstRun: Bool = defaults.object(forKey: NIMBUS_IS_FIRST_RUN_KEY) == nil
        if isFirstRun {
            defaults.set(false, forKey: NIMBUS_IS_FIRST_RUN_KEY)
        }

        let errorReporter: NimbusErrorReporter = { err in
            DefaultLogger.shared.log("Error in Nimbus SDK",
                                     level: .warning,
                                     category: .experiments,
                                     description: err.localizedDescription)
        }

        let initialExperiments = Bundle.main.url(forResource: "initial_experiments", withExtension: "json")

        guard let dbPath = Experiments.dbPath else {
            DefaultLogger.shared.log("Nimbus didn't get to create, because of a nil dbPath",
                                     level: .warning,
                                     category: .experiments)
            return NimbusDisabled.shared
        }

        return buildNimbus(dbPath: dbPath,
                           errorReporter: errorReporter,
                           initialExperiments: initialExperiments,
                           isFirstRun: isFirstRun)
    }()

    private static func getAppSettings(isFirstRun: Bool) -> NimbusAppSettings {
        let isPhone = UIDevice.current.userInterfaceIdiom == .phone

        let customTargetingAttributes: [String: Any] =  [
            "isFirstRun": "\(isFirstRun)",
            "is_first_run": isFirstRun,
            "is_phone": isPhone,
            "is_review_checker_enabled": isReviewCheckerEnabled(),
            "is_default_browser": isDefaultBrowser(),
        ]

        // App settings, to allow experiments to target the app name and the
        // channel. The values given here should match what `Experimenter`
        // thinks it is.
        return NimbusAppSettings(
            appName: nimbusAppName,
            channel: AppConstants.buildChannel.nimbusString,
            customTargetingAttributes: customTargetingAttributes
        )
    }

    private static func isReviewCheckerEnabled() -> Bool {
        var isReviewCheckerEnabled = false
        if let prefs = UserDefaults(suiteName: AppInfo.sharedContainerIdentifier) {
            isReviewCheckerEnabled = prefs.bool(forKey: "profile." + PrefsKeys.Shopping2023OptIn)
        }
        return isReviewCheckerEnabled
    }

    private static func isDefaultBrowser() -> Bool {
        return UserDefaults.standard.bool(forKey: PrefsKeys.AppleConfirmedUserIsDefaultBrowser)
    }

    private static func buildNimbus(dbPath: String,
                                    errorReporter: @escaping NimbusErrorReporter,
                                    initialExperiments: URL?,
                                    isFirstRun: Bool) -> NimbusInterface {
        let bundles = [
            Bundle.main,
            Strings.bundle,
            Strings.bundle.fallbackTranslationBundle(language: "en-US")
        ].compactMap { $0 }

        return NimbusBuilder(dbPath: dbPath)
            .with(url: remoteSettingsURL)
            .using(previewCollection: usePreviewCollection())
            .with(errorReporter: errorReporter)
            .with(initialExperiments: initialExperiments)
            .isFirstRun(isFirstRun)
            .with(bundles: bundles)
            .with(featureManifest: FxNimbus.shared)
            .with(commandLineArgs: CommandLine.arguments)
            .build(appInfo: getAppSettings(isFirstRun: isFirstRun))
    }

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
    public static func intialize() {
        // Getting the singleton first time initializes it.
        let nimbus = Experiments.shared

        DefaultLogger.shared.log("Nimbus is ready!",
                                 level: .info,
                                 category: .experiments)

        // This does its work on another thread, downloading the experiment recipes
        // for the next run. It should be the last thing we do before returning.
        nimbus.fetchExperiments()
    }
}

extension Experiments {
    public static func createJexlHelper() -> NimbusMessagingHelperProtocol? {
        let contextProvider = GleanPlumbContextProvider()
        let context = contextProvider.createAdditionalDeviceContext()
        return try? sdk.createMessageHelper(additionalContext: context)
    }

    public static var messaging: GleanPlumbMessageManagerProtocol = {
        GleanPlumbMessageManager()
    }()

    public static var events: NimbusEventStore = {
        sdk.events
    }()

    public static var sdk: NimbusInterface = shared
}

private extension AppBuildChannel {
    var nimbusString: String {
        switch self {
        case .release: return "release"
        case .beta: return "beta"
        case .developer: return "developer"
        case .other: return "other"
        }
    }
}
