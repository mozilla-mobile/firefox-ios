// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Storage
import XCTest

@testable import Client

class ZoomPageManagerTests: XCTestCase {
    private var profile: MockProfile!
    private var zoomStore: MockZoomStore!
    private let windowUUID: WindowUUID = .XCTestDefaultUUID

    override func setUp() async throws {
        try await super.setUp()
        self.profile = MockProfile()
        self.zoomStore = MockZoomStore()
        await DependencyHelperMock().bootstrapDependencies()
    }

    override func tearDown() async throws {
        self.profile = nil
        self.zoomStore = nil
        DependencyHelperMock().reset()
        try await super.tearDown()
    }

    @MainActor
    func testTabNil_AfterInit() {
        let subject = createSubject()
        XCTAssertNil(subject.tab)
    }

    @MainActor
    func testTabNotNil_WhenTabGainFocus() {
        let subject = createSubject()
        let tab = createTab()
        subject.tabDidGainFocus(tab)

        XCTAssertNotNil(subject.tab)
    }

    @MainActor
    func testTabZoomChange_WhenZoomInIsCalled() {
        let subject = createSubject()
        let tab = createTab()
        subject.tabDidGainFocus(tab)
        let newZoom = subject.zoomIn()
        let expectedZoom = 1.1

        XCTAssertEqual(newZoom, expectedZoom)
        XCTAssertEqual(tab.pageZoom, expectedZoom)
    }

    @MainActor
    func testTabZoomChange_WhenZoomOutIsCalled() {
        let subject = createSubject()
        let tab = createTab()
        subject.tabDidGainFocus(tab)
        let newZoom = subject.zoomOut()
        let expectedZoom = 0.9

        XCTAssertEqual(newZoom, expectedZoom)
        XCTAssertEqual(tab.pageZoom, expectedZoom)
    }

    @MainActor
    func testTabZoomReset_WhenResetZoomIsCalled() {
        let subject = createSubject()
        let tab = createTab()
        subject.tabDidGainFocus(tab)
        subject.resetZoom()
        let expectedZoom = ZoomConstants.defaultZoomLimit

        XCTAssertEqual(tab.pageZoom, expectedZoom)
    }

    @MainActor
    func testTabZoomDoesntChange_WhenZoomInIsCalledForUpperLimit() {
        let subject = createSubject()
        let domainZoomLevel = DomainZoomLevel(host: "www.website.com",
                                              zoomLevel: ZoomConstants.upperZoomLimit)
        zoomStore.saveDomainZoom(domainZoomLevel, completion: nil)
        let tab = createTab()
        subject.tabDidGainFocus(tab)
        let newZoom = subject.zoomIn()
        let expectedZoom = ZoomConstants.upperZoomLimit

        XCTAssertEqual(newZoom, expectedZoom)
        XCTAssertEqual(tab.pageZoom, expectedZoom)
    }

    @MainActor
    func testTabZoomDoesntChange_WhenZoomOutIsCalledForLowerLimit() {
        let subject = createSubject()
        let domainZoomLevel = DomainZoomLevel(host: "www.website.com",
                                              zoomLevel: ZoomConstants.lowerZoomLimit)
        zoomStore.saveDomainZoom(domainZoomLevel, completion: nil)
        let tab = createTab()
        subject.tabDidGainFocus(tab)
        let newZoom = subject.zoomOut()
        let expectedZoom = ZoomConstants.lowerZoomLimit

        XCTAssertEqual(newZoom, expectedZoom)
        XCTAssertEqual(tab.pageZoom, expectedZoom)
    }

    @MainActor
    func testZoomStoreSaved_WhenZoomInIsCalled() {
        let subject = createSubject()
        let tab = createTab()
        subject.tabDidGainFocus(tab)
        _ = subject.zoomIn()

        XCTAssertEqual(zoomStore.saveCalledCount, 1)
    }

    @MainActor
    func testZoomStoreSaved_WhenZoomResetIsCalled() {
        let subject = createSubject()
        let tab = createTab()
        subject.tabDidGainFocus(tab)
        subject.resetZoom()

        XCTAssertEqual(zoomStore.saveCalledCount, 1)
    }

    @MainActor
    func testFindZoomStore_WhenZoomInIsCalled() {
        let subject = createSubject()
        let tab = createTab()
        subject.tabDidGainFocus(tab)

        // When the tab is set we check if there is zoom level and set it
        XCTAssertEqual(zoomStore.findZoomLevelCalledCount, 1)
    }

    // MARK: - Private
    @MainActor
    private func createSubject() -> ZoomPageManager {
        let subject = ZoomPageManager(windowUUID: .XCTestDefaultUUID,
                                      zoomStore: zoomStore)
        trackForMemoryLeaks(subject)
        return subject
    }

    @MainActor
    func createTab() -> Tab {
        let tab = Tab(profile: profile, windowUUID: windowUUID)

        guard let url = URL(string: "http://www.website.com") else { return tab }

        tab.url = url
        return tab
    }
}
