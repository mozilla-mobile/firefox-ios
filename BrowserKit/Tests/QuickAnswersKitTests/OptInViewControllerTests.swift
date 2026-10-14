// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import QuickAnswersKit
import Common
import TestKit
import UIKit
import XCTest

@MainActor
final class OptInViewControllerTests: XCTestCase {
    private let learnMoreURL = URL(string: "https://mozilla.org")!
    private var continueCallCount = 0
    private var dismissCallCount = 0
    private var learnMoreURLs: [URL] = []

    override func setUp() {
        super.setUp()
        continueCallCount = 0
        dismissCallCount = 0
        learnMoreURLs = []
    }

    // MARK: - continueButton
    func test_continueButton_whenTapped_completesOptIn() {
        let subject = createSubject()
        subject.loadViewIfNeeded()

        tap(continueButton(in: subject.view))

        XCTAssertEqual(continueCallCount, 1)
        XCTAssertEqual(dismissCallCount, 0)
        XCTAssertTrue(learnMoreURLs.isEmpty)
    }

    // MARK: - learnMoreButton
    func test_learnMoreButton_whenTapped_opensLearnMoreURL() {
        let subject = createSubject()
        subject.loadViewIfNeeded()

        tap(learnMoreButton(in: subject.view))

        XCTAssertEqual(learnMoreURLs, [learnMoreURL])
        XCTAssertEqual(continueCallCount, 0)
        XCTAssertEqual(dismissCallCount, 0)
    }

    func test_learnMoreButton_whenThereIsNoLearnMoreURL_isHidden() {
        let subject = createSubject(hasLearnMoreURL: false)
        subject.loadViewIfNeeded()

        let button = learnMoreButton(in: subject.view)

        XCTAssertEqual(button?.isHidden, true)
    }

    // MARK: - closeButton
    func test_closeButton_whenTapped_reportsDismissal() {
        let subject = createSubject()
        subject.loadViewIfNeeded()

        tap(closeButton(in: subject.view))

        XCTAssertEqual(dismissCallCount, 1)
        XCTAssertEqual(continueCallCount, 0)
    }

    // MARK: - presentationControllerDidDismiss
    func test_presentationControllerDidDismiss_whenSwipedAway_reportsDismissal() {
        let subject = createSubject()

        subject.presentationControllerDidDismiss(
            UIPresentationController(presentedViewController: subject, presenting: nil)
        )

        XCTAssertEqual(dismissCallCount, 1)
        XCTAssertEqual(continueCallCount, 0)
    }

    // MARK: - Helpers
    private func createSubject(
        hasLearnMoreURL: Bool = true,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> OptInViewController {
        let subject = OptInViewController(
            windowUUID: .XCTestDefaultUUID,
            themeManager: DefaultThemeManager(sharedContainerIdentifier: ""),
            learnMoreURL: hasLearnMoreURL ? learnMoreURL : nil,
            onContinue: { [weak self] in self?.continueCallCount += 1 },
            onLearnMore: { [weak self] url in self?.learnMoreURLs.append(url) },
            onDismiss: { [weak self] in self?.dismissCallCount += 1 }
        )
        trackForMemoryLeaks(subject, file: file, line: line)
        return subject
    }

    private func continueButton(in view: UIView) -> UIButton? {
        return findButton(in: view) { $0.configuration?.title == OptInViewController.UX.continueTitle }
    }

    private func learnMoreButton(in view: UIView) -> UIButton? {
        return findButton(in: view) { $0.configuration?.title == OptInViewController.UX.learnMoreTitle }
    }

    private func closeButton(in view: UIView) -> UIButton? {
        return findButton(in: view) { $0.accessibilityLabel == OptInViewController.UX.closeButtonA11yLabel }
    }

    private func findButton(in view: UIView, matching predicate: (UIButton) -> Bool) -> UIButton? {
        if let button = view as? UIButton, predicate(button) { return button }
        for subview in view.subviews {
            if let button = findButton(in: subview, matching: predicate) { return button }
        }
        return nil
    }

    private func tap(
        _ button: UIButton?,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard let button else {
            XCTFail("No button found to tap", file: file, line: line)
            return
        }
        button.sendActions(for: .touchUpInside)
    }
}
