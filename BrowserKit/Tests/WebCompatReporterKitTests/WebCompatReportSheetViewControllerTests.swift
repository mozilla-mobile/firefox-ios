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
            .init(id: "url", rows: [.init(id: "url", title: "https://example.com", a11yIdentifier: "url")]),
            .init(id: "advanced", rows: [
                .init(id: "screenshot", title: "Include screenshot", a11yIdentifier: "screenshot"),
                .init(id: "blocklist", title: "Include blocked list", a11yIdentifier: "blocklist")
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

    func testSelectingSubOptionRow_notifiesDelegateWithRowID() {
        let delegate = MockWebCompatReportSheetDelegate()
        let subject = createSubject()
        subject.delegate = delegate
        subject.loadViewIfNeeded()
        subject.configure(with: makeViewModel(sections: pickerSections()))

        selectItem(in: subject, at: IndexPath(item: 1, section: 1))

        XCTAssertEqual(delegate.selectedSubOptionIDs, ["page_not_loading"])
        XCTAssertTrue(delegate.selectedCategoryIDs.isEmpty)
    }

    func testSelectingCategoryMenuRow_doesNotNotifySubOptionDelegate() {
        let delegate = MockWebCompatReportSheetDelegate()
        let subject = createSubject()
        subject.delegate = delegate
        subject.loadViewIfNeeded()
        subject.configure(with: makeViewModel(sections: pickerSections()))

        selectItem(in: subject, at: IndexPath(item: 0, section: 0))

        XCTAssertTrue(delegate.selectedSubOptionIDs.isEmpty)
    }

    func testConfigure_withPickerSections_dequeuesTypedCells() {
        let subject = createSubject()
        subject.view.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        subject.loadViewIfNeeded()

        subject.configure(with: makeViewModel(sections: pickerSections()))
        subject.view.layoutIfNeeded()

        let collectionView = subject.view.subviews.compactMap { $0 as? UICollectionView }.first
        XCTAssertEqual(collectionView?.numberOfSections, 2)
        XCTAssertEqual(collectionView?.numberOfItems(inSection: 1), 4)
        XCTAssertTrue(
            collectionView?.cellForItem(at: IndexPath(item: 0, section: 0)) is WebCompatCategoryMenuCell
        )
        XCTAssertTrue(
            collectionView?.cellForItem(at: IndexPath(item: 0, section: 1)) is WebCompatSubOptionCell
        )
    }

    func testConfigure_withFieldSections_dequeuesTypedCells() {
        let subject = createSubject()
        subject.view.frame = CGRect(x: 0, y: 0, width: 390, height: 2000)
        subject.loadViewIfNeeded()

        subject.configure(with: makeViewModel(sections: fieldSections()))
        subject.view.layoutIfNeeded()

        let collectionView = subject.view.subviews.compactMap { $0 as? UICollectionView }.first
        XCTAssertTrue(collectionView?.cellForItem(at: IndexPath(item: 0, section: 0)) is WebCompatURLCell)
        XCTAssertTrue(collectionView?.cellForItem(at: IndexPath(item: 0, section: 1)) is WebCompatDetailsCell)
    }

    func testURLCell_editingEnd_notifiesDelegateWithRowIDAndText() {
        let delegate = MockWebCompatReportSheetDelegate()
        let (subject, window) = hostedFieldSubject(delegate: delegate)
        defer { window.isHidden = true }

        let urlCell = collectionView(in: subject)?.cellForItem(at: IndexPath(item: 0, section: 0))
        let textField = firstSubview(ofType: UITextField.self, in: urlCell?.contentView)
        textField?.becomeFirstResponder()
        textField?.text = "https://changed.example.com"
        textField?.resignFirstResponder()

        XCTAssertEqual(delegate.editedText.map(\.id), ["url"])
        XCTAssertEqual(delegate.editedText.map(\.text), ["https://changed.example.com"])
    }

    func testDetailsCell_editingEnd_notifiesDelegateWithRowIDAndText() {
        let delegate = MockWebCompatReportSheetDelegate()
        let (subject, window) = hostedFieldSubject(delegate: delegate)
        defer { window.isHidden = true }

        let detailsCell = collectionView(in: subject)?.cellForItem(at: IndexPath(item: 0, section: 1))
        let textView = firstSubview(ofType: UITextView.self, in: detailsCell?.contentView)
        textView?.becomeFirstResponder()
        textView?.text = "The images never load"
        textView?.resignFirstResponder()

        XCTAssertEqual(delegate.editedText.map(\.id), ["details"])
        XCTAssertEqual(delegate.editedText.map(\.text), ["The images never load"])
    }

    // MARK: - Helpers

    private func hostedFieldSubject(
        delegate: MockWebCompatReportSheetDelegate
    ) -> (WebCompatReportSheetViewController, UIWindow) {
        let subject = createSubject()
        subject.delegate = delegate
        // A tall key window lays out every section and gives text fields a real
        // editing session for first-responder changes.
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 2000))
        window.rootViewController = subject
        window.makeKeyAndVisible()
        subject.configure(with: makeViewModel(sections: fieldSections()))
        subject.view.layoutIfNeeded()
        return (subject, window)
    }

    private func collectionView(in subject: WebCompatReportSheetViewController) -> UICollectionView? {
        return subject.view.subviews.compactMap { $0 as? UICollectionView }.first
    }

    private func firstSubview<T: UIView>(ofType type: T.Type, in view: UIView?) -> T? {
        guard let view else { return nil }
        for subview in view.subviews {
            if let match = subview as? T { return match }
            if let match = firstSubview(ofType: type, in: subview) { return match }
        }
        return nil
    }

    private func fieldSections() -> [WebCompatReportViewModel.Section] {
        return [
            WebCompatReportViewModel.Section(id: "url", rows: [
                WebCompatReportViewModel.Row(
                    id: "url",
                    title: "URL",
                    kind: .urlField(text: "https://example.com", placeholder: "Website address"),
                    a11yIdentifier: "url"
                )
            ]),
            WebCompatReportViewModel.Section(id: "details", rows: [
                WebCompatReportViewModel.Row(
                    id: "details",
                    title: "Additional details",
                    kind: .detailsField(text: "", placeholder: "Additional Details (optional)"),
                    a11yIdentifier: "details"
                )
            ])
        ]
    }

    private func pickerSections() -> [WebCompatReportViewModel.Section] {
        let options = [
            WebCompatReportViewModel.Row.MenuOption(
                id: "siteNotUsable",
                title: "Site is not usable",
                isSelected: true
            ),
            WebCompatReportViewModel.Row.MenuOption(
                id: "designBroken",
                title: "Design is broken",
                isSelected: false
            )
        ]
        return [
            WebCompatReportViewModel.Section(id: "issue-category", title: "Site Issue", rows: [
                WebCompatReportViewModel.Row(
                    id: "issue-category",
                    title: "Site is not usable",
                    kind: .categoryMenu(isPlaceholder: false, options: options),
                    a11yIdentifier: "issue-category"
                )
            ]),
            WebCompatReportViewModel.Section(id: "issue-suboptions", rows: [
                WebCompatReportViewModel.Row(
                    id: "browser_blocked",
                    title: "Browser is blocked",
                    kind: .subOption(isSelected: false),
                    a11yIdentifier: "browser_blocked"
                ),
                WebCompatReportViewModel.Row(
                    id: "page_not_loading",
                    title: "Page not loading correctly",
                    kind: .subOption(isSelected: false),
                    a11yIdentifier: "page_not_loading"
                ),
                WebCompatReportViewModel.Row(
                    id: "missing_items",
                    title: "Missing items",
                    kind: .subOption(isSelected: false),
                    a11yIdentifier: "missing_items"
                ),
                WebCompatReportViewModel.Row(
                    id: "buttons_not_working",
                    title: "Buttons or links not working",
                    kind: .subOption(isSelected: false),
                    a11yIdentifier: "buttons_not_working"
                )
            ])
        ]
    }

    private func selectItem(in subject: WebCompatReportSheetViewController, at indexPath: IndexPath) {
        guard let collectionView = subject.view.subviews.compactMap({ $0 as? UICollectionView }).first else {
            return XCTFail("Expected a collection view")
        }
        subject.collectionView(collectionView, didSelectItemAt: indexPath)
    }

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
    var selectedCategoryIDs: [String] = []
    var selectedSubOptionIDs: [String] = []
    var editedText: [(id: String, text: String)] = []

    func webCompatReportSheetDidTapClose() {
        didTapCloseCallCount += 1
    }

    func webCompatReportSheetDidTapPreview() {
        didTapPreviewCallCount += 1
    }

    func webCompatReportSheetDidSelectCategory(id: String) {
        selectedCategoryIDs.append(id)
    }

    func webCompatReportSheetDidSelectSubOption(id: String) {
        selectedSubOptionIDs.append(id)
    }

    func webCompatReportSheetDidEditText(id: String, text: String) {
        editedText.append((id, text))
    }
}
