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

    func testConfigure_withSendSection_dequeuesSendButtonCell() {
        let subject = createSubject()
        subject.view.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        subject.loadViewIfNeeded()

        subject.configure(with: makeViewModel(sections: sendSections(isEnabled: true)))
        subject.view.layoutIfNeeded()

        XCTAssertTrue(
            collectionView(in: subject)?.cellForItem(at: IndexPath(item: 0, section: 0)) is WebCompatSendButtonCell
        )
    }

    func testSendButton_whenTapped_notifiesDelegateWithRowID() {
        let delegate = MockWebCompatReportSheetDelegate()
        let subject = createSubject()
        subject.delegate = delegate
        subject.view.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        subject.loadViewIfNeeded()
        subject.configure(with: makeViewModel(sections: sendSections(isEnabled: true)))
        subject.view.layoutIfNeeded()

        let cell = collectionView(in: subject)?.cellForItem(at: IndexPath(item: 0, section: 0))
        fireActions(firstSubview(ofType: UIButton.self, in: cell), for: .touchUpInside)

        XCTAssertEqual(delegate.tappedButtonIDs, ["send"])
    }

    func testSendButton_whenNotSubmittable_rendersDisabledButton() {
        let subject = createSubject()
        subject.view.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        subject.loadViewIfNeeded()
        subject.configure(with: makeViewModel(sections: sendSections(isEnabled: false)))
        subject.view.layoutIfNeeded()

        let cell = collectionView(in: subject)?.cellForItem(at: IndexPath(item: 0, section: 0))
        XCTAssertEqual(firstSubview(ofType: UIButton.self, in: cell)?.isEnabled, false)
    }

    func testConfigure_withToggleSection_dequeuesToggleCell() {
        let subject = createSubject()
        subject.view.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        subject.loadViewIfNeeded()

        subject.configure(with: makeViewModel(sections: toggleSections()))
        subject.view.layoutIfNeeded()

        XCTAssertTrue(
            collectionView(in: subject)?.cellForItem(at: IndexPath(item: 0, section: 0)) is WebCompatToggleCell
        )
    }

    func testToggleCell_activation_notifiesDelegateWithRowIDAndValue() {
        let delegate = MockWebCompatReportSheetDelegate()
        let subject = createSubject()
        subject.delegate = delegate
        subject.view.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        subject.loadViewIfNeeded()
        subject.configure(with: makeViewModel(sections: toggleSections()))
        subject.view.layoutIfNeeded()

        let toggleCell = collectionView(in: subject)?.cellForItem(at: IndexPath(item: 0, section: 0))
        let toggle = firstSubview(ofType: UISwitch.self, in: toggleCell)
        toggle?.isOn = true
        fireActions(toggle, for: .valueChanged)

        XCTAssertEqual(delegate.toggles.map(\.id), ["screenshot"])
        XCTAssertEqual(delegate.toggles.map(\.isOn), [true])
    }

    // A toggle flip re-renders the whole view model. Rows that didn't change must not
    // be reconfigured: sub-option cells rebuild their checkmark accessory on configure,
    // and the list animates that as a remove+insert, so the checkmark visibly flickers.
    func testConfigure_whenOnlyAToggleChanges_doesNotRebuildTheSubOptionCheckmark() {
        let subject = createSubject()
        subject.view.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        subject.loadViewIfNeeded()
        subject.configure(with: makeViewModel(sections: subOptionAndToggleSections(isOn: false)))
        subject.view.layoutIfNeeded()

        let subOptionIndexPath = IndexPath(item: 0, section: 0)
        let checkmarkBefore = checkmarkView(in: subject, at: subOptionIndexPath)

        subject.configure(with: makeViewModel(sections: subOptionAndToggleSections(isOn: true)))
        subject.view.layoutIfNeeded()

        XCTAssertNotNil(checkmarkBefore)
        XCTAssertTrue(checkmarkBefore === checkmarkView(in: subject, at: subOptionIndexPath))
    }

    func testConfigure_whenASubOptionChanges_rebuildsItsCheckmark() {
        let subject = createSubject()
        subject.view.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        subject.loadViewIfNeeded()
        subject.configure(with: makeViewModel(sections: subOptionAndToggleSections(isOn: false)))
        subject.view.layoutIfNeeded()

        let subOptionIndexPath = IndexPath(item: 0, section: 0)
        XCTAssertNotNil(checkmarkView(in: subject, at: subOptionIndexPath))

        subject.configure(
            with: makeViewModel(sections: subOptionAndToggleSections(isOn: false, isSubOptionSelected: false))
        )
        subject.view.layoutIfNeeded()

        XCTAssertNil(checkmarkView(in: subject, at: subOptionIndexPath))
    }

    // MARK: - Helpers

    private func collectionView(in subject: WebCompatReportSheetViewController) -> UICollectionView? {
        return subject.view.subviews.compactMap { $0 as? UICollectionView }.first
    }

    // UIControl.sendActions needs a running UIApplication, which logic tests lack,
    // so invoke each registered target/action selector directly.
    private func fireActions(_ control: UIControl?, for event: UIControl.Event) {
        guard let control else { return }
        for target in control.allTargets {
            let object = target as NSObject
            control.actions(forTarget: target, forControlEvent: event)?.forEach {
                object.perform(Selector($0))
            }
        }
    }

    private func sendSections(isEnabled: Bool) -> [WebCompatReportViewModel.Section] {
        return [
            WebCompatReportViewModel.Section(id: "send", rows: [
                WebCompatReportViewModel.Row(
                    id: "send",
                    title: "Send Report",
                    kind: .sendButton(isEnabled: isEnabled),
                    a11yIdentifier: "send"
                )
            ])
        ]
    }

    /// The image view backing a sub-option's checkmark accessory, or nil when unselected.
    /// Identity matters: the cell builds a fresh one on every configure, so a new instance
    /// means the row was reconfigured.
    private func checkmarkView(
        in subject: WebCompatReportSheetViewController,
        at indexPath: IndexPath
    ) -> UIImageView? {
        let cell = collectionView(in: subject)?.cellForItem(at: indexPath)
        return firstSubview(ofType: UIImageView.self, in: cell)
    }

    private func subOptionAndToggleSections(
        isOn: Bool,
        isSubOptionSelected: Bool = true
    ) -> [WebCompatReportViewModel.Section] {
        return [
            WebCompatReportViewModel.Section(id: "issue-suboptions", rows: [
                WebCompatReportViewModel.Row(
                    id: "page_not_loading",
                    title: "Page not loading correctly",
                    kind: .subOption(isSelected: isSubOptionSelected),
                    a11yIdentifier: "page_not_loading"
                )
            ]),
            WebCompatReportViewModel.Section(id: "advanced", title: "Additional Info", rows: [
                WebCompatReportViewModel.Row(
                    id: "screenshot",
                    title: "Include screenshot",
                    kind: .toggle(isOn: isOn),
                    a11yIdentifier: "screenshot"
                )
            ])
        ]
    }

    private func toggleSections() -> [WebCompatReportViewModel.Section] {
        return [
            WebCompatReportViewModel.Section(
                id: "advanced",
                title: "Additional Info",
                rows: [
                    WebCompatReportViewModel.Row(
                        id: "screenshot",
                        title: "Include screenshot",
                        kind: .toggle(isOn: false),
                        a11yIdentifier: "screenshot"
                    ),
                    WebCompatReportViewModel.Row(
                        id: "blocklist",
                        title: "Include blocked list",
                        kind: .toggle(isOn: true),
                        a11yIdentifier: "blocklist"
                    )
                ]
            )
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
    var tappedButtonIDs: [String] = []
    var toggles: [(id: String, isOn: Bool)] = []

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

    func webCompatReportSheetDidTapButton(id: String) {
        tappedButtonIDs.append(id)
    }

    func webCompatReportSheetDidToggle(id: String, isOn: Bool) {
        toggles.append((id, isOn))
    }
}
