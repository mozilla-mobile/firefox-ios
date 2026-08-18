// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit
import XCTest
@testable import WebCompatReporterKit

@MainActor
final class WebCompatReportPreviewViewControllerTests: XCTestCase {
    private enum UX {
        static let presentationSize = CGSize(width: 390, height: 844)
    }

    func testTappingTechnicalDataRow_notifiesDelegate_butTappingTheSummaryDoesNot() throws {
        let delegate = MockWebCompatReportPreviewDelegate()
        let subject = createSubject()
        subject.delegate = delegate
        layout(subject)
        let collectionView = try XCTUnwrap(collectionView(in: subject))

        subject.collectionView(collectionView, didSelectItemAt: IndexPath(item: 0, section: 0))
        XCTAssertEqual(delegate.didTapTechnicalDataCallCount, 0)

        subject.collectionView(
            collectionView,
            didSelectItemAt: IndexPath(item: 0, section: collectionView.numberOfSections - 1)
        )
        XCTAssertEqual(delegate.didTapTechnicalDataCallCount, 1)
    }

    func testCloseTap_notifiesDelegate() throws {
        let delegate = MockWebCompatReportPreviewDelegate()
        let subject = createSubject()
        subject.delegate = delegate
        subject.loadViewIfNeeded()

        let closeButton = try XCTUnwrap(subject.navigationItem.rightBarButtonItem)
        let target = try XCTUnwrap(closeButton.target as? NSObject)
        target.perform(try XCTUnwrap(closeButton.action))

        XCTAssertEqual(delegate.didRequestDismissCallCount, 1)
    }

    func testSummaryCard_appearsOnlyWithBullets() {
        let withoutBullets = createSubject(bullets: [])
        let withBullets = createSubject(bullets: ["Page URL"])
        layout(withoutBullets)
        layout(withBullets)

        XCTAssertEqual(collectionView(in: withoutBullets)?.numberOfSections, 1)
        XCTAssertEqual(collectionView(in: withBullets)?.numberOfSections, 2)
    }

    // MARK: - Helpers

    private func createSubject(
        bullets: [String] = ["Page URL"],
        themeManager: ThemeManager = MockThemeManager()
    ) -> WebCompatReportPreviewViewController {
        let viewModel = WebCompatReportPreviewViewModel(
            title: "Report Preview",
            closeAccessibilityLabel: "Close",
            closeA11yIdentifier: "close",
            bullets: bullets,
            bulletsA11yIdentifier: "bullets",
            technicalDataTitle: "Technical Data",
            technicalDataA11yIdentifier: "technicalData"
        )
        return WebCompatReportPreviewViewController(
            viewModel: viewModel,
            windowUUID: .XCTestDefaultUUID,
            themeManager: themeManager,
            notificationCenter: NotificationCenter.default
        )
    }

    private func layout(_ subject: WebCompatReportPreviewViewController) {
        subject.view.frame = CGRect(origin: .zero, size: UX.presentationSize)
        subject.loadViewIfNeeded()
        subject.view.layoutIfNeeded()
    }

    private func collectionView(in subject: WebCompatReportPreviewViewController) -> UICollectionView? {
        return subject.view.subviews.compactMap { $0 as? UICollectionView }.first
    }
}

private final class MockWebCompatReportPreviewDelegate: WebCompatReportPreviewDelegate {
    var didRequestDismissCallCount = 0
    var didTapTechnicalDataCallCount = 0

    func webCompatReportPreviewDidRequestDismiss() {
        didRequestDismissCallCount += 1
    }

    func webCompatReportPreviewDidTapTechnicalData() {
        didTapTechnicalDataCallCount += 1
    }
}
