// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import XCTest
@testable import ToolbarKit

@MainActor
final class LocationViewTests: XCTestCase {
    private var delegate: MockLocationViewDelegate!
    private let testURL = URL(string: "https://mozilla.org")!

    override func setUp() async throws {
        try await super.setUp()
        delegate = MockLocationViewDelegate()
    }

    override func tearDown() async throws {
        delegate = nil
        try await super.tearDown()
    }

    // MARK: - Icon Container Arrangement
    func testConfigure_whenNotEditingWithURL_showsLockIcon() {
        let subject = createSubject()
        subject.configure(makeConfig(url: testURL), delegate: delegate)

        XCTAssertEqual(subject.iconContainerStackView.arrangedSubviews.count, 1)
        XCTAssertTrue(subject.iconContainerStackView.arrangedSubviews.first === subject.lockIconButton,
                      "A loaded page should show the lock icon in the container.")
    }

    func testConfigure_whenEditing_showsSearchEngineView() {
        let subject = createSubject()
        subject.configure(makeConfig(url: nil, isEditing: true), delegate: delegate)

        XCTAssertTrue(subject.iconContainerStackView.arrangedSubviews.first === subject.searchEngineContentView,
                      "Editing should show the search engine view in the container.")
    }

    func testConfigure_walledTwiceWithSameState_seepsIdenticalArrangement() {
        let subject = createSubject()
        let config = makeConfig(url: testURL)

        subject.configure(config, delegate: delegate)
        let firstArrangement = subject.iconContainerStackView.arrangedSubviews

        subject.configure(config, delegate: delegate)

        let isUnchanged = subject.iconContainerStackView.arrangedSubviews.elementsEqual(firstArrangement) { $0 === $1 }
        XCTAssertTrue(isUnchanged, "Reconfiguring with the same state should leave the icon container untouched.")
    }

    func testConfigure_whenStateChangesFromURLToEditing_rebuildsArrangement() {
        let subject = createSubject()

        subject.configure(makeConfig(url: testURL), delegate: delegate)
        XCTAssertTrue(subject.iconContainerStackView.arrangedSubviews.first === subject.lockIconButton)

        subject.configure(makeConfig(url: nil, isEditing: true), delegate: delegate)

        XCTAssertTrue(subject.iconContainerStackView.arrangedSubviews.first === subject.searchEngineContentView,
                      "A real state change must still rebuild the icon container.")
    }

    // MARK: - Icon Alphas
    func testConfigure_whenNotEditingWithURL_showsLockIconAlphas() {
        let subject = createSubject()
        invalidateIconAlphas(on: subject)

        subject.configure(makeConfig(url: testURL), delegate: delegate)

        XCTAssertEqual(subject.lockIconButton.alpha, 1, "The lock icon should be visible for a loaded page.")
        XCTAssertEqual(subject.searchEngineContentView.alpha, 0, "The search engine view should be hidden.")
    }

    func testConfigure_whenEditing_showsSearchEngineAlphas() {
        let subject = createSubject()
        invalidateIconAlphas(on: subject)

        subject.configure(makeConfig(url: nil, isEditing: true), delegate: delegate)

        XCTAssertEqual(subject.lockIconButton.alpha, 0, "The lock icon should be hidden while editing.")
        XCTAssertEqual(subject.searchEngineContentView.alpha, 1, "The search engine view should be visible.")
    }

    func testConfigure_whenStateChanges_updatesAlphasDespiteSkipGuard() {
        let subject = createSubject()
        invalidateIconAlphas(on: subject)

        subject.configure(makeConfig(url: testURL), delegate: delegate)
        XCTAssertEqual(subject.lockIconButton.alpha, 1)
        XCTAssertEqual(subject.searchEngineContentView.alpha, 0)

        subject.configure(makeConfig(url: nil, isEditing: true), delegate: delegate)

        let message = "The skip-when-unchanged guard must not block a genuine alpha change."
        XCTAssertEqual(subject.lockIconButton.alpha, 0, message)
        XCTAssertEqual(subject.searchEngineContentView.alpha, 1, message)
    }

    // MARK: - Helpers
    /// Puts both icons at an alpha no expected value matches, so the assertions fail unless the
    /// code under test actually writes them.
    private func invalidateIconAlphas(on subject: LocationView) {
        subject.lockIconButton.alpha = 0.42
        subject.searchEngineContentView.alpha = 0.42
    }

    private func createSubject(file: StaticString = #filePath, line: UInt = #line) -> LocationView {
        let subject = LocationView(frame: CGRect(x: 0, y: 0, width: 320, height: 44))
        trackForMemoryLeaks(subject, file: file, line: line)
        return subject
    }

    private func makeConfig(url: URL?, isEditing: Bool = false) -> LocationViewConfiguration {
        return LocationViewConfiguration(
            searchEngineImageViewA11yId: "searchEngineA11yId",
            searchEngineImageViewA11yLabel: "searchEngineA11yLabel",
            lockIconButtonA11yId: "lockIconA11yId",
            lockIconButtonA11yLabel: "lockIconA11yLabel",
            urlTextFieldPlaceholder: "placeholder",
            urlTextFieldA11yId: "urlTextFieldA11yId",
            searchEngineImage: UIImage(),
            lockIconImageName: "lockIcon",
            lockIconNeedsTheming: false,
            safeListedURLImageName: nil,
            url: url,
            droppableUrl: nil,
            searchTerm: nil,
            isEditing: isEditing,
            didStartTyping: false,
            shouldShowKeyboard: false,
            shouldSelectSearchTerm: false
        )
    }
}

private extension LocationView {
    func configure(_ config: LocationViewConfiguration, delegate: LocationViewDelegate) {
        configure(config,
                  delegate: delegate,
                  isUnifiedSearchEnabled: false,
                  uxConfig: .default(),
                  addressBarPosition: .top)
    }
}

@MainActor
private final class MockLocationViewDelegate: LocationViewDelegate {
    func locationViewDidEnterText(_ text: String) {}
    func locationViewDidClearText() {}
    func locationViewDidBeginEditing(_ text: String, shouldShowSuggestions: Bool) {}
    func locationViewDidSubmitText(_ text: String) {}
    func locationViewDidTapSearchEngine<T: SearchEngineView>(_ searchEngine: T) {}
    func locationViewAccessibilityActions() -> [UIAccessibilityCustomAction]? { return nil }
    func locationTextFieldNeedsSearchReset() {}
    func locationViewDidDisplayEditingAccessoryButton(_ button: UIButton, contextualHintType: String) {}
}
