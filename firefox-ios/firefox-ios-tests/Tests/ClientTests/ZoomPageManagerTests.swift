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

    override func setUp() {
        super.setUp()
        self.profile = MockProfile()
        self.zoomStore = MockZoomStore()
        DependencyHelperMock().bootstrapDependencies()
    }

    override func tearDown() {
        self.profile = nil
        self.zoomStore = nil
        DependencyHelperMock().reset()
        super.tearDown()
    }

    func testTabNil_AfterInit() {
        let subject = createSubject()
        XCTAssertNil(subject.tab)
    }

    func testTabNotNil_WhenTabGainFocus() {
        let subject = createSubject()
        let tab = createTab()
        subject.tabDidGainFocus(tab)

        XCTAssertNotNil(subject.tab)
    }

    func testTabZoomChange_WhenZoomInIsCalled() {
        let subject = createSubject()
        let tab = createTab()
        subject.tabDidGainFocus(tab)
        let newZoom = subject.zoomIn()
        let expectedZoom = 1.1

        XCTAssertEqual(newZoom, expectedZoom)
        XCTAssertEqual(tab.pageZoom, expectedZoom)
    }

    func testTabZoomChange_WhenZoomOutIsCalled() {
        let subject = createSubject()
        let tab = createTab()
        subject.tabDidGainFocus(tab)
        let newZoom = subject.zoomOut()
        let expectedZoom = 0.9

        XCTAssertEqual(newZoom, expectedZoom)
        XCTAssertEqual(tab.pageZoom, expectedZoom)
    }

    func testTabZoomReset_WhenResetZoomIsCalled() {
        let subject = createSubject()
        let tab = createTab()
        subject.tabDidGainFocus(tab)
        subject.resetZoom()
        let expectedZoom = ZoomConstants.defaultZoomLimit

        XCTAssertEqual(tab.pageZoom, expectedZoom)
    }

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

    func testZoomStoreSaved_WhenZoomInIsCalled() {
        let subject = createSubject()
        let tab = createTab()
        subject.tabDidGainFocus(tab)
        _ = subject.zoomIn()

        XCTAssertEqual(zoomStore.saveCalledCount, 1)
    }

    func testZoomStoreSaved_WhenZoomResetIsCalled() {
        let subject = createSubject()
        let tab = createTab()
        subject.tabDidGainFocus(tab)
        subject.resetZoom()

        XCTAssertEqual(zoomStore.saveCalledCount, 1)
    }

    func testFindZoomStore_WhenZoomInIsCalled() {
        let subject = createSubject()
        let tab = createTab()
        subject.tabDidGainFocus(tab)

        // When the tab is set we check if there is zoom level and set it
        XCTAssertEqual(zoomStore.findZoomLevelCalledCount, 1)
    }

    // MARK: - Private
    private func createSubject() -> ZoomPageManager {
        let subject = ZoomPageManager(windowUUID: .XCTestDefaultUUID,
                                      zoomStore: zoomStore)
        trackForMemoryLeaks(subject)
        return subject
    }

    func createTab() -> Tab {
        let tab = Tab(profile: profile, windowUUID: windowUUID)

        guard let url = URL(string: "http://www.website.com") else { return tab }

        tab.url = url
        return tab
    }
}
