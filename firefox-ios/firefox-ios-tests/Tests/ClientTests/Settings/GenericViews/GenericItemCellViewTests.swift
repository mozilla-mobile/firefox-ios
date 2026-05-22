// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Common
@testable import Client

final class GenericItemCellViewTests: XCTestCase {
    override func setUp() async throws {
        try await super.setUp()
        await DependencyHelperMock().bootstrapDependencies()
    }

    override func tearDown() async throws {
        DependencyHelperMock().reset()
        try await super.tearDown()
    }

    @MainActor
    func testBody_isEvaluated() {
        let subject = createSubject()
        _ = subject.body
    }

    // MARK: - Subject
    @MainActor
    private func createSubject(
        title: String = "Test title",
        image: Client.ImageResource? = nil,
        theme: Theme? = nil,
        onTap: @escaping () -> Void = {}
    ) -> GenericItemCellView {
        let subject = GenericItemCellView(
            title: title,
            image: image,
            theme: theme,
            onTap: onTap
        )

        return subject
    }
}
