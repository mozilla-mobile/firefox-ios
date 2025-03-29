// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import XCTest
import Shared
import MozillaAppServices

@testable import Client

@MainActor
final class BookmarksViewControllerTests: XCTestCase {
    private let windowUUID: WindowUUID = .XCTestDefaultUUID

    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
    }

    override func tearDown() {
        DependencyHelperMock().reset()
        super.tearDown()
    }

    func testGetSiteDetailsAsync_whenNotPinnedSite_returnsFalse() async {
        let subject = createSubject()
        let indexPath = IndexPath(row: 0, section: 0)

        let site = await subject.getSiteDetailsAsync(for: indexPath)

        XCTAssert(site?.isPinnedSite == false)
    }

    func testGetSiteDetailsAsync_whenPinnedSite_returnsTrue() async {
        let subject = createSubject(isPinnedTopSite: true)
        let indexPath = IndexPath(row: 0, section: 0)

        let site = await subject.getSiteDetailsAsync(for: indexPath)

        XCTAssert(site?.isPinnedSite == true)
    }

    private func createSubject(isPinnedTopSite: Bool = false) -> BookmarksViewController {
        let mockProfile = MockProfile(
            injectedPinnedSites: PinnedSitesMock(
                stubbedIsPinnedtopSite: isPinnedTopSite
            )
        )

        let bookmark = BookmarkItemData(
            guid: "abc",
            dateAdded: Int64(Date().toTimestamp()),
            lastModified: Int64(Date().toTimestamp()),
            parentGUID: "123",
            position: 0,
            url: "www.firefox.com",
            title: "bookmark1"
        )

        let viewModel = BookmarksPanelViewModel(
            profile: mockProfile,
            bookmarksHandler: BookmarksHandlerMock()
        )
        viewModel.bookmarkNodes.append(bookmark)

        let subject = BookmarksViewController(
            viewModel: viewModel,
            windowUUID: windowUUID
        )
        trackForMemoryLeaks(viewModel)
        return subject
    }
}

// MARK: - Mocks
private class PinnedSitesMock: MockablePinnedSites {
    let isPinnedTopSite: Bool

    init(stubbedIsPinnedtopSite: Bool) {
        isPinnedTopSite = stubbedIsPinnedtopSite
    }

    override func isPinnedTopSite(_ url: String) -> Deferred<Maybe<Bool>> {
        let deffered = Deferred<Maybe<Bool>>()
        deffered.fill(Maybe(success: isPinnedTopSite))
        return deffered
    }
}
