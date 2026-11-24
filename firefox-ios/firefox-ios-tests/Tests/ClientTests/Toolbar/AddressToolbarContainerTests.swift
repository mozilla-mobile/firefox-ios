// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux
import ToolbarKit
import XCTest

@testable import Client

@MainActor
final class AddressToolbarContainerTests: XCTestCase, StoreTestUtility {
    private let windowUUID: WindowUUID = .XCTestDefaultUUID
    private var delegate: MockAddressToolbarContainerDelegate!
    var mockStore: MockStoreForMiddleware<AppState>!

    override func setUp() async throws {
        try await super.setUp()
        DependencyHelperMock().bootstrapDependencies(injectedTabManager: MockTabManager())
        delegate = MockAddressToolbarContainerDelegate()
        setupStore()
    }

    override func tearDown() async throws {
        delegate = nil
        resetStore()
        DependencyHelperMock().reset()
        try await super.tearDown()
    }

    func testNewState_whenMinimizedStateChanges_notifiesDelegate() {
        let subject = createSubject()

        subject.newState(state: createLens(isAddressBarMinimized: true))
        subject.newState(state: createLens(isAddressBarMinimized: false))

        XCTAssertEqual(delegate.didChangeMinimizedStateCallCount, 2)
    }

    func testNewState_whenMinimizedStateIsUnchanged_doesNotNotifyDelegate() {
        let subject = createSubject()
        subject.newState(state: createLens(isAddressBarMinimized: true))

        subject.newState(state: createLens(isAddressBarMinimized: true, numberOfTabs: 2))

        XCTAssertEqual(delegate.didChangeMinimizedStateCallCount, 1)
    }

    // MARK: - Helpers

    private func createSubject() -> AddressToolbarContainer {
        let subject = AddressToolbarContainer()
        subject.configure(
            windowUUID: windowUUID,
            profile: makeProfile(),
            searchEnginesManager: MockSearchEnginesManager(),
            delegate: delegate,
            isUnifiedSearchEnabled: false,
            isBottomSearchBar: true
        )
        // Start from an expanded toolbar so each test only counts the changes it triggers.
        subject.newState(state: createLens(isAddressBarMinimized: false))
        delegate.didChangeMinimizedStateCallCount = 0
        return subject
    }

    private func createLens(isAddressBarMinimized: Bool, numberOfTabs: Int = 1) -> AddressToolbarContainerLens {
        let toolbarState = ToolbarState(windowUUID: windowUUID)
            .copy(toolbarPosition: .bottom)
            .copy(isAddressBarMinimized: isAddressBarMinimized)
            .copy(numberOfTabs: numberOfTabs)
        let appState = AppState(presentedComponents: PresentedComponentsState(components: [
            .toolbar(toolbarState),
            .browserViewController(BrowserViewControllerState(windowUUID: windowUUID))
        ]))
        return AddressToolbarContainerLens(appState: appState, uuid: windowUUID)
    }

    // MARK: - StoreTestUtility

    func setupAppState() -> AppState {
        return AppState()
    }
}

private final class MockAddressToolbarContainerDelegate: AddressToolbarContainerDelegate {
    var didChangeMinimizedStateCallCount = 0

    func searchSuggestions(searchTerm: String) {}
    func openBrowser(searchTerm: String) {}
    func openSuggestions(searchTerm: String) {}
    func configureContextualHint(for button: UIButton, with contextualHintType: String) {}
    func addressToolbarDidHideEditingAccessoryButton() {}
    func addressToolbarDidBeginEditing(searchTerm: String, shouldShowSuggestions: Bool) {}
    func addressToolbarContainerAccessibilityActions() -> [UIAccessibilityCustomAction]? { return nil }
    func addressToolbarDidEnterOverlayMode(_ view: UIView) {}
    func addressToolbar(_ view: UIView, didLeaveOverlayModeForReason: URLBarLeaveOverlayModeReason) {}
    func addressToolbarDidBeginDragInteraction() {}
    func addressToolbarDidTapSearchEngine(_ searchEngineView: UIView) {}
    func addressToolbarDidChangeMinimizedState() {
        didChangeMinimizedStateCallCount += 1
    }
    func contextMenu(for actionType: ToolbarActionConfiguration.ActionType) -> UIMenu? { return nil }
}
