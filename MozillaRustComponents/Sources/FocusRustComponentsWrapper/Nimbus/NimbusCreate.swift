/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Glean
import UIKit

private let logTag = "Nimbus.swift"
private let logger = Logger(tag: logTag)

public let defaultErrorReporter: NimbusErrorReporter = { err in
    switch err {
    case is LocalizedError:
        let description = err.localizedDescription
        logger.error("Nimbus error: \(description)")
    default:
        logger.error("Nimbus error: \(err)")
    }
}

class GleanMetricsHandler: MetricsHandler {
    func recordEnrollmentStatuses(enrollmentStatusExtras: [EnrollmentStatusExtraDef]) {
        for extra in enrollmentStatusExtras {
            GleanMetrics.NimbusEvents.enrollmentStatus
                .record(GleanMetrics.NimbusEvents.EnrollmentStatusExtra(
                    branch: extra.branch,
                    conflictSlug: extra.conflictSlug,
                    errorString: extra.errorString,
                    reason: extra.reason,
                    slug: extra.slug,
                    status: extra.status
                ))
        }
    }

    func recordFeatureActivation(event: FeatureExposureExtraDef) {
        GleanMetrics.NimbusEvents.activation
            .record(GleanMetrics.NimbusEvents.ActivationExtra(
                branch: event.branch,
                experiment: event.slug,
                featureId: event.featureId
            ))
    }

    func recordFeatureExposure(event: FeatureExposureExtraDef) {
        GleanMetrics.NimbusEvents.exposure
            .record(GleanMetrics.NimbusEvents.ExposureExtra(
                branch: event.branch,
                experiment: event.slug,
                featureId: event.featureId
            ))
    }

    func recordMalformedFeatureConfig(event: MalformedFeatureConfigExtraDef) {
        GleanMetrics.NimbusEvents.malformedFeature
            .record(GleanMetrics.NimbusEvents.MalformedFeatureExtra(
                branch: event.branch,
                experiment: event.slug,
                featureId: event.featureId,
                partId: event.part
            ))
    }
}

public extension Nimbus {
    /// Create an instance of `Nimbus`.
    ///
    /// - Parameters:
    ///     - server: the server that experiments will be downloaded from
    ///     - appSettings: the name and channel for the app
    ///     - dbPath: the path on disk for the database
    ///     - resourceBundles: an optional array of `Bundle` objects that are used to lookup text and images
    ///     - enabled: intended for FeatureFlags. If false, then return a dummy `Nimbus` instance. Defaults to `true`.
    ///     - errorReporter: a closure capable of reporting errors. Defaults to using a logger.
    /// - Returns an implementation of `NimbusApi`.
    /// - Throws `NimbusError` if anything goes wrong with the Rust FFI or in the `NimbusClient` constructor.
    ///
    static func create(
        _ server: NimbusServerSettings?,
        appSettings: NimbusAppSettings,
        coenrollingFeatureIds: [String] = [],
        dbPath: String,
        resourceBundles: [Bundle] = [Bundle.main],
        enabled: Bool = true,
        userDefaults: UserDefaults? = nil,
        errorReporter: @escaping NimbusErrorReporter = defaultErrorReporter,
        recordedContext: RecordedContext? = nil
    ) throws -> NimbusInterface {
        guard enabled else {
            return NimbusDisabled.shared
        }

        let context = Nimbus.buildExperimentContext(appSettings)
        let remoteSettings = server.map { server -> RemoteSettingsConfig in
            RemoteSettingsConfig(
                collectionName: server.collection,
                server: .custom(url: server.url.absoluteString)
            )
        }
        let nimbusClient = try NimbusClient(
            appCtx: context,
            recordedContext: recordedContext,
            coenrollingFeatureIds: coenrollingFeatureIds,
            dbpath: dbPath,
            remoteSettingsConfig: remoteSettings,
            metricsHandler: GleanMetricsHandler(),
            geckoPrefHandler: nil
        )

        return Nimbus(
            nimbusClient: nimbusClient,
            resourceBundles: resourceBundles,
            userDefaults: userDefaults,
            errorReporter: errorReporter
        )
    }

    static func buildExperimentContext(
        _ appSettings: NimbusAppSettings,
        bundle: Bundle = Bundle.main,
        device: UIDevice = .current
    ) -> AppContext {
        let info = bundle.infoDictionary ?? [:]
        var inferredDateInstalledOn: Date? {
            guard
                let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last,
                let attributes = try? FileManager.default.attributesOfItem(atPath: documentsURL.path)
            else { return nil }
            return attributes[.creationDate] as? Date
        }
        let installationDateSinceEpoch = inferredDateInstalledOn.map {
            Int64(($0.timeIntervalSince1970 * 1000).rounded())
        }

        return AppContext(
            appName: appSettings.appName,
            appId: info["CFBundleIdentifier"] as? String ?? "unknown",
            channel: appSettings.channel,
            appVersion: info["CFBundleShortVersionString"] as? String,
            appBuild: info["CFBundleVersion"] as? String,
            architecture: Sysctl.machine, // Sysctl is from Glean.
            deviceManufacturer: Sysctl.manufacturer,
            deviceModel: Sysctl.model,
            locale: getLocaleTag(), // from Glean utils
            os: device.systemName,
            osVersion: device.systemVersion,
            androidSdkVersion: nil,
            debugTag: "Nimbus.rs",
            installationDate: installationDateSinceEpoch,
            homeDirectory: nil,
            customTargetingAttributes: try? appSettings.customTargetingAttributes.stringify()
        )
    }
}
