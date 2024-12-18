// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Glean
import Shared

import func MozillaAppServices.getCalculatedAttributes
import func MozillaAppServices.getLocaleTag
import struct MozillaAppServices.JsonObject
import protocol MozillaAppServices.RecordedContext
import MozillaRustComponents

private extension Double? {
    func toInt64() -> Int64? {
        guard let self = self else { return nil }
        return Int64(self)
    }
}

private extension Int32? {
    func toInt64() -> Int64? {
        guard let self = self else { return nil }
        return Int64(self)
    }
}

class RecordedNimbusContext: RecordedContext {
    /**
     * The following constants are string constants of the keys that appear in the [EVENT_QUERIES] map.
     */
    static let DAYS_OPENED_IN_LAST_28: String = "days_opened_in_last_28"

    /**
     * [EVENT_QUERIES] is a map of keys to Nimbus SDK EventStore queries.
     */
    static let EVENT_QUERIES = [
        DAYS_OPENED_IN_LAST_28: "'events.app_opened'|eventCountNonZero('Days', 28, 0)",
    ]

    var isFirstRun: Bool
    var isPhone: Bool
    var isReviewCheckerEnabled: Bool
    var isDefaultBrowser: Bool
    var appVersion: String?
    var region: String?
    var language: String?
    var locale: String
    var daysSinceInstall: Int32?
    var daysSinceUpdate: Int32?

    private var eventQueries: [String: String]
    private var eventQueryValues: [String: Double] = [:]

    private var logger: Logger

    init(isFirstRun: Bool,
         isReviewCheckerEnabled: Bool,
         isDefaultBrowser: Bool,
         eventQueries: [String: String] = RecordedNimbusContext.EVENT_QUERIES,
         isPhone: Bool = UIDevice.current.userInterfaceIdiom == .phone,
         bundle: Bundle = Bundle.main,
         logger: Logger = DefaultLogger.shared) {
        self.logger = logger
        logger.log("init start", level: .debug, category: .experiments)
        self.eventQueries = eventQueries

        self.isFirstRun = isFirstRun
        self.isPhone = isPhone
        self.isReviewCheckerEnabled = isReviewCheckerEnabled
        self.isDefaultBrowser = isDefaultBrowser

        let info = bundle.infoDictionary ?? [:]
        appVersion = info["CFBundleShortVersionString"] as? String

        locale = getLocaleTag()
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
        guard let dbPath = Experiments.dbPath else {
            self.logger.log("Unable to obtain dbPath, skipping calculating attributes",
                            level: .warning,
                            category: .experiments)
            return
        }
        guard let calculatedAttributes = try? getCalculatedAttributes(installationDate: installationDateSinceEpoch,
                                                                      dbPath: dbPath,
                                                                      locale: locale)
        else { return }

        daysSinceInstall = calculatedAttributes.daysSinceInstall
        daysSinceUpdate = calculatedAttributes.daysSinceUpdate
        language = calculatedAttributes.language
        region = calculatedAttributes.region
        self.logger.log("init end", level: .debug, category: .experiments)
    }

    /**
     * [getEventQueries] is called by the Nimbus SDK Rust code to retrieve the map of event
     * queries. The are then executed against the Nimbus SDK's EventStore to retrieve their values.
     *
     * @return Map<String, String>
     */
    func getEventQueries() -> [String: String] {
        logger.log("getEventQueries", level: .debug, category: .experiments)
        return eventQueries
    }

    /**
     * [record] is called when experiment enrollments are evolved. It should apply the
     * [RecordedNimbusContext]'s values to a [NimbusSystem.RecordedNimbusContextObject] instance,
     * and use that instance to record the values to Glean.
     */
    func record() {
        logger.log("record start", level: .debug, category: .experiments)
        let eventQueryValuesObject = GleanMetrics.NimbusSystem.RecordedNimbusContextObjectItemEventQueryValuesObject(
            daysOpenedInLast28: eventQueryValues[RecordedNimbusContext.DAYS_OPENED_IN_LAST_28].toInt64()
        )

        GleanMetrics.NimbusSystem.recordedNimbusContext.set(
            GleanMetrics.NimbusSystem.RecordedNimbusContextObject(
                isFirstRun: isFirstRun,
                eventQueryValues: eventQueryValuesObject,
                isReviewCheckerEnabled: isReviewCheckerEnabled,
                isPhone: isPhone,
                appVersion: appVersion,
                locale: locale,
                daysSinceInstall: daysSinceInstall.toInt64(),
                daysSinceUpdate: daysSinceUpdate.toInt64(),
                language: language,
                region: region,
                isDefaultBrowser: isDefaultBrowser
            )
        )
        logger.log("record end", level: .debug, category: .experiments)
    }

    /**
     * [setEventQueryValues] is called by the Nimbus SDK Rust code after the event queries have been
     * executed. The [eventQueryValues] should be written back to the Kotlin object.
     *
     * @param [eventQueryValues] The values for each query after they have been executed in the
     * Nimbus SDK Rust environment.
     */
    func setEventQueryValues(eventQueryValues: [String: Double]) {
        logger.log("setEventQueryValues", level: .debug, category: .experiments)
        self.eventQueryValues = eventQueryValues
    }

    /**
     * [toJson] is called by the Nimbus SDK Rust code after the event queries have been executed,
     * and before experiment enrollments have been evolved. The value returned from this method
     * will be applied directly to the Nimbus targeting context, and its keys/values take
     * precedence over those in the main Nimbus targeting context.
     *
     * @return JsonObject
     */
    func toJson() -> JsonObject {
        logger.log("toJson start", level: .debug, category: .experiments)
        guard let data = try? JSONSerialization.data(withJSONObject: [
            "is_first_run": isFirstRun,
            "isFirstRun": "\(isFirstRun)",
            "is_phone": isPhone,
            "is_review_checker_enabled": isReviewCheckerEnabled,
            "events": eventQueryValues,
            "app_version": appVersion as Any,
            "region": region as Any,
            "language": language as Any,
            "locale": locale as Any,
            "days_since_install": daysSinceInstall as Any,
            "days_since_update": daysSinceUpdate as Any,
            "is_default_browser": isDefaultBrowser,
        ]),
            let jsonString = NSString(data: data, encoding: String.Encoding.utf8.rawValue) as? String
        else {
            logger.log("toJson error thrown while creating JSON string", level: .warning, category: .experiments)
            return "{}"
        }
        logger.log("toJson end", level: .debug, category: .experiments, extra: ["json": jsonString])
        return jsonString
    }
}
