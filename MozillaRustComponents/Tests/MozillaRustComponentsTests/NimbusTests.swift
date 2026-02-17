/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Glean
@testable import MozillaRustComponents
@testable import MozillaAppServices
import UIKit
import XCTest

class NimbusTests: XCTestCase {
    override func setUp() {
        // Due to recent changes in how upload enabled works, we need to register the custom
        // Sync pings before they can collect data in tests, even here in Nimbus unfortunately.
        // See https://bugzilla.mozilla.org/show_bug.cgi?id=1935001 for more info.
        Glean.shared.registerPings(GleanMetrics.Pings.shared.sync)
        Glean.shared.registerPings(GleanMetrics.Pings.shared.historySync)
        Glean.shared.registerPings(GleanMetrics.Pings.shared.bookmarksSync)
        Glean.shared.registerPings(GleanMetrics.Pings.shared.loginsSync)
        Glean.shared.registerPings(GleanMetrics.Pings.shared.creditcardsSync)
        Glean.shared.registerPings(GleanMetrics.Pings.shared.addressesSync)
        Glean.shared.registerPings(GleanMetrics.Pings.shared.tabsSync)

        Glean.shared.resetGlean(clearStores: true)
    }

    func emptyExperimentJSON() -> String {
        return """
        { "data": [] }
        """
    }

    func minimalExperimentJSON() -> String {
        return """
        {
            "data": [{
                "schemaVersion": "1.0.0",
                "slug": "secure-gold",
                "endDate": null,
                "featureIds": ["aboutwelcome"],
                "branches": [{
                        "slug": "control",
                        "ratio": 1,
                        "feature": {
                            "featureId": "aboutwelcome",
                            "enabled": false,
                            "value": {
                                "text": "OK then",
                                "number": 42
                            }
                        }
                    },
                    {
                        "slug": "treatment",
                        "ratio": 1,
                        "feature": {
                            "featureId": "aboutwelcome",
                            "enabled": true,
                            "value": {
                                "text": "OK then",
                                "number": 42
                            }
                        }
                    }
                ],
                "probeSets": [],
                "startDate": null,
                "application": "\(xcTestAppId())",
                "bucketConfig": {
                    "count": 10000,
                    "start": 0,
                    "total": 10000,
                    "namespace": "secure-gold",
                    "randomizationUnit": "nimbus_id"
                },
                "userFacingName": "Diagnostic test experiment",
                "referenceBranch": "control",
                "isEnrollmentPaused": false,
                "proposedEnrollment": 7,
                "userFacingDescription": "This is a test experiment for diagnostic purposes.",
                "id": "secure-gold",
                "last_modified": 1602197324372
            }]
        }
        """
    }

    func xcTestAppId() -> String {
        return "com.apple.dt.xctest.tool"
    }

    func createDatabasePath() -> String {
        // For whatever reason, we cannot send a file:// because it'll fail
        // to make the DB both locally and on CI, so we just send the path
        let directory = NSTemporaryDirectory()
        let filename = "testdb-\(UUID().uuidString).db"
        let dbPath = directory + filename
        return dbPath
    }

    func testNimbusCreate() throws {
        let appSettings = NimbusAppSettings(appName: "test", channel: "nightly")
        let nimbusEnabled = try Nimbus.create(nil, appSettings: appSettings, dbPath: createDatabasePath())
        XCTAssert(nimbusEnabled is Nimbus)

        let nimbusDisabled = try Nimbus.create(nil, appSettings: appSettings, dbPath: createDatabasePath(), enabled: false)
        XCTAssert(nimbusDisabled is NimbusDisabled, "Nimbus is disabled if a feature flag disables it")
    }

    func testSmokeTest() throws {
        let appSettings = NimbusAppSettings(appName: "test", channel: "nightly")
        let nimbus = try Nimbus.create(nil, appSettings: appSettings, dbPath: createDatabasePath()) as! Nimbus

        try nimbus.setExperimentsLocallyOnThisThread(minimalExperimentJSON())
        try nimbus.applyPendingExperimentsOnThisThread()

        let branch = nimbus.getExperimentBranch(experimentId: "secure-gold")
        XCTAssertNotNil(branch)
        XCTAssert(branch == "treatment" || branch == "control")

        let experiments = nimbus.getActiveExperiments()
        XCTAssertEqual(experiments.count, 1)

        let json = nimbus.getFeatureConfigVariablesJson(featureId: "aboutwelcome")
        if let json = json {
            XCTAssertEqual(json["text"] as? String, "OK then")
            XCTAssertEqual(json["number"] as? Int, 42)
        } else {
            XCTAssertNotNil(json)
        }

        try nimbus.setExperimentsLocallyOnThisThread(emptyExperimentJSON())
        try nimbus.applyPendingExperimentsOnThisThread()
        let noExperiments = nimbus.getActiveExperiments()
        XCTAssertEqual(noExperiments.count, 0)
    }

    func testSmokeTestAsync() throws {
        let appSettings = NimbusAppSettings(appName: "test", channel: "nightly")
        let nimbus = try Nimbus.create(nil, appSettings: appSettings, dbPath: createDatabasePath()) as! Nimbus

        // We do the same tests as `testSmokeTest` but with the actual calls that
        // the client app will make.
        // This shows that delegating to a background thread is working, and
        // that Rust is callable from a background thread.
        nimbus.setExperimentsLocally(minimalExperimentJSON())
        let job = nimbus.applyPendingExperiments()
        let finishedNormally = job.joinOrTimeout(timeout: 3600.0)
        XCTAssertTrue(finishedNormally)

        let branch = nimbus.getExperimentBranch(experimentId: "secure-gold")
        XCTAssertNotNil(branch)
        XCTAssert(branch == "treatment" || branch == "control")

        let experiments = nimbus.getActiveExperiments()
        XCTAssertEqual(experiments.count, 1)

        nimbus.setExperimentsLocally(emptyExperimentJSON())
        let job1 = nimbus.applyPendingExperiments()
        let finishedNormally1 = job1.joinOrTimeout(timeout: 3600.0)
        XCTAssertTrue(finishedNormally1)

        let noExperiments = nimbus.getActiveExperiments()
        XCTAssertEqual(noExperiments.count, 0)
    }

    func testApplyLocalExperimentsTimedOut() throws {
        let appSettings = NimbusAppSettings(appName: "test", channel: "nightly")
        let nimbus = try Nimbus.create(nil, appSettings: appSettings, dbPath: createDatabasePath()) as! Nimbus

        let job = nimbus.applyLocalExperiments {
            Thread.sleep(forTimeInterval: 5.0)
            return self.minimalExperimentJSON()
        }

        let finishedNormally = job.joinOrTimeout(timeout: 1.0)
        XCTAssertFalse(finishedNormally)

        let noExperiments = nimbus.getActiveExperiments()
        XCTAssertEqual(noExperiments.count, 0)
    }

    func testApplyLocalExperiments() throws {
        let appSettings = NimbusAppSettings(appName: "test", channel: "nightly")
        let nimbus = try Nimbus.create(nil, appSettings: appSettings, dbPath: createDatabasePath()) as! Nimbus

        let job = nimbus.applyLocalExperiments {
            Thread.sleep(forTimeInterval: 0.1)
            return self.minimalExperimentJSON()
        }

        let finishedNormally = job.joinOrTimeout(timeout: 4.0)
        XCTAssertTrue(finishedNormally)

        let noExperiments = nimbus.getActiveExperiments()
        XCTAssertEqual(noExperiments.count, 1)
    }

    func testBuildExperimentContext() throws {
        let appSettings = NimbusAppSettings(appName: "test", channel: "nightly")
        let appContext: AppContext = Nimbus.buildExperimentContext(appSettings)
        NSLog("appContext \(appContext)")
        XCTAssertEqual(appContext.appId, "com.apple.dt.xctest.tool")
        XCTAssertEqual(appContext.deviceManufacturer, "Apple")
        XCTAssertEqual(appContext.os, "iOS")

        if Device.isSimulator() {
            // XCTAssertEqual(appContext.deviceModel, "x86_64")
        }
    }

    func testRecordExperimentTelemetry() throws {
        let appSettings = NimbusAppSettings(appName: "NimbusUnitTest", channel: "test")
        let nimbus = try Nimbus.create(nil, appSettings: appSettings, dbPath: createDatabasePath()) as! Nimbus

        let enrolledExperiments = [EnrolledExperiment(
            featureIds: [],
            slug: "test-experiment",
            userFacingName: "Test Experiment",
            userFacingDescription: "A test experiment for testing experiments",
            branchSlug: "test-branch"
        )]

        nimbus.recordExperimentTelemetry(enrolledExperiments)
        XCTAssertTrue(Glean.shared.testIsExperimentActive("test-experiment"),
                      "Experiment should be active")
        // TODO: Below fails due to branch and extra being private members Glean
        // We will need to change this if we want to remove glean as a submodule and instead
        // consume it as a swift package https://github.com/mozilla/application-services/issues/4864

        // let experimentData = Glean.shared.testGetExperimentData(experimentId: "test-experiment")!
        // XCTAssertEqual("test-branch", experimentData.branch, "Experiment branch must match")
        // XCTAssertEqual("enrollment-id", experimentData.extra["enrollmentId"], "Enrollment id must match")
    }

    func testRecordExperimentEvents() throws {
        let appSettings = NimbusAppSettings(appName: "NimbusUnitTest", channel: "test")
        let nimbus = try Nimbus.create(nil, appSettings: appSettings, dbPath: createDatabasePath()) as! Nimbus

        // Create a list of events to record, one of each type, all associated with the same
        // experiment
        let events = [
            EnrollmentChangeEvent(
                experimentSlug: "test-experiment",
                branchSlug: "test-branch",
                reason: "test-reason",
                change: .enrollment
            ),
            EnrollmentChangeEvent(
                experimentSlug: "test-experiment",
                branchSlug: "test-branch",
                reason: "test-reason",
                change: .unenrollment
            ),
            EnrollmentChangeEvent(
                experimentSlug: "test-experiment",
                branchSlug: "test-branch",
                reason: "test-reason",
                change: .disqualification
            ),
        ]

        // Record the experiment events in Glean
        nimbus.recordExperimentEvents(events)

        // Use the Glean test API to check the recorded events

        // Enrollment
        XCTAssertNotNil(GleanMetrics.NimbusEvents.enrollment.testGetValue(), "Enrollment event must exist")
        let enrollmentEvents = GleanMetrics.NimbusEvents.enrollment.testGetValue()!
        XCTAssertEqual(1, enrollmentEvents.count, "Enrollment event count must match")
        let enrollmentEventExtras = enrollmentEvents.first!.extra
        XCTAssertEqual("test-experiment", enrollmentEventExtras!["experiment"], "Enrollment event experiment must match")
        XCTAssertEqual("test-branch", enrollmentEventExtras!["branch"], "Enrollment event branch must match")

        // Unenrollment
        XCTAssertNotNil(GleanMetrics.NimbusEvents.unenrollment.testGetValue(), "Unenrollment event must exist")
        let unenrollmentEvents = GleanMetrics.NimbusEvents.unenrollment.testGetValue()!
        XCTAssertEqual(1, unenrollmentEvents.count, "Unenrollment event count must match")
        let unenrollmentEventExtras = unenrollmentEvents.first!.extra
        XCTAssertEqual("test-experiment", unenrollmentEventExtras!["experiment"], "Unenrollment event experiment must match")
        XCTAssertEqual("test-branch", unenrollmentEventExtras!["branch"], "Unenrollment event branch must match")

        // Disqualification
        XCTAssertNotNil(GleanMetrics.NimbusEvents.disqualification.testGetValue(), "Disqualification event must exist")
        let disqualificationEvents = GleanMetrics.NimbusEvents.disqualification.testGetValue()!
        XCTAssertEqual(1, disqualificationEvents.count, "Disqualification event count must match")
        let disqualificationEventExtras = disqualificationEvents.first!.extra
        XCTAssertEqual("test-experiment", disqualificationEventExtras!["experiment"], "Disqualification event experiment must match")
        XCTAssertEqual("test-branch", disqualificationEventExtras!["branch"], "Disqualification event branch must match")
    }

    func testRecordFeatureActivation() throws {
        let appSettings = NimbusAppSettings(appName: "NimbusUnitTest", channel: "test")
        let nimbus = try Nimbus.create(nil, appSettings: appSettings, dbPath: createDatabasePath()) as! Nimbus

        // Load an experiment in nimbus that we will record an event in. The experiment bucket configuration
        // is set so that it will be guaranteed to be active. This is necessary because the SDK checks for
        // active experiments before recording.
        try nimbus.setExperimentsLocallyOnThisThread(minimalExperimentJSON())
        try nimbus.applyPendingExperimentsOnThisThread()

        // Assert that there are no events to start with
        XCTAssertNil(GleanMetrics.NimbusEvents.activation.testGetValue(), "Event must not have a value")

        // Record a valid exposure event in Glean that matches the featureId from the test experiment
        // let _ = nimbus.getFeatureConfigVariablesJson(featureId: "aboutwelcome")

        // // Use the Glean test API to check that the valid event is present
        // XCTAssertNotNil(GleanMetrics.NimbusEvents.activation.testGetValue(), "Event must have a value")
        // let events = GleanMetrics.NimbusEvents.activation.testGetValue()!
        // XCTAssertEqual(1, events.count, "Event count must match")
        // let extras = events.first!.extra
        // XCTAssertEqual("secure-gold", extras!["experiment"], "Experiment slug must match")
        // XCTAssertTrue(
        //     extras!["branch"] == "control" || extras!["branch"] == "treatment",
        //     "Experiment branch must match"
        // )
        // XCTAssertEqual("aboutwelcome", extras!["feature_id"], "Feature ID must match")
    }

    func testRecordExposureFromFeature() throws {
        let appSettings = NimbusAppSettings(appName: "NimbusUnitTest", channel: "test")
        let nimbus = try Nimbus.create(nil, appSettings: appSettings, dbPath: createDatabasePath()) as! Nimbus

        // Load an experiment in nimbus that we will record an event in. The experiment bucket configuration
        // is set so that it will be guaranteed to be active. This is necessary because the SDK checks for
        // active experiments before recording.
        try nimbus.setExperimentsLocallyOnThisThread(minimalExperimentJSON())
        try nimbus.applyPendingExperimentsOnThisThread()

        // Assert that there are no events to start with
        XCTAssertNil(GleanMetrics.NimbusEvents.exposure.testGetValue(), "Event must not have a value")

        // Record a valid exposure event in Glean that matches the featureId from the test experiment
        nimbus.recordExposureEvent(featureId: "aboutwelcome")

        // Use the Glean test API to check that the valid event is present
        XCTAssertNotNil(GleanMetrics.NimbusEvents.exposure.testGetValue(), "Event must have a value")
        let exposureEvents = GleanMetrics.NimbusEvents.exposure.testGetValue()!
        XCTAssertEqual(1, exposureEvents.count, "Event count must match")
        let exposureEventExtras = exposureEvents.first!.extra
        XCTAssertEqual("secure-gold", exposureEventExtras!["experiment"], "Experiment slug must match")
        XCTAssertTrue(
            exposureEventExtras!["branch"] == "control" || exposureEventExtras!["branch"] == "treatment",
            "Experiment branch must match"
        )

        // Attempt to record an event for a non-existent or feature we are not enrolled in an
        // experiment in to ensure nothing is recorded.
        nimbus.recordExposureEvent(featureId: "not-a-feature")

        // Verify the invalid event was ignored by checking again that the valid event is still the only
        // event, and that it hasn't changed any of its extra properties.
        let exposureEventsTryTwo = GleanMetrics.NimbusEvents.exposure.testGetValue()!
        XCTAssertEqual(1, exposureEventsTryTwo.count, "Event count must match")
        let exposureEventExtrasTryTwo = exposureEventsTryTwo.first!.extra
        XCTAssertEqual("secure-gold", exposureEventExtrasTryTwo!["experiment"], "Experiment slug must match")
        XCTAssertTrue(
            exposureEventExtrasTryTwo!["branch"] == "control" || exposureEventExtrasTryTwo!["branch"] == "treatment",
            "Experiment branch must match"
        )
    }

    func testRecordExposureFromExperiment() throws {
        let appSettings = NimbusAppSettings(appName: "NimbusUnitTest", channel: "test")
        let nimbus = try Nimbus.create(nil, appSettings: appSettings, dbPath: createDatabasePath()) as! Nimbus

        // Load an experiment in nimbus that we will record an event in. The experiment bucket configuration
        // is set so that it will be guaranteed to be active. This is necessary because the SDK checks for
        // active experiments before recording.
        try nimbus.setExperimentsLocallyOnThisThread(minimalExperimentJSON())
        try nimbus.applyPendingExperimentsOnThisThread()

        // Assert that there are no events to start with
        XCTAssertNil(GleanMetrics.NimbusEvents.exposure.testGetValue(), "Event must not have a value")

        // Record a valid exposure event in Glean that matches the featureId from the test experiment
        nimbus.recordExposureEvent(featureId: "aboutwelcome", experimentSlug: "secure-gold")

        // Use the Glean test API to check that the valid event is present
        XCTAssertNotNil(GleanMetrics.NimbusEvents.exposure.testGetValue(), "Event must have a value")
        let exposureEvents = GleanMetrics.NimbusEvents.exposure.testGetValue()!
        XCTAssertEqual(1, exposureEvents.count, "Event count must match")
        let exposureEventExtras = exposureEvents.first!.extra
        XCTAssertEqual("secure-gold", exposureEventExtras!["experiment"], "Experiment slug must match")
        XCTAssertTrue(
            exposureEventExtras!["branch"] == "control" || exposureEventExtras!["branch"] == "treatment",
            "Experiment branch must match"
        )

        // Attempt to record an event for a non-existent or feature we are not enrolled in an
        // experiment in to ensure nothing is recorded.
        nimbus.recordExposureEvent(featureId: "aboutwelcome", experimentSlug: "not-an-experiment")

        // Verify the invalid event was ignored by checking again that the valid event is still the only
        // event, and that it hasn't changed any of its extra properties.
        let exposureEventsTryTwo = GleanMetrics.NimbusEvents.exposure.testGetValue()!
        XCTAssertEqual(1, exposureEventsTryTwo.count, "Event count must match")
        let exposureEventExtrasTryTwo = exposureEventsTryTwo.first!.extra
        XCTAssertEqual("secure-gold", exposureEventExtrasTryTwo!["experiment"], "Experiment slug must match")
        XCTAssertTrue(
            exposureEventExtrasTryTwo!["branch"] == "control" || exposureEventExtrasTryTwo!["branch"] == "treatment",
            "Experiment branch must match"
        )
    }

    func testRecordMalformedConfiguration() throws {
        let appSettings = NimbusAppSettings(appName: "NimbusUnitTest", channel: "test")
        let nimbus = try Nimbus.create(nil, appSettings: appSettings, dbPath: createDatabasePath()) as! Nimbus

        // Load an experiment in nimbus that we will record an event in. The experiment bucket configuration
        // is set so that it will be guaranteed to be active. This is necessary because the SDK checks for
        // active experiments before recording.
        try nimbus.setExperimentsLocallyOnThisThread(minimalExperimentJSON())
        try nimbus.applyPendingExperimentsOnThisThread()

        // Record a valid exposure event in Glean that matches the featureId from the test experiment
        nimbus.recordMalformedConfiguration(featureId: "aboutwelcome", with: "detail")

        // Use the Glean test API to check that the valid event is present
        XCTAssertNotNil(GleanMetrics.NimbusEvents.malformedFeature.testGetValue(), "Event must have a value")
        let events = GleanMetrics.NimbusEvents.malformedFeature.testGetValue()!
        XCTAssertEqual(1, events.count, "Event count must match")
        let extras = events.first!.extra
        XCTAssertEqual("secure-gold", extras!["experiment"], "Experiment slug must match")
        XCTAssertTrue(
            extras!["branch"] == "control" || extras!["branch"] == "treatment",
            "Experiment branch must match"
        )
        XCTAssertEqual("detail", extras!["part_id"], "Part identifier should match")
        XCTAssertEqual("aboutwelcome", extras!["feature_id"], "Feature identifier should match")
    }

    func testRecordDisqualificationOnOptOut() throws {
        let appSettings = NimbusAppSettings(appName: "NimbusUnitTest", channel: "test")
        let nimbus = try Nimbus.create(nil, appSettings: appSettings, dbPath: createDatabasePath()) as! Nimbus

        // Load an experiment in nimbus that we will record an event in. The experiment bucket configuration
        // is set so that it will be guaranteed to be active. This is necessary because the SDK checks for
        // active experiments before recording.
        try nimbus.setExperimentsLocallyOnThisThread(minimalExperimentJSON())
        try nimbus.applyPendingExperimentsOnThisThread()

        // Assert that there are no events to start with
        XCTAssertNil(GleanMetrics.NimbusEvents.exposure.testGetValue(), "Event must not have a value")

        // Opt out of the experiment, which should generate a "disqualification" event
        try nimbus.optOutOnThisThread("secure-gold")

        // Use the Glean test API to check that the valid event is present
        XCTAssertNotNil(GleanMetrics.NimbusEvents.disqualification.testGetValue(), "Event must have a value")
        let disqualificationEvents = GleanMetrics.NimbusEvents.disqualification.testGetValue()!
        XCTAssertEqual(1, disqualificationEvents.count, "Event count must match")
        let disqualificationEventExtras = disqualificationEvents.first!.extra
        XCTAssertEqual("secure-gold", disqualificationEventExtras!["experiment"], "Experiment slug must match")
        XCTAssertTrue(
            disqualificationEventExtras!["branch"] == "control" || disqualificationEventExtras!["branch"] == "treatment",
            "Experiment branch must match"
        )
    }

    func testRecordDisqualificationOnGlobalOptOut() throws {
        let appSettings = NimbusAppSettings(appName: "NimbusUnitTest", channel: "test")
        let nimbus = try Nimbus.create(nil, appSettings: appSettings, dbPath: createDatabasePath()) as! Nimbus

        // Load an experiment in nimbus that we will record an event in. The experiment bucket configuration
        // is set so that it will be guaranteed to be active. This is necessary because the SDK checks for
        // active experiments before recording.
        try nimbus.setExperimentsLocallyOnThisThread(minimalExperimentJSON())
        try nimbus.applyPendingExperimentsOnThisThread()

        // Assert that there are no events to start with
        XCTAssertNil(GleanMetrics.NimbusEvents.exposure.testGetValue(), "Event must not have a value")

        // Opt out of all experiments, which should generate a "disqualification" event for the enrolled
        // experiment
        try nimbus.setExperimentParticipationOnThisThread(false)

        // Use the Glean test API to check that the valid event is present
        XCTAssertNotNil(GleanMetrics.NimbusEvents.disqualification.testGetValue(), "Event must have a value")
        let disqualificationEvents = GleanMetrics.NimbusEvents.disqualification.testGetValue()!
        XCTAssertEqual(1, disqualificationEvents.count, "Event count must match")
        let disqualificationEventExtras = disqualificationEvents.first!.extra
        XCTAssertEqual("secure-gold", disqualificationEventExtras!["experiment"], "Experiment slug must match")
        XCTAssertTrue(
            disqualificationEventExtras!["branch"] == "control" || disqualificationEventExtras!["branch"] == "treatment",
            "Experiment branch must match"
        )
    }

    func testNimbusCreateWithJson() throws {
        let appSettings = NimbusAppSettings(appName: "test", channel: "nightly", customTargetingAttributes: ["is_first_run": false, "is_test": true])
        let nimbus = try Nimbus.create(nil, appSettings: appSettings, dbPath: createDatabasePath())
        let helper = try nimbus.createMessageHelper()

        XCTAssertTrue(try helper.evalJexl(expression: "is_test"))
        XCTAssertFalse(try helper.evalJexl(expression: "is_first_run"))
    }

    class TestRecordedContext: RecordedContext, @unchecked Sendable {
        var recorded: [[String: Any]] = []
        var enabled: Bool
        var eventQueries: [String: String]? = nil
        var eventQueryValues: [String: Double]? = nil

        init(enabled: Bool = true, eventQueries: [String: String]? = nil) {
            self.enabled = enabled
            self.eventQueries = eventQueries
        }

        func getEventQueries() -> [String: String] {
            if let queries = eventQueries {
                return queries
            } else {
                return [:]
            }
        }

        func setEventQueryValues(eventQueryValues: [String: Double]) {
            self.eventQueryValues = eventQueryValues
        }

        func toJson() -> MozillaAppServices.JsonObject {
            do {
                return try String(data: JSONSerialization.data(withJSONObject: [
                    "enabled": enabled,
                    "events": eventQueries as Any,
                ] as Any), encoding: .ascii) ?? "{}" as MozillaAppServices.JsonObject
            } catch {
                print(error.localizedDescription)
                return "{}"
            }
        }

        func record() {
            recorded.append(["enabled": enabled, "events": eventQueryValues as Any])
        }
    }

    func testNimbusRecordsRecordedContextObject() throws {
        let recordedContext = TestRecordedContext()
        let appSettings = NimbusAppSettings(appName: "test", channel: "nightly")
        let nimbus = try Nimbus.create(nil, appSettings: appSettings, dbPath: createDatabasePath(), recordedContext: recordedContext) as! Nimbus

        try nimbus.setExperimentsLocallyOnThisThread(minimalExperimentJSON())
        try nimbus.applyPendingExperimentsOnThisThread()

        XCTAssertEqual(1, recordedContext.recorded.count)
        print(recordedContext.recorded)
        XCTAssertEqual(true, recordedContext.recorded.first!["enabled"] as! Bool)
    }

    func testNimbusRecordedContextEventQueriesAreRunAndTheValueIsWrittenBackIntoTheObject() throws {
        let recordedContext = TestRecordedContext(eventQueries: ["TEST_QUERY": "'event'|eventSum('Days', 1, 0)"])
        let appSettings = NimbusAppSettings(appName: "test", channel: "nightly")
        let nimbus = try Nimbus.create(nil, appSettings: appSettings, dbPath: createDatabasePath(), recordedContext: recordedContext) as! Nimbus

        try nimbus.setExperimentsLocallyOnThisThread(minimalExperimentJSON())
        try nimbus.applyPendingExperimentsOnThisThread()

        XCTAssertEqual(1, recordedContext.recorded.count)
        XCTAssertEqual(true, recordedContext.recorded.first!["enabled"] as! Bool)
        XCTAssertEqual(0, (recordedContext.recorded.first!["events"] as! [String: Any])["TEST_QUERY"] as! Double)
    }

    func testNimbusRecordedContextEventQueriesAreValidated() throws {
        let recordedContext = TestRecordedContext(eventQueries: ["TEST_QUERY": "'event'|eventSumThisWillFail('Days', 1, 0)"])

        XCTAssertThrowsError(try validateEventQueries(recordedContext: recordedContext))
    }

    func testNimbusCanObtainCalculatedAttributes() throws {
        let appSettings = NimbusAppSettings(appName: "test", channel: "nightly")
        let databasePath = createDatabasePath()
        _ = try Nimbus.create(nil, appSettings: appSettings, dbPath: databasePath) as! Nimbus

        let calculatedAttributes = try getCalculatedAttributes(installationDate: Int64(Date().timeIntervalSince1970 * 1000) - (86_400_000 * 5), dbPath: databasePath, locale: getLocaleTag())

        XCTAssertEqual(5, calculatedAttributes.daysSinceInstall)
        XCTAssertEqual(0, calculatedAttributes.daysSinceUpdate)
        XCTAssertEqual("en", calculatedAttributes.language)
        XCTAssertEqual("US", calculatedAttributes.region)
    }

    func testRecordEnrollmentStatuses() throws {
        let metricConfig = """
            {
                "metrics_enabled": {
                    "nimbus_events.enrollment_status": true
                }
            }
        """
        Glean.shared.applyServerKnobsConfig(metricConfig)

        var events: [RecordedEvent]?
        let expectation = expectation(description: "The nimbus targeting context ping was sent")
        GleanMetrics.Pings.shared.nimbusTargetingContext.testBeforeNextSubmit { e in
            events = GleanMetrics.NimbusEvents.enrollmentStatus.testGetValue()
            expectation.fulfill()
        }

        let metricsHandler = GleanMetricsHandler()
        metricsHandler.recordEnrollmentStatuses(enrollmentStatusExtras: [
            EnrollmentStatusExtraDef(
                branch: "branch",
                conflictSlug: "conflictSlug",
                errorString: "errorString",
                reason: "reason",
                slug: "slug",
                status: "status",
                prevGeckoPrefStates: nil
            )
        ])
        metricsHandler.submitTargetingContext()

        wait(for: [expectation], timeout: 5.0)

        XCTAssertEqual(
            events?.map { $0.extra },
            [[
                "branch": "branch",
                "conflict_slug": "conflictSlug",
                "error_string": "errorString",
                "reason": "reason",
                "slug": "slug",
                "status": "status"
            ]]
        )
    }
}

private extension Device {
    static func isSimulator() -> Bool {
        return ProcessInfo.processInfo.environment["SIMULATOR_ROOT"] != nil
    }
}
