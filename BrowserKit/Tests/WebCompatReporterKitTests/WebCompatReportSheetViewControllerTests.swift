// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import XCTest
@testable import WebCompatReporterKit

@MainActor
final class WebCompatReportSheetViewControllerTests: XCTestCase {
    func testConfigure_setsNavigationTitleAndCloseAccessibilityLabel() {
        let subject = createSubject()
        subject.loadViewIfNeeded()

        XCTAssertEqual(subject.navigationItem.title, "Report a Website Issue")
        XCTAssertEqual(subject.navigationItem.leftBarButtonItem?.accessibilityLabel, "Close")
    }

    func testConfigure_disablesPreviewButton_whenPreviewNotEnabled() {
        let subject = createSubject(isPreviewEnabled: false)
        subject.loadViewIfNeeded()

        XCTAssertEqual(subject.navigationItem.rightBarButtonItem?.isEnabled, false)
    }

    func testReconfigure_updatesPreviewEnabledState() {
        let subject = createSubject(isPreviewEnabled: false)
        subject.loadViewIfNeeded()

        subject.configure(with: makeViewModel(isPreviewEnabled: true))

        XCTAssertEqual(subject.navigationItem.rightBarButtonItem?.isEnabled, true)
    }

    func testConfigure_withSections_populatesList() {
        let subject = createSubject()
        subject.loadViewIfNeeded()

        subject.configure(with: makeViewModel(sections: [
            .init(id: "url", rows: [.init(id: "url", title: "https://example.com")]),
            .init(id: "advanced", rows: [
                .init(id: "screenshot", title: "Include screenshot"),
                .init(id: "blocklist", title: "Include blocked list")
            ])
        ]))

        let collectionView = subject.view.subviews.compactMap { $0 as? UICollectionView }.first
        XCTAssertEqual(collectionView?.numberOfSections, 2)
        XCTAssertEqual(collectionView?.numberOfItems(inSection: 1), 2)
    }

    func testCloseButton_notifiesDelegate() {
        let delegate = MockWebCompatReportSheetDelegate()
        let subject = createSubject()
        subject.delegate = delegate
        subject.loadViewIfNeeded()

        tap(subject.navigationItem.leftBarButtonItem)

        XCTAssertEqual(delegate.didTapCloseCallCount, 1)
        XCTAssertEqual(delegate.didTapPreviewCallCount, 0)
    }

    func testPreviewButton_notifiesDelegate() {
        let delegate = MockWebCompatReportSheetDelegate()
        let subject = createSubject(isPreviewEnabled: true)
        subject.delegate = delegate
        subject.loadViewIfNeeded()

        tap(subject.navigationItem.rightBarButtonItem)

        XCTAssertEqual(delegate.didTapPreviewCallCount, 1)
        XCTAssertEqual(delegate.didTapCloseCallCount, 0)
    }

    // MARK: - Helpers

    private func makeViewModel(
        isPreviewEnabled: Bool = false,
        sections: [WebCompatReportViewModel.Section] = []
    ) -> WebCompatReportViewModel {
        return WebCompatReportViewModel(
            navigationTitle: "Report a Website Issue",
            closeButtonAccessibilityLabel: "Close",
            previewButtonTitle: "Preview",
            isPreviewEnabled: isPreviewEnabled,
            sections: sections
        )
    }

    private func createSubject(isPreviewEnabled: Bool = false) -> WebCompatReportSheetViewController {
        return WebCompatReportSheetViewController(
            viewModel: makeViewModel(isPreviewEnabled: isPreviewEnabled),
            theme: LightTheme()
        )
    }

    private func tap(_ item: UIBarButtonItem?) {
        guard let item, let action = item.action else { return }
        _ = item.target?.perform(action)
    }
}

private final class MockWebCompatReportSheetDelegate: WebCompatReportSheetDelegate {
    var didTapCloseCallCount = 0
    var didTapPreviewCallCount = 0

    func webCompatReportSheetDidTapClose() {
        didTapCloseCallCount += 1
    }

    func webCompatReportSheetDidTapPreview() {
        didTapPreviewCallCount += 1
    }
}
