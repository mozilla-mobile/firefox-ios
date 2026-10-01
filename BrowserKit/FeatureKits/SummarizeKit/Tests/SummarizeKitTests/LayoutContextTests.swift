// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Testing
@testable import SummarizeKit

@Suite
struct LayoutContextTests {
    @Test
    func test_isLandscapeLayout_whenPortraitOrientation() {
        let subject = createSubject(width: 375, height: 667)
        #expect(!subject.isLandscapeLayout)
    }

    @Test
    func test_isLandscapeLayout_whenLandscapeOrientation() {
        let subject = createSubject(width: 667, height: 375)
        #expect(subject.isLandscapeLayout)
    }

    @Test
    func test_isLandscapeLayout_whenRegularSizeClass() {
        let subject = createSubject(width: 1024, height: 768, horizontalSizeClass: .regular)
        // iPad with regular horizontal size class should use portrait layout even if width > height
        #expect(!subject.isLandscapeLayout)
    }

    private func createSubject(
        width: CGFloat,
        height: CGFloat,
        horizontalSizeClass: UIUserInterfaceSizeClass = .compact
    ) -> LayoutContext {
        let traitCollection = UITraitCollection(horizontalSizeClass: horizontalSizeClass)
        return LayoutContext(
            viewSize: CGSize(width: width, height: height),
            traitCollection: traitCollection,
            tabSnapshotTopOffset: 0.0
        )
    }
}
