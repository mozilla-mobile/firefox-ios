// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import XCTest
@testable import WebCompatReporterKit

@MainActor
final class WebCompatReportPreviewViewControllerTests: XCTestCase {
    func testConfigure_setsNavigationTitle() {
        let subject = createSubject(title: "Report Preview")
        subject.loadViewIfNeeded()

        XCTAssertEqual(subject.navigationItem.title, "Report Preview")
    }

    func testWithoutScreenshot_omitsScreenshotSection() {
        let subject = createSubject(screenshot: nil, sections: sampleSections())
        subject.loadViewIfNeeded()

        XCTAssertEqual(collectionView(in: subject)?.numberOfSections, sampleSections().count)
    }

    func testWithScreenshot_addsLeadingScreenshotSection() {
        let subject = createSubject(screenshot: sampleImage(), sections: sampleSections())
        subject.view.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        subject.loadViewIfNeeded()
        subject.view.layoutIfNeeded()

        let collectionView = collectionView(in: subject)
        XCTAssertEqual(collectionView?.numberOfSections, sampleSections().count + 1)
        XCTAssertEqual(collectionView?.numberOfItems(inSection: 0), 1)
        XCTAssertTrue(collectionView?.cellForItem(at: IndexPath(item: 0, section: 0)) is WebCompatPreviewScreenshotCell)
    }

    func testSectionsStartCollapsed() {
        let subject = createSubject(screenshot: nil, sections: sampleSections())
        subject.view.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        subject.loadViewIfNeeded()
        subject.view.layoutIfNeeded()

        // A collapsed disclosure section shows only its header row.
        XCTAssertEqual(collectionView(in: subject)?.numberOfItems(inSection: 0), 1)
    }

    func testScreenshotTap_notifiesDelegate() {
        let delegate = MockWebCompatReportPreviewDelegate()
        let subject = createSubject(screenshot: sampleImage(), sections: sampleSections())
        subject.delegate = delegate
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.rootViewController = subject
        window.makeKeyAndVisible()
        defer { window.isHidden = true }
        subject.view.layoutIfNeeded()

        let cell = collectionView(in: subject)?.cellForItem(at: IndexPath(item: 0, section: 0))
        let button = firstSubview(ofType: UIButton.self, in: cell?.contentView)
        fireActions(button, for: .touchUpInside)

        XCTAssertEqual(delegate.didTapScreenshotCallCount, 1)
    }

    func testCloseTap_notifiesDelegate() {
        let delegate = MockWebCompatReportPreviewDelegate()
        let subject = createSubject(sections: sampleSections())
        subject.delegate = delegate
        subject.loadViewIfNeeded()

        let closeItem = subject.navigationItem.leftBarButtonItem
        if let action = closeItem?.action {
            _ = closeItem?.target?.perform(action)
        }

        XCTAssertEqual(delegate.didTapCloseCallCount, 1)
    }

    // MARK: - Helpers

    private func createSubject(
        title: String = "Report Preview",
        screenshot: UIImage? = nil,
        sections: [WebCompatReportPreviewViewModel.PreviewSection] = []
    ) -> WebCompatReportPreviewViewController {
        let viewModel = WebCompatReportPreviewViewModel(
            title: title,
            closeAccessibilityLabel: "Close",
            screenshotAccessibilityLabel: "Screenshot",
            screenshot: screenshot,
            sections: sections
        )
        return WebCompatReportPreviewViewController(viewModel: viewModel, theme: LightTheme())
    }

    private func sampleSections() -> [WebCompatReportPreviewViewModel.PreviewSection] {
        return [
            WebCompatReportPreviewViewModel.PreviewSection(id: "details", title: "Report details", rows: [
                WebCompatReportPreviewViewModel.PreviewRow(
                    id: "website", label: "Website", value: .string("https://example.com")
                ),
                WebCompatReportPreviewViewModel.PreviewRow(
                    id: "issue", label: "Issue type", value: .string("Site is not usable")
                )
            ]),
            WebCompatReportPreviewViewModel.PreviewSection(id: "device", title: "Device", rows: [
                WebCompatReportPreviewViewModel.PreviewRow(id: "type", label: "Device type", value: .string("Phone"))
            ])
        ]
    }

    private func sampleImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 40, height: 60))
        return renderer.image { context in
            UIColor.systemBlue.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 40, height: 60))
        }
    }

    private func collectionView(in subject: WebCompatReportPreviewViewController) -> UICollectionView? {
        return subject.view.subviews.compactMap { $0 as? UICollectionView }.first
    }

    private func fireActions(_ control: UIControl?, for event: UIControl.Event) {
        guard let control else { return }
        for target in control.allTargets {
            let object = target as NSObject
            control.actions(forTarget: target, forControlEvent: event)?.forEach {
                object.perform(Selector($0))
            }
        }
    }

    private func firstSubview<T: UIView>(ofType type: T.Type, in view: UIView?) -> T? {
        guard let view else { return nil }
        for subview in view.subviews {
            if let match = subview as? T { return match }
            if let match = firstSubview(ofType: type, in: subview) { return match }
        }
        return nil
    }
}

final class MockWebCompatReportPreviewDelegate: WebCompatReportPreviewDelegate {
    var didTapCloseCallCount = 0
    var didTapScreenshotCallCount = 0

    func webCompatReportPreviewDidTapClose() {
        didTapCloseCallCount += 1
    }

    func webCompatReportPreviewDidTapScreenshot() {
        didTapScreenshotCallCount += 1
    }
}
