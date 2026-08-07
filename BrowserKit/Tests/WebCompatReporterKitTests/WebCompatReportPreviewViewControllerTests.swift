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

    // Both are single-item sections, so a handler keyed on the wrong one still hits a real cell.
    func testTappingTechnicalDataRow_notifiesDelegate() throws {
        let delegate = MockWebCompatReportPreviewDelegate()
        let subject = createSubject()
        subject.delegate = delegate
        layout(subject)
        let collectionView = try XCTUnwrap(collectionView(in: subject))

        subject.collectionView(
            collectionView,
            didSelectItemAt: IndexPath(item: 0, section: collectionView.numberOfSections - 1)
        )

        XCTAssertEqual(delegate.didTapTechnicalDataCallCount, 1)
    }

    func testTappingBulletCard_doesNotPushTechnicalData() throws {
        let delegate = MockWebCompatReportPreviewDelegate()
        let subject = createSubject()
        subject.delegate = delegate
        layout(subject)
        let collectionView = try XCTUnwrap(collectionView(in: subject))

        subject.collectionView(collectionView, didSelectItemAt: IndexPath(item: 0, section: 0))

        XCTAssertEqual(delegate.didTapTechnicalDataCallCount, 0)
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

    // Reporting the gesture as handled with nobody listening would swallow it.
    func testAccessibilityEscape_withoutDelegate_isNotHandled() {
        XCTAssertFalse(createSubject().accessibilityPerformEscape())
    }

    // The row is the way off this screen, so it has to survive an empty summary.
    func testWithoutBullets_stillShowsTheTechnicalDataRow() {
        let subject = createSubject(bullets: [])
        layout(subject)

        XCTAssertEqual(collectionView(in: subject)?.numberOfSections, 1)
    }

    func testUpdateScreenshot_addsAndRemovesTheThumbnailSection() {
        let subject = createSubject()
        layout(subject)
        XCTAssertEqual(collectionView(in: subject)?.numberOfSections, 2)

        subject.updateScreenshot(UIImage())
        subject.view.layoutIfNeeded()
        XCTAssertEqual(collectionView(in: subject)?.numberOfSections, 3)

        subject.updateScreenshot(nil)
        subject.view.layoutIfNeeded()
        XCTAssertEqual(collectionView(in: subject)?.numberOfSections, 2)
    }

    // A configure that changes nothing must not rebuild cells.
    func testConfigure_withUnchangedViewModel_keepsTheExistingCells() throws {
        let subject = createSubject()
        layout(subject)
        let indexPath = IndexPath(item: 0, section: 0)
        let cellBefore = try XCTUnwrap(collectionView(in: subject)?.cellForItem(at: indexPath))

        subject.configure(with: makeViewModel())
        subject.view.layoutIfNeeded()

        XCTAssertIdentical(cellBefore, collectionView(in: subject)?.cellForItem(at: indexPath))
    }

    // The dots are image attachments, which VoiceOver would announce per line.
    func testBulletCard_accessibilityLabel_omitsTheDots() throws {
        let subject = createSubject()
        layout(subject)

        let cell = try XCTUnwrap(collectionView(in: subject)?.cellForItem(at: IndexPath(item: 0, section: 0)))
        let label = try XCTUnwrap(cell.accessibilityLabel)
        XCTAssertFalse(label.contains("\u{FFFC}"), "The attachment placeholder must not reach VoiceOver")
        XCTAssertTrue(label.contains("Page URL"))
        XCTAssertTrue(label.contains("App version number"))
    }

    // MARK: - Helpers

    private func makeViewModel(
        bullets: [WebCompatReportPreviewViewModel.Bullet]? = nil
    ) -> WebCompatReportPreviewViewModel {
        return WebCompatReportPreviewViewModel(
            title: "Report Preview",
            closeAccessibilityLabel: "Close",
            closeA11yIdentifier: "close",
            screenshotAccessibilityLabel: "Screenshot",
            screenshotA11yIdentifier: "screenshot",
            bullets: bullets ?? sampleBullets,
            bulletsA11yIdentifier: "bullets",
            technicalDataTitle: "Technical Data",
            technicalDataA11yIdentifier: "technicalData"
        )
    }

    private func createSubject(
        bullets: [WebCompatReportPreviewViewModel.Bullet]? = nil,
        themeManager: ThemeManager = MockThemeManager()
    ) -> WebCompatReportPreviewViewController {
        return WebCompatReportPreviewViewController(
            viewModel: makeViewModel(bullets: bullets),
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

    private let sampleBullets = [
        WebCompatReportPreviewViewModel.Bullet(id: "bullet.url", text: "Page URL [https://example.com]"),
        WebCompatReportPreviewViewModel.Bullet(id: "bullet.app", text: "App version number")
    ]
}

private final class MockWebCompatReportPreviewDelegate: WebCompatReportPreviewDelegate {
    var didRequestDismissCallCount = 0
    var didTapTechnicalDataCallCount = 0

    func webCompatReportPreviewDidRequestDismiss() {
        didRequestDismissCallCount += 1
    }

    func webCompatReportPreviewDidTapScreenshot() {}

    func webCompatReportPreviewDidTapTechnicalData() {
        didTapTechnicalDataCallCount += 1
    }
}
