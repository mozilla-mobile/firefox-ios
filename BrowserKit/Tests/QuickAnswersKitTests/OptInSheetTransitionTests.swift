// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import QuickAnswersKit
import UIKit
import XCTest

@MainActor
final class OptInSheetTransitionTests: XCTestCase {
    private var controller: UIViewController!
    private var fallback: SourceRevealTransitionAnimator!

    override func setUp() async throws {
        try await super.setUp()
        controller = UIViewController()
        fallback = SourceRevealTransitionAnimator(sourceRect: .zero, isOptInVisible: { false })
    }

    override func tearDown() async throws {
        controller = nil
        fallback = nil
        try await super.tearDown()
    }

    // MARK: - animationController(forPresented:)
    func test_animationControllerForPresented_whenOptInSheetPending_returnsItself() {
        let subject = createSubject(isOptInSheetPending: true)

        let animator = subject.animationController(forPresented: controller, presenting: controller, source: controller)

        XCTAssertTrue(animator === subject)
    }

    func test_animationControllerForPresented_whenOptInSheetNotPending_returnsFallbackAnimator() {
        let subject = createSubject(isOptInSheetPending: false)

        let animator = subject.animationController(forPresented: controller, presenting: controller, source: controller)

        XCTAssertTrue(animator === fallback)
    }

    func test_animationControllerForPresented_withoutFallback_returnsNil() {
        let subject = createSubject(isOptInSheetPending: false, hasFallback: false)

        let animator = subject.animationController(forPresented: controller, presenting: controller, source: controller)

        XCTAssertNil(animator)
    }

    // MARK: - animationController(forDismissed:)
    func test_animationControllerForDismissed_whenOptInSheetPending_returnsItself() {
        let subject = createSubject(isOptInSheetPending: true)

        XCTAssertTrue(subject.animationController(forDismissed: controller) === subject)
    }

    func test_animationControllerForDismissed_whenOptInSheetNotPending_returnsFallbackAnimator() {
        let subject = createSubject(isOptInSheetPending: false)

        XCTAssertTrue(subject.animationController(forDismissed: controller) === fallback)
    }

    // MARK: - Helpers
    private func createSubject(isOptInSheetPending: Bool, hasFallback: Bool = true) -> OptInSheetTransition {
        return OptInSheetTransition(
            isOptInSheetPending: { isOptInSheetPending },
            fallback: hasFallback ? fallback : nil
        )
    }
}
