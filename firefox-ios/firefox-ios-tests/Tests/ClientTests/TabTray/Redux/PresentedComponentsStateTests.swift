// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux
import XCTest

@testable import Client

/// Tests for `PresentedComponentsState`'s add/remove/reduce behavior and `AppState.componentState`,
/// with a focus on the per-instance `screenIdentity` on
/// confirming that entries without an identity keep the original `(component, window)` behavior.
final class PresentedComponentsStateTests: XCTestCase {
    private let windowA: WindowUUID = .XCTestDefaultUUID
    private let windowB = UUID(uuidString: "44BA0B7D-097A-484D-8358-91A6E374451D")!

    // MARK: - addComponent
    @MainActor
    func testAddComponent_withIdentity_storesEntryTaggedWithThatIdentity() {
        let identity = UUID()
        let state = PresentedComponentsState()

        let result = PresentedComponentsState.reducer.legacyReducer(
            state,
            addAction(.tabsPanel, identity: identity)
        )

        XCTAssertEqual(result.components.count, 1)
        XCTAssertEqual(result.components.first?.screenIdentity, identity)
        XCTAssertEqual(result.components.first?.state.associatedAppComponent, .tabsPanel)
    }

    @MainActor
    func testAddComponent_withoutIdentity_storesEntryWithNilIdentity() {
        let state = PresentedComponentsState()

        let result = PresentedComponentsState.reducer.legacyReducer(
            state,
            addAction(.tabsPanel, identity: nil)
        )

        XCTAssertEqual(result.components.count, 1)
        XCTAssertNil(result.components.first?.screenIdentity)
    }

    // MARK: - removeComponent
    @MainActor
    func testRemoveComponent_withIdentity_removesOnlyThatInstance() {
        let keep = UUID()
        let remove = UUID()
        let state = makeState([
            tabsComponent(identity: remove),
            tabsComponent(identity: keep)
        ])

        let result = PresentedComponentsState.reducer.legacyReducer(
            state,
            removeAction(.tabsPanel, identity: remove)
        )

        XCTAssertEqual(tabsPanelIdentities(in: result), [keep])
    }

    @MainActor
    func testRemoveComponent_withoutIdentity_removesEveryMatchingEntry() {
        let tabPeekComponent = ActiveComponent(
            screenIdentity: nil,
            state: .tabPeek(
                TabPeekState(
                    windowUUID: .XCTestDefaultUUID
                )
            )
        )
        let state = makeState([
            tabsComponent(identity: UUID()),
            tabsComponent(identity: UUID()),
            tabPeekComponent
        ])

        let result = PresentedComponentsState.reducer.legacyReducer(
            state,
            removeAction(.tabsPanel, identity: nil)
        )

        XCTAssertTrue(tabsPanelIdentities(in: result).isEmpty, "All .tabsPanel entries should be removed.")
        XCTAssertTrue(
            result.components.contains { $0.state.associatedAppComponent == .tabPeek },
            "A different component should be untouched."
        )
    }

    @MainActor
    func testRemoveComponent_withUnknownIdentity_isNoOp() {
        let first = UUID()
        let second = UUID()
        let state = makeState([
            tabsComponent(identity: first),
            tabsComponent(identity: second)
        ])

        let result = PresentedComponentsState.reducer.legacyReducer(
            state,
            removeAction(.tabsPanel, identity: UUID())  // not present
        )

        XCTAssertEqual(tabsPanelIdentities(in: result), [first, second])
    }

    @MainActor
    func testRemoveComponent_isScopedToWindow() {
        let state = makeState([
            tabsComponent(identity: nil, window: windowA),
            tabsComponent(identity: nil, window: windowB)
        ])

        let result = PresentedComponentsState.reducer.legacyReducer(
            state,
            removeAction(.tabsPanel, window: windowA, identity: nil)
        )

        let remainingWindows = result.components
            .filter { $0.state.associatedAppComponent == .tabsPanel }
            .compactMap { $0.state.windowUUID }
        XCTAssertEqual(remainingWindows, [windowB])
    }

    // MARK: - Identity preservation across reduces
    @MainActor
    func testLegacyReduce_nonComponentAction_preservesIdentity() {
        let identity = UUID()
        let state = makeState([tabsComponent(identity: identity)])

        // A real, non-`ComponentAction` action: the reducer must not add/remove or drop identity.
        let result = PresentedComponentsState.reducer.legacyReducer(
            state,
            TabPanelViewAction(panelType: .tabs,
                               windowUUID: windowA,
                               actionType: TabPanelViewActionType.closeTab)
        )

        XCTAssertEqual(result.components.count, 1)
        XCTAssertEqual(result.components.first?.screenIdentity, identity)
        XCTAssertEqual(result.components.first?.state.associatedAppComponent, .tabsPanel)
    }

    @MainActor
    func testModernReduce_preservesIdentityAndDoesNotAddOrRemove() {
        let identity = UUID()
        let tabPeekComponent = ActiveComponent(
            screenIdentity: nil,
            state: .tabPeek(
                TabPeekState(
                    windowUUID: .XCTestDefaultUUID
                )
            )
        )
        let state = makeState([tabsComponent(identity: identity), tabPeekComponent])

        let result = PresentedComponentsState.reducer.modernReducer(
            state,
            TestModernAction(),
            windowA
        )

        XCTAssertEqual(result.components.count, 2, "Modern reducer must not add or remove components.")
        XCTAssertEqual(tabsPanelIdentities(in: result), [identity], "Identity must survive a modern action.")
        XCTAssertTrue(result.components.contains { $0.state.associatedAppComponent == .tabPeek })
    }

    // MARK: - AppState.componentState
    @MainActor
    func testComponentState_withIdentity_returnsThatInstancesState() {
        let normalIdentity = UUID()
        let privateIdentity = UUID()
        let appState = AppState(presentedComponents: makeState([
            tabsComponent(identity: normalIdentity, isPrivate: false),
            tabsComponent(identity: privateIdentity, isPrivate: true)
        ]))

        let normal = appState.componentState(
            TabsPanelState.self, for: .tabsPanel, window: windowA, screenIdentity: normalIdentity
        )
        let privateState = appState.componentState(
            TabsPanelState.self, for: .tabsPanel, window: windowA, screenIdentity: privateIdentity
        )

        XCTAssertEqual(normal?.isPrivateMode, false)
        XCTAssertEqual(privateState?.isPrivateMode, true)
    }

    @MainActor
    func testComponentState_withoutIdentity_returnsFirstMatch() {
        let appState = AppState(presentedComponents: makeState([
            tabsComponent(identity: UUID(), isPrivate: false),
            tabsComponent(identity: UUID(), isPrivate: true)
        ]))

        let result = appState.componentState(TabsPanelState.self, for: .tabsPanel, window: windowA)

        // No identity → original behavior: first matching entry (the normal one, added first).
        XCTAssertEqual(result?.isPrivateMode, false)
    }

    @MainActor
    func testComponentState_withUnknownIdentity_returnsNil() {
        let appState = AppState(presentedComponents: makeState([tabsComponent(identity: UUID())]))
        let result = appState.componentState(
            TabsPanelState.self, for: .tabsPanel, window: windowA, screenIdentity: UUID()
        )

        XCTAssertNil(result)
    }

    // MARK: - Helpers
    private func makeState(_ components: [ActiveComponent]) -> PresentedComponentsState {
        return PresentedComponentsState(components: components)
    }

    private func tabsComponent(identity: UUID?,
                               window: WindowUUID = .XCTestDefaultUUID,
                               isPrivate: Bool = false) -> ActiveComponent {
        return ActiveComponent(
            screenIdentity: identity,
            state: .tabsPanel(TabsPanelState(windowUUID: window, isPrivateMode: isPrivate))
        )
    }

    private func addAction(_ component: AppComponent,
                           window: WindowUUID = .XCTestDefaultUUID,
                           identity: UUID?) -> ComponentAction {
        return ComponentAction(windowUUID: window,
                               actionType: ComponentActionType.addComponent,
                               component: component,
                               screenIdentity: identity)
    }

    private func removeAction(_ component: AppComponent,
                              window: WindowUUID = .XCTestDefaultUUID,
                              identity: UUID?) -> ComponentAction {
        return ComponentAction(windowUUID: window,
                               actionType: ComponentActionType.removeComponent,
                               component: component,
                               screenIdentity: identity)
    }

    private func tabsPanelIdentities(in state: PresentedComponentsState) -> [UUID?] {
        return state.components
            .filter { $0.state.associatedAppComponent == .tabsPanel }
            .map { $0.screenIdentity }
    }
}

// The Client module has no concrete `ModernAction` yet, so this minimal stand-in is the only way to
// drive the modern reducer path in a test.
private struct TestModernAction: ModernAction {
    let description = "TestModernAction"
}
