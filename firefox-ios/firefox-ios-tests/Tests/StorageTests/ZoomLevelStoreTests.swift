// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Storage

final class ZoomLevelStoreTests: XCTestCase {
    var zoomLevelStore: ZoomLevelStore!

    let testHost1 = "www.example1.com"
    let testHost2 = "www.example2.com"
    let testHost3 = "www.example3.com"
    let testZoomLevel: CGFloat = 2.0

    override func setUp() {
        super.setUp()
        zoomLevelStore = ZoomLevelStore.shared
        cleanUp()
    }

    override func tearDown() {
        super.tearDown()
        zoomLevelStore = nil
        cleanUp()
    }

    private func cleanUp() {
        let url = URL(fileURLWithPath: "domain-zoom-levels",
                      relativeTo: FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first)
        if FileManager.default.fileExists(atPath: url.path) {
            do {
                try FileManager.default.removeItem(at: url)
            } catch {
                assertionFailure("Error removing file: \(error)")
            }
        }
    }

    func testSaveAndFindZoomLevel() {
        let domainZoomLevel = DomainZoomLevel(host: testHost1, zoomLevel: testZoomLevel)
        zoomLevelStore.saveDomainZoom(domainZoomLevel)

        let retrievedZoomLevel = zoomLevelStore.findZoomLevel(forDomain: testHost1)
        XCTAssertEqual(retrievedZoomLevel, domainZoomLevel)
    }

    func testSaveMultipleZoomLevels() {
        let domainZoomLevel1 = DomainZoomLevel(host: testHost1, zoomLevel: testZoomLevel)
        let domainZoomLevel2 = DomainZoomLevel(host: testHost2, zoomLevel: testZoomLevel)
        zoomLevelStore.saveDomainZoom(domainZoomLevel1)
        zoomLevelStore.saveDomainZoom(domainZoomLevel2)

        let retrievedZoomLevel1 = zoomLevelStore.findZoomLevel(forDomain: testHost1)
        XCTAssertEqual(retrievedZoomLevel1, domainZoomLevel1)

        let retrievedZoomLevel2 = zoomLevelStore.findZoomLevel(forDomain: testHost2)
        XCTAssertEqual(retrievedZoomLevel2, domainZoomLevel2)
    }

    func testSaveAndUpdateZoomLevel() {
        let domainZoomLevel1 = DomainZoomLevel(host: testHost1, zoomLevel: testZoomLevel)
        let domainZoomLevel2 = DomainZoomLevel(host: testHost1, zoomLevel: testZoomLevel + 1)
        zoomLevelStore.saveDomainZoom(domainZoomLevel1)
        zoomLevelStore.saveDomainZoom(domainZoomLevel2)

        let retrievedZoomLevel = zoomLevelStore.findZoomLevel(forDomain: testHost1)
        XCTAssertEqual(retrievedZoomLevel, domainZoomLevel2)
    }

    func testSaveDefaultZoomLevel() {
        let domainZoomLevel = DomainZoomLevel(host: testHost1, zoomLevel: 1.0)
        zoomLevelStore.saveDomainZoom(domainZoomLevel)

        XCTAssertTrue(zoomLevelStore.getDomainZoomLevel().contains(domainZoomLevel))
    }

    func testFindZoomLevelNotFound() {
        let domainZoomLevel = zoomLevelStore.findZoomLevel(forDomain: testHost3)

        XCTAssertNil(domainZoomLevel)
    }

    func testSaveSameZoomLevel() {
        let dispatchGroup = DispatchGroup()

        let domainZoomLevel = DomainZoomLevel(host: testHost3, zoomLevel: 1.5)
        dispatchGroup.enter()
        zoomLevelStore.saveDomainZoom(domainZoomLevel) {
            dispatchGroup.leave()
        }

        let updatedDomainZoomLevel = DomainZoomLevel(host: testHost3, zoomLevel: 2.0)
        dispatchGroup.enter()
        zoomLevelStore.saveDomainZoom(updatedDomainZoomLevel) {
            dispatchGroup.leave()
        }
        dispatchGroup.wait()

        XCTAssertTrue(zoomLevelStore.getDomainZoomLevel().contains(updatedDomainZoomLevel))
        XCTAssertFalse(zoomLevelStore.getDomainZoomLevel().contains(domainZoomLevel))
    }

    func testSingletonInstance() {
        let zoomLevelStore1 = ZoomLevelStore.shared
        let zoomLevelStore2 = ZoomLevelStore.shared

        XCTAssertTrue(zoomLevelStore1 === zoomLevelStore2)
    }
}
