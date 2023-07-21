// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Glean

@testable import Client
import MozillaAppServices

class GleanPlumbMessageManagerTests: XCTestCase {
    var subject: GleanPlumbMessageManager!
    var messagingStore: MockGleanPlumbMessageStore!
    var applicationHelper: MockApplicationHelper!
    let messageId = "testId"

    override func setUp() {
        super.setUp()

        Glean.shared.resetGlean(clearStores: true)
        Glean.shared.enableTestingMode()
        messagingStore = MockGleanPlumbMessageStore(messageId: messageId)
        applicationHelper = MockApplicationHelper()
        subject = GleanPlumbMessageManager(
            helperUtility: MockNimbusMessagingHelperUtility(),
            messagingStore: messagingStore,
            applicationHelper: applicationHelper,
            messagingFeature: FxNimbus.shared.features.messaging
        )
    }

    override func tearDown() {
        super.tearDown()

        messagingStore = nil
        subject = nil
    }

    func testMessagingFeatureIsCoenrolling() {
        XCTAssertTrue(FxNimbus.shared.getCoenrollingFeatureIds().contains("messaging"))
    }

    func testManagerGetMessage() {
        let hardcodedNimbusFeatures =
            HardcodedNimbusFeatures(with: [
                "messaging": [
                    "messages": [
                        "default-browser": [
                            "trigger": ["ALWAYS"]
                        ]
                    ]
                ]
            ]
        )
        hardcodedNimbusFeatures.connect(with: FxNimbus.shared)

        guard let message = subject.getNextMessage(for: .newTabCard) else {
            XCTFail("Expected to retrieve message")
            return
        }

        subject.onMessageDisplayed(message)
        testEventMetricRecordingSuccess(metric: GleanMetrics.Messaging.shown)
        XCTAssertEqual(hardcodedNimbusFeatures.getExposureCount(featureId: "messaging"), 0)
    }

    func testManagerGetMessage_happyPath_bySurface() throws {
        let hardcodedNimbusFeatures = HardcodedNimbusFeatures(with: ["messaging": "{}"])
        hardcodedNimbusFeatures.connect(with: FxNimbus.shared)

        let expectedId = "infoCard"
        let messages = [
            createMessage(messageId: "notification", surface: .notification),
            createMessage(messageId: expectedId, surface: .newTabCard)
        ]
        guard let observed = subject.getNextMessage(for: .newTabCard, availableMessages: messages) else {
            XCTFail("Expected to retrieve message")
            return
        }
        XCTAssertEqual(observed.id, expectedId)
        XCTAssertEqual(hardcodedNimbusFeatures.getExposureCount(featureId: "messaging"), 0)
    }

    func testManagerGetMessage_happyPath_byTrigger() throws {
        let expectedId = "infoCard"
        let messages = [
            createMessage(messageId: "infoCard-notyet", surface: .newTabCard, trigger: ["false"]),
            createMessage(messageId: expectedId, surface: .newTabCard)
        ]
        guard let observed = subject.getNextMessage(for: .newTabCard, availableMessages: messages) else {
            XCTFail("Expected to retrieve message")
            return
        }
        XCTAssertEqual(observed.id, expectedId)
    }

    func testManagerGetMessage_happyPath_byMultipleTriggers() throws {
        let expectedId = "infoCard"
        let messages = [
            // The  trigger expressions _all_ have to be true in order for the messsage to be shown.
            createMessage(messageId: "infoCard-notyet", surface: .newTabCard, trigger: ["true", "false"]),
            createMessage(messageId: expectedId, surface: .newTabCard, trigger: ["true", "true"])
        ]
        guard let observed = subject.getNextMessage(for: .newTabCard, availableMessages: messages) else {
            XCTFail("Expected to retrieve message")
            return
        }
        XCTAssertEqual(observed.id, expectedId)
    }

    func testManagerGetMessage_experiments_exposureEvents() throws {
        let hardcodedNimbusFeatures = HardcodedNimbusFeatures(with: ["messaging": "{}"])
        hardcodedNimbusFeatures.connect(with: FxNimbus.shared)

        let expectedId = "infoCard"
        let experiment = "my-experiment"
        let messages = [
            createMessage(messageId: expectedId, surface: .newTabCard, experiment: experiment)
        ]
        guard let observed = subject.getNextMessage(for: .newTabCard, availableMessages: messages) else {
            XCTFail("Expected to retrieve message")
            return
        }
        XCTAssertEqual(observed.id, expectedId)

        XCTAssertEqual(hardcodedNimbusFeatures.getExposureCount(featureId: "messaging"), 1)
    }

    func testManagerGetMessage_experiments_controlMessages() throws {
        let hardcodedNimbusFeatures = HardcodedNimbusFeatures(with: ["messaging": "{}"])
        hardcodedNimbusFeatures.connect(with: FxNimbus.shared)

        XCTAssertEqual(messagingStore.getMessageMetadata(messageId: "control").impressions, 0)

        let expectedId = "infoCard"
        let experiment = "my-experiment"
        let messages = [
            createMessage(messageId: "control", surface: .newTabCard, experiment: experiment, isControl: true),
            createMessage(messageId: expectedId, surface: .newTabCard)
        ]
        guard let observed = subject.getNextMessage(for: .newTabCard, availableMessages: messages) else {
            XCTFail("Expected to retrieve message")
            return
        }
        XCTAssertEqual(observed.id, expectedId)

        XCTAssertEqual(messagingStore.getMessageMetadata(messageId: "control").impressions, 1)

        XCTAssertEqual(hardcodedNimbusFeatures.getExposureCount(featureId: "messaging"), 1)
    }

    func testManagerGetMessage_experiments_malformedControlMessages() throws {
        let hardcodedNimbusFeatures = HardcodedNimbusFeatures(with: ["messaging": "{}"])
        hardcodedNimbusFeatures.connect(with: FxNimbus.shared)

        XCTAssertEqual(messagingStore.getMessageMetadata(messageId: "control").impressions, 0)

        let expectedId = "infoCard"
        let messages = [
            createMessage(messageId: "control", surface: .newTabCard, isControl: true),
            createMessage(messageId: expectedId, surface: .newTabCard)
        ]
        guard let observed = subject.getNextMessage(for: .newTabCard, availableMessages: messages) else {
            XCTFail("Expected to retrieve message")
            return
        }
        XCTAssertEqual(observed.id, expectedId)

        XCTAssertEqual(messagingStore.getMessageMetadata(messageId: "control").impressions, 1)

        XCTAssertEqual(hardcodedNimbusFeatures.getExposureCount(featureId: "messaging"), 0)
        XCTAssertEqual(hardcodedNimbusFeatures.getMalformed(for: "messaging"), "control")
    }

    func testManagerGetMessage_experiments_multiplControlMessages() throws {
        let hardcodedNimbusFeatures = HardcodedNimbusFeatures(with: ["messaging": "{}"])
        hardcodedNimbusFeatures.connect(with: FxNimbus.shared)

        XCTAssertEqual(messagingStore.getMessageMetadata(messageId: "control-1").impressions, 0)
        XCTAssertEqual(messagingStore.getMessageMetadata(messageId: "control-2").impressions, 0)

        let expectedId = "infoCard"
        let experiment = "my-experiment"
        let messages = [
            createMessage(messageId: "control-1", surface: .newTabCard, experiment: experiment, isControl: true),
            createMessage(messageId: "control-2", surface: .newTabCard, experiment: experiment, isControl: true),
            createMessage(messageId: expectedId, surface: .newTabCard)
        ]
        guard let observed = subject.getNextMessage(for: .newTabCard, availableMessages: messages) else {
            XCTFail("Expected to retrieve message")
            return
        }
        XCTAssertEqual(observed.id, expectedId)

        XCTAssertEqual(messagingStore.getMessageMetadata(messageId: "control-1").impressions, 1)
        XCTAssertEqual(messagingStore.getMessageMetadata(messageId: "control-2").impressions, 1)

        XCTAssertEqual(hardcodedNimbusFeatures.getExposureCount(featureId: "messaging"), 2)
    }

    func testManagerOnMessageDisplayed() {
        let message = createMessage(messageId: messageId)
        subject.onMessageDisplayed(message)
        let messageMetadata = messagingStore.getMessageMetadata(messageId: messageId)
        XCTAssertFalse(messageMetadata.isExpired)
        XCTAssertEqual(messageMetadata.impressions, 1)
        testEventMetricRecordingSuccess(metric: GleanMetrics.Messaging.shown)
    }

    func testManagerOnMessagePressed() {
        let message = createMessage(messageId: messageId, action: "://test-action")
        subject.onMessagePressed(message)
        let messageMetadata = messagingStore.getMessageMetadata(messageId: messageId)
        XCTAssertTrue(messageMetadata.isExpired)
        XCTAssertEqual(applicationHelper.openURLCalled, 1)
        testEventMetricRecordingSuccess(metric: GleanMetrics.Messaging.clicked)
    }

    func testManagerOnMessagePressed_withWebpage() {
        let message = createMessage(messageId: messageId, action: "https://mozilla.com")
        subject.onMessagePressed(message)
        let messageMetadata = messagingStore.getMessageMetadata(messageId: messageId)
        XCTAssertTrue(messageMetadata.isExpired)
        XCTAssertEqual(applicationHelper.openURLCalled, 1)
        XCTAssertNotNil(applicationHelper.lastOpenURL)
        XCTAssertEqual(applicationHelper.lastOpenURL?.absoluteString.hasPrefix(URL.mozInternalScheme), true)
        testEventMetricRecordingSuccess(metric: GleanMetrics.Messaging.clicked)
    }

    func testManagerOnMessagePressed_withMalformedURL() {
        let message = createMessage(messageId: messageId, action: "http://www.google.com?q=א")
        subject.onMessagePressed(message)
        let messageMetadata = messagingStore.getMessageMetadata(messageId: messageId)
        XCTAssertTrue(messageMetadata.isExpired)
        XCTAssertEqual(applicationHelper.openURLCalled, 0)
        XCTAssertNil(applicationHelper.lastOpenURL)
        testEventMetricRecordingSuccess(metric: GleanMetrics.Messaging.malformed)
    }

    func testManagerOnMessageDismissed() {
        let message = createMessage(messageId: messageId)
        subject.onMessageDismissed(message)
        let messageMetadata = messagingStore.getMessageMetadata(messageId: messageId)
        XCTAssertEqual(messageMetadata.dismissals, 1)
        XCTAssertTrue(messageMetadata.isExpired)
        testEventMetricRecordingSuccess(metric: GleanMetrics.Messaging.dismissed)
    }

    // MARK: - Helper function

    private func createMessage(messageId: String,
                               action: String = "MAKE_DEFAULT_BROWSER",
                               surface: MessageSurfaceId = .newTabCard,
                               trigger: [String] = ["true"],
                               experiment: String? = nil,
                               isControl: Bool = false,
                               maxDisplayCount: Int = 3
    ) -> GleanPlumbMessage {
        let styleData = MockStyleData(priority: 50, maxDisplayCount: maxDisplayCount)

        let messageMetadata = GleanPlumbMessageMetaData(id: messageId,
                                                        impressions: 0,
                                                        dismissals: 0,
                                                        isExpired: false)
        let data = MessageData(
            action: action,
            buttonLabel: "buttonLabel-\(messageId)",
            experiment: experiment,
            isControl: isControl,
            style: "DEFAULT",
            surface: surface,
            text: "text-\(messageId)",
            title: "title-\(messageId)",
            trigger: trigger)

        return GleanPlumbMessage(id: messageId,
                                 data: data,
                                 action: action,
                                 triggers: trigger,
                                 style: styleData,
                                 metadata: messageMetadata)
    }
}

// MARK: - MockGleanPlumbMessageStore
class MockGleanPlumbMessageStore: GleanPlumbMessageStoreProtocol {
    private var metadatas = [String: GleanPlumbMessageMetaData]()
    var messageId: String

    var maxImpression = 3

    init(messageId: String) {
        self.messageId = messageId
    }

    func metadata(for message: GleanPlumbMessage) -> GleanPlumbMessageMetaData {
        return metadata(for: message.id)
    }

    func metadata(for id: String) -> GleanPlumbMessageMetaData {
        if let data = metadatas[id] {
            return data
        }
        metadatas[id] = GleanPlumbMessageMetaData(
            id: messageId,
            impressions: 0,
            dismissals: 0,
            isExpired: false)
        return metadata(for: id)
    }

    func getMessageMetadata(messageId: String) -> GleanPlumbMessageMetaData {
        return metadata(for: messageId)
    }

    func onMessageDisplayed(_ message: GleanPlumbMessage) {
        let metadata = metadata(for: message)
        metadata.impressions += 1

        if metadata.impressions > maxImpression {
            onMessageExpired(metadata, surface: message.surface, shouldReport: true)
        }
    }

    func onMessagePressed(_ message: GleanPlumbMessage) {
        let metadata = metadata(for: message)
        onMessageExpired(metadata, surface: message.surface, shouldReport: false)
    }

    func onMessageDismissed(_ message: GleanPlumbMessage) {
        let metadata = metadata(for: message)
        metadata.dismissals += 1
        onMessageExpired(metadata, surface: message.surface, shouldReport: false)
    }

    func onMessageExpired(_ metadata: GleanPlumbMessageMetaData, surface: MessageSurfaceId, shouldReport: Bool) {
        metadata.isExpired = true
    }
}
