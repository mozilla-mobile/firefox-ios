// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import ComponentLibrary
import Common
@testable import SummarizeKit

@MainActor
class ToSBottomSheetViewControllerTests: XCTestCase {
    private var dismissDelegate: MockBottomSheetDismissDelegate!
    private let url = URL(string: "https://example.com")!

    override func setUp() {
        super.setUp()
        dismissDelegate = MockBottomSheetDismissDelegate()
    }

    override func tearDown() {
        dismissDelegate = nil
        super.tearDown()
    }

    func testTextViewShouldInteractWithURL_calssDismissDelegateAndOnRequestOpenURL() {
        let expectation = XCTestExpectation(description: "onRequestOpenURL should be called")
        let subject = createSubject { url in
            XCTAssertEqual(url, self.url)
            expectation.fulfill()
        }
        let result = subject.textView(UITextView(), shouldInteractWith: url, in: .init())

        XCTAssertFalse(result)
        XCTAssertEqual(dismissDelegate.didCallDismissSheetViewController, 1)
        wait(for: [expectation], timeout: 1.0)
    }

    func testWillDismiss_callsOnDismiss() {
        let expectation = expectation(description: "onDismiss should be called")

        let subject = createSubject(onDismiss: {
            expectation.fulfill()
        })
        subject.willDismiss()
        wait(for: [expectation], timeout: 1.0)
    }

    func testDismiss_callsDismissDelegate() {
        let subject = createSubject()

        subject.dismiss(animated: false)

        XCTAssertEqual(dismissDelegate.didCallDismissSheetViewController, 1)
    }

    func testDismiss_doesntCallDismissDelegate_whenDelegateIsNil() {
        let subject = createSubject()

        subject.dismissDelegate = nil
        subject.dismiss(animated: false)

        XCTAssertEqual(dismissDelegate.didCallDismissSheetViewController, 0)
    }

    private func createSubject(
        onRequestOpenURL: ((URL?) -> Void)? = nil,
        onAllowButtonPressed: (() -> Void)? = nil,
        onDismiss: (() -> Void)? = nil
    ) -> ToSBottomSheetViewController {
        let controller = ToSBottomSheetViewController(
            viewModel: .init(
                titleLabel: "",
                descriptionLabel: "",
                linkButtonLabel: "",
                linkButtonURL: nil,
                allowButtonTitle: "",
                allowButtonA11yId: "",
                allowButtonA11yLabel: "",
                cancelButtonTitle: "",
                cancelButtonA11yId: "",
                cancelButtonA11yLabel: "",
                onRequestOpenURL: onRequestOpenURL,
                onAllowButtonPressed: onAllowButtonPressed,
                onDismiss: onDismiss
            ),
            themeManager: DefaultThemeManager(sharedContainerIdentifier: ""),
            windowUUID: .XCTestDefaultUUID
        )
        controller.dismissDelegate = dismissDelegate
        return controller
    }
}
