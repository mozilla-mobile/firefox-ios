// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Testing
import UIKit
@testable import SummarizeKit

@Suite
struct SnapshotLayoutCalculatorTests {
    private let configuration = DefaultSnapshotLayoutCalculator.Configuration(
        summaryTransformBottomPaddingPortrait: 110.0,
        transformPercentagePortrait: 0.5,
        transformPercentageLandscape: 1.0
    )
    private let portraitContext = LayoutContext(
        viewSize: CGSize(width: 375, height: 667),
        traitCollection: UITraitCollection(horizontalSizeClass: .compact),
        tabSnapshotTopOffset: 50
    )
    private let landscapeContext = LayoutContext(
        viewSize: CGSize(width: 667, height: 375),
        traitCollection: UITraitCollection(horizontalSizeClass: .compact),
        tabSnapshotTopOffset: 0
    )

    // MARK: - Summary Transform
    @Test
    func test_calculateSummaryTransform_whenPortraitOrientation() {
        let subject = createSubject()

        let transform = subject.calculateSummaryTransform(context: portraitContext)

        let expectedY = portraitContext.viewSize.height
            - configuration.summaryTransformBottomPaddingPortrait
            - portraitContext.tabSnapshotTopOffset
        #expect(transform.tx == 0)
        #expect(transform.ty == expectedY)
    }

    @Test
    func test_calculateSummaryTransform_whenLandscapeOrientation() {
        let subject = createSubject()

        let transform = subject.calculateSummaryTransform(context: landscapeContext)

        let expectedY = landscapeContext.viewSize.height
        #expect(transform.tx == 0)
        #expect(transform.ty == expectedY)
    }

    @Test
    func test_calculateSummaryTransform_whenInterfaceRotated() {
        var subject = createSubject()
        subject.didRotateInterface = true

        let transform = subject.calculateSummaryTransform(context: portraitContext)

        let expectedY = portraitContext.viewSize.height
        #expect(transform.tx == 0)
        #expect(transform.ty == expectedY)
    }

    // MARK: - Info Transform
    @Test
    func test_calculateInfoTransform_whenPortraitOrientation() {
        let subject = createSubject()

        let transform = subject.calculateInfoTransform(context: portraitContext)

        let expectedY = portraitContext.viewSize.height * configuration.transformPercentagePortrait
        #expect(transform.tx == 0)
        #expect(transform.ty == expectedY)
    }

    @Test
    func test_calculateInfoTransform_whenLandscapeOrientation() {
        let subject = createSubject()

        let transform = subject.calculateInfoTransform(context: landscapeContext)

        let expectedY = landscapeContext.viewSize.height * configuration.transformPercentageLandscape
        #expect(transform.tx == 0)
        #expect(transform.ty == expectedY)
    }

    @Test
    func test_calculateInfoTransform_whenInterfaceRotated() {
        var subject = createSubject()
        subject.didRotateInterface = true

        let transform = subject.calculateInfoTransform(context: portraitContext)

        let expectedY = portraitContext.viewSize.height
        #expect(transform.tx == 0)
        #expect(transform.ty == expectedY)
    }

    // MARK: - Dismiss Transform
    @Test
    func test_calculateDismissTransform_whenNotRotated() {
        let subject = createSubject()

        let transform = subject.calculateDismissTransform(context: portraitContext)

        #expect(transform == .identity)
    }

    @Test
    func test_calculateDismissTransform_whenInterfaceRotated() {
        var subject = createSubject()
        subject.didRotateInterface = true

        let transform = subject.calculateDismissTransform(context: portraitContext)

        let expectedY = portraitContext.viewSize.height
        #expect(transform.tx == 0)
        #expect(transform.ty == expectedY)
    }

    // MARK: - View Did Appear Transform
    @Test
    func test_calculateViewDidAppearTransform_whenPortraitOrientation() {
        let subject = createSubject()

        let transform = subject.calculateViewDidAppearTransform(context: portraitContext)

        let expectedY = portraitContext.viewSize.height * configuration.transformPercentagePortrait
        #expect(transform.tx == 0)
        #expect(transform.ty == expectedY)
    }

    @Test
    func test_calculateViewDidAppearTransform_whenLandscapeOrientation() {
        let subject = createSubject()

        let transform = subject.calculateViewDidAppearTransform(context: landscapeContext)

        let expectedY = landscapeContext.viewSize.height * configuration.transformPercentageLandscape
        #expect(transform.tx == 0)
        #expect(transform.ty == expectedY)
    }

    @Test
    func test_calculateViewDidAppearTransform_whenInterfaceRotated() {
        var subject = createSubject()
        subject.didRotateInterface = true

        let transform = subject.calculateViewDidAppearTransform(context: portraitContext)

        let expectedY = portraitContext.viewSize.height
        #expect(transform.tx == 0)
        #expect(transform.ty == expectedY)
    }

    // MARK: - Did Rotate Transform
    @Test
    func test_calculateDidRotateTransform() {
        let subject = createSubject()

        let transform = subject.calculateDidRotateTransform(context: portraitContext)

        let expectedY = portraitContext.viewSize.height
        #expect(transform.tx == 0)
        #expect(transform.ty == expectedY)
    }

    // MARK: - Helper Methods
    private func createSubject() -> DefaultSnapshotLayoutCalculator {
        return DefaultSnapshotLayoutCalculator(configuration: configuration)
    }
}
