/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import XCTest
@testable import Client
import Shared
import Storage

class ActivityStreamTests: XCTestCase {
    var profile: Profile!
    var panel: ActivityStreamPanel!
    var mockPingClient: MockPingClient!
    var telemetry: ActivityStreamTracker!

    override func setUp() {
        super.setUp()
        self.profile = MockProfile()
        self.telemetry = ActivityStreamTracker(eventsTracker: MockPingClient(), sessionsTracker: MockPingClient())
        self.panel = ActivityStreamPanel(profile: profile, telemetry: self.telemetry)
    }

    override func tearDown() {
        mockPingClient = nil
    }

    func testDeletionOfSingleSuggestedSite() {
        let siteToDelete = panel.defaultTopSites()[0]

        panel.hideURLFromTopSites(URL(string: siteToDelete.url)!)
        let newSites = panel.defaultTopSites()

        XCTAssertFalse(newSites.contains(siteToDelete, f: { (a, b) -> Bool in
            return a.url == b.url
        }))
    }

    func testDeletionOfAllDefaultSites() {
        let defaultSites = panel.defaultTopSites()
        defaultSites.forEach({
            panel.hideURLFromTopSites(URL(string: $0.url)!)
        })

        let newSites = panel.defaultTopSites()
        XCTAssertTrue(newSites.isEmpty)
    }
}

// MARK: Telemetry Tests
extension ActivityStreamTests {
    fileprivate func expectedPayloadForEvent(_ event: String, source: String, position: Int) -> [String: Any] {
        return [
            "event": event,
            "page": "NEW_TAB",
            "source": source,
            "action_position": position,
            "app_version": AppInfo.appVersion,
            "build": AppInfo.buildNumber,
            "locale": Locale.current.identifier,
            "release_channel": AppConstants.BuildChannel.rawValue
        ]
    }

    fileprivate func assertPayload(_ actual: [String: Any], matches: [String: Any]) {
        XCTAssertTrue(actual.count == matches.count)
        actual.enumerated().forEach { index, element in
            if let actualValue = element.1 as? Int,
               let matchesValue = matches[element.0] as? Int {
                XCTAssertTrue(actualValue == matchesValue)
            }

            if let actualValue = element.1 as? String,
               let matchesValue = matches[element.0] as? String {
                XCTAssertTrue(actualValue == matchesValue)
            }
        }
    }
    
    func testHighlightEmitsEventOnTap() {
        let mockSite = Site(url: "http://mozilla.org", title: "Mozilla")
        panel.highlights = [mockSite]
        panel.selectItemAtIndex(0, inSection: .highlights)

        let pingsSent = (telemetry.eventsTracker as! MockPingClient).pingsReceived
        XCTAssertEqual(pingsSent.count, 1)
        let eventPing = pingsSent[0]
        assertPayload(eventPing, matches: expectedPayloadForEvent("CLICK", source: "HIGHLIGHTS", position: 0))
    }

    func testContextMenuOnTopSiteEmitsRemoveEvent() {
        let mockSite = Site(url: "http://mozilla.org", title: "Mozilla")
        let topSitesContextMenu = panel.contextMenuForSite(mockSite, atIndex: 0, forSection: .topSites)

        let removeAction = topSitesContextMenu?.actions.find { $0.title == Strings.RemoveFromASContextMenuTitle }
        removeAction?.handler?(removeAction!)

        let pingsSent = (telemetry.eventsTracker as! MockPingClient).pingsReceived
        XCTAssertEqual(pingsSent.count, 1)
        let removePing = pingsSent[0]
        assertPayload(removePing, matches: expectedPayloadForEvent("DISMISS", source: "TOP_SITES", position: 0))
    }

    func testContextMenuOnHighlightsEmitsRemoveDismissEvents() {
        let mockSite = Site(url: "http://mozilla.org", title: "Mozilla")
        let highlightsContextMenu = panel.contextMenuForSite(mockSite, atIndex: 0, forSection: .highlights)

        let dismiss = highlightsContextMenu?.actions.find { $0.title == Strings.RemoveFromASContextMenuTitle }
        let delete = highlightsContextMenu?.actions.find { $0.title == Strings.DeleteFromHistoryContextMenuTitle }

        dismiss?.handler?(dismiss!)
        delete?.handler?(delete!)

        // Check to see that they emitted telemetry events
        let pingsSent = (telemetry.eventsTracker as! MockPingClient).pingsReceived
        XCTAssertEqual(pingsSent.count, 2)

        let dismissPing = pingsSent[0]
        assertPayload(dismissPing, matches: expectedPayloadForEvent("DISMISS", source: "HIGHLIGHTS", position: 0))

        let deletePing = pingsSent[1]
        assertPayload(deletePing, matches: expectedPayloadForEvent("DELETE", source: "HIGHLIGHTS", position: 0))
    }

    func testSessionReportedWhenViewAppearsAndDisappears() {
        // Simulate the panel opening and closing with a second in between for some session_duration
        panel.viewWillAppear(false)
        var pingsSent = (telemetry.sessionsTracker as! MockPingClient).pingsReceived
        XCTAssertEqual(pingsSent.count, 0)

        wait(1)
        panel.viewDidDisappear(false)

        pingsSent = (telemetry.sessionsTracker as! MockPingClient).pingsReceived
        XCTAssertEqual(pingsSent.count, 1)

        let eventPing = pingsSent[0]
        XCTAssertNotNil(eventPing["session_duration"])
    }
}

class MockPingClient: PingCentreClient {

    var pingsReceived: [[String: Any]] = []

    public func sendPing(_ data: [String : Any], validate: Bool) -> Success {
        pingsReceived.append(data)
        return succeed()
    }
}
