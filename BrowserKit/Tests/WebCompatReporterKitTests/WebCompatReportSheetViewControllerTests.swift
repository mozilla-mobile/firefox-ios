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

    func testSendButton_whenTapped_notifiesDelegateWithRowID() throws {
        let delegate = MockWebCompatReportSheetDelegate()
        let subject = createSubject()
        subject.delegate = delegate
        subject.view.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        subject.loadViewIfNeeded()
        subject.configure(with: makeViewModel(sections: sendSections(isEnabled: true)))
        subject.view.layoutIfNeeded()

        let cell = collectionView(in: subject)?.cellForItem(at: IndexPath(item: 0, section: 0))
        let sendButton = try XCTUnwrap(firstSubview(ofType: UIButton.self, in: cell))
        fireActions(on: sendButton, for: .touchUpInside)

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

    func testToggleCell_activation_notifiesDelegateWithRowIDAndValue() throws {
        let delegate = MockWebCompatReportSheetDelegate()
        let subject = createSubject()
        subject.delegate = delegate
        subject.view.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        subject.loadViewIfNeeded()
        subject.configure(with: makeViewModel(sections: toggleSections()))
        subject.view.layoutIfNeeded()

        let toggleCell = collectionView(in: subject)?.cellForItem(at: IndexPath(item: 0, section: 0))
        let toggle = try XCTUnwrap(firstSubview(ofType: UISwitch.self, in: toggleCell))
        toggle.isOn = true
        fireActions(on: toggle, for: .valueChanged)

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

    func testConfigure_whenASubOptionChanges_dropsItsCheckmark() {
        let subject = createSubject()
        subject.view.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        subject.loadViewIfNeeded()
        subject.configure(with: makeViewModel(sections: subOptionAndToggleSections(isOn: false)))
        subject.view.layoutIfNeeded()

        let subOptionIndexPath = IndexPath(item: 0, section: 0)
        XCTAssertEqual(accessoryCount(in: subject, at: subOptionIndexPath), 1)

        subject.configure(
            with: makeViewModel(sections: subOptionAndToggleSections(isOn: false, isSubOptionSelected: false))
        )
        subject.view.layoutIfNeeded()

        XCTAssertEqual(accessoryCount(in: subject, at: subOptionIndexPath), 0)
    }

    func testLearnMoreFooterLinkTap_forwardsTappedURLToDelegate() throws {
        let delegate = MockWebCompatReportSheetDelegate()
        let hosted = hostedFooterSubject(delegate: delegate)
        defer { hosted.window.isHidden = true }

        let footer = try XCTUnwrap(footerView(in: hosted.controller))
        let textView = try XCTUnwrap(firstSubview(ofType: UITextView.self, in: footer))
        let linkURL = try XCTUnwrap(URL(string: "https://support.mozilla.org/kb/report-site-issues-firefox-ios"))

        let allowsDefault = footer.textView(
            textView,
            shouldInteractWith: linkURL,
            in: NSRange(location: 0, length: 0),
            interaction: .invokeDefaultAction
        )

        // The coordinator owns navigation, so the text view must not open the URL itself.
        XCTAssertFalse(allowsDefault)
        XCTAssertEqual(delegate.learnMoreURLs, [linkURL])
    }

    func testLearnMoreFooter_applyTheme_linksOnlyTheLinkTextRange() throws {
        let delegate = MockWebCompatReportSheetDelegate()
        let hosted = hostedFooterSubject(delegate: delegate)
        defer { hosted.window.isHidden = true }

        let footer = try XCTUnwrap(footerView(in: hosted.controller))
        let textView = try XCTUnwrap(firstSubview(ofType: UITextView.self, in: footer))
        let attributed = try XCTUnwrap(textView.attributedText)

        let expectedRange = (attributed.string as NSString).range(of: "Learn More…")
        var linkRange = NSRange(location: 0, length: 0)
        let linkURL = attributed.attribute(.link, at: expectedRange.location, effectiveRange: &linkRange) as? URL

        XCTAssertEqual(linkURL, URL(string: "https://support.mozilla.org/kb/report-site-issues-firefox-ios"))
        XCTAssertEqual(linkRange, expectedRange)
    }

    func testSectionWithoutFooter_rendersNoFooterSupplementary() {
        let subject = createSubject()
        subject.view.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        subject.loadViewIfNeeded()
        subject.configure(with: makeViewModel(sections: pickerSections()))
        subject.view.layoutIfNeeded()

        XCTAssertNil(footerView(in: subject))
    }

    func testConfigure_withFieldSections_dequeuesTypedCells() {
        let subject = createSubject()
        subject.view.frame = CGRect(x: 0, y: 0, width: 390, height: 2000)
        subject.loadViewIfNeeded()

        subject.configure(with: makeViewModel(sections: fieldSections()))
        subject.view.layoutIfNeeded()

        XCTAssertTrue(
            collectionView(in: subject)?.cellForItem(at: IndexPath(item: 0, section: 0)) is WebCompatURLCell
        )
        XCTAssertTrue(
            collectionView(in: subject)?.cellForItem(at: IndexPath(item: 0, section: 1)) is WebCompatDetailsCell
        )
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

    /// The accessory model, which updates synchronously — unlike the accessory views,
    /// which linger in the hierarchy while the list animates them out.
    private func accessoryCount(
        in subject: WebCompatReportSheetViewController,
        at indexPath: IndexPath
    ) -> Int? {
        let cell = collectionView(in: subject)?.cellForItem(at: indexPath) as? UICollectionViewListCell
        return cell?.accessories.count
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

    /// A key-windowed sheet whose second section carries a Learn More footer, so
    /// the supplementary view is actually realized.
    private func hostedFooterSubject(
        delegate: MockWebCompatReportSheetDelegate
    ) -> (controller: WebCompatReportSheetViewController, window: UIWindow) {
        let subject = createSubject()
        subject.delegate = delegate
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.rootViewController = subject
        window.makeKeyAndVisible()
        subject.configure(with: makeViewModel(sections: footerSections()))
        subject.view.layoutIfNeeded()
        return (subject, window)
    }

    private func footerView(in subject: WebCompatReportSheetViewController) -> WebCompatLearnMoreFooterView? {
        return collectionView(in: subject)?.supplementaryView(
            forElementKind: UICollectionView.elementKindSectionFooter,
            at: IndexPath(item: 0, section: 0)
        ) as? WebCompatLearnMoreFooterView
    }

    private func footerSections() -> [WebCompatReportViewModel.Section] {
        return [
            WebCompatReportViewModel.Section(
                id: "footer-host",
                title: "Additional Info",
                footer: WebCompatReportViewModel.Footer(
                    text: "Firefox needs this info to fix the site. Learn More…",
                    linkText: "Learn More…",
                    linkURL: URL(string: "https://support.mozilla.org/kb/report-site-issues-firefox-ios"),
                    linkA11yIdentifier: "learnMore"
                ),
                rows: [
                    WebCompatReportViewModel.Row(id: "row", title: "Row", a11yIdentifier: "row")
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
    var learnMoreURLs: [URL] = []
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

    func webCompatReportSheetDidTapButton(id: String) {
        tappedButtonIDs.append(id)
    }

    func webCompatReportSheetDidToggle(id: String, isOn: Bool) {
        toggles.append((id, isOn))
    }

    func webCompatReportSheetDidTapLearnMore(url: URL) {
        learnMoreURLs.append(url)
    }

    func webCompatReportSheetDidEditText(id: String, text: String) {
        editedText.append((id, text))
    }
}
