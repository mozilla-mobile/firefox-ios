// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client

final class DownloadsCoordinatorTests: XCTestCase {
    private var router: MockRouter!
    private var parentCoordinator: MockLibraryCoordinatorDelegate!
    private var profile: MockProfile!

    override func setUp() {
        super.setUp()
        profile = MockProfile()
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: profile)
        router = MockRouter(navigationController: UINavigationController())
        parentCoordinator = MockLibraryCoordinatorDelegate()
        DependencyHelperMock().bootstrapDependencies()
    }

    override func tearDown() {
        router = nil
        parentCoordinator = nil
        profile = nil
        DependencyHelperMock().reset()
        super.tearDown()
    }

    func testHandleFile_presentsShareController() {
        let subject = createSubject()
        let fileFetcher = MockDownloadFileFetcher()
        fileFetcher.resultsPerSection = [Date(): 1]

        let files = fileFetcher.fetchData()
        guard let file = files.first
        else {
            XCTFail("There should be at least one file")
            return
        }
        subject.handleFile(file, sourceView: UIView())

        XCTAssertTrue(router.presentedViewController is UIActivityViewController)
        XCTAssertEqual(router.presentCalled, 1)
    }

    private func createSubject() -> DownloadsCoordinator {
        let subject = DownloadsCoordinator(
            router: router,
            profile: profile,
            parentCoordinator: parentCoordinator,
            tabManager: MockTabManager()
        )
        trackForMemoryLeaks(subject)
        return subject
    }
}
