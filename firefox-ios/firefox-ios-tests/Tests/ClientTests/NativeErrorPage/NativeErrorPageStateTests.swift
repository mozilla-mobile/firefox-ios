// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux
import XCTest

@testable import Client

final class NativeErrorPageStateTests: XCTestCase {
    func testInitialState() {
        let initialState = createSubject()

        XCTAssertNil(initialState.model)
    }

    @MainActor
    func testLoadErrorpageData() {
        let initialState = createSubject()
        let reducer = nativeErrorPageReducer()

        let model = ErrorPageModel.internetConnection

        let action = getAction(model: model, for: .initialize)
        let newState = reducer.legacyReducer(initialState, action)

        XCTAssertEqual(newState.model, model)
    }

    @MainActor
    func testLoadCertificateErrorWithAdvancedSection() {
        let initialState = createSubject()
        let reducer = nativeErrorPageReducer()

        let advancedSection = ErrorPageModel.AdvancedSectionConfig(
            buttonText: "Advanced",
            infoText: "Firefox doesn’t trust this site because the certificate provided isn’t valid for example.com.",
            warningText: """
You might need to sign in through your network, or check your settings.
If you’re on a corporate network, your support team might have more info.
""",
            certificateErrorCode: "SSL_ERROR_BAD_CERT_DOMAIN",
            showProceedButton: true
        )

        let model = ErrorPageModel.badCertDomain(BadCertDomainModel(
            url: URL(string: "https://example.com")!,
            advancedSection: advancedSection
        ))

        let action = getAction(model: model, for: .initialize)
        let newState = reducer.legacyReducer(initialState, action)

        XCTAssertEqual(newState.model, model)
    }

    @MainActor
    func testStateModel_withGenericModelWithURL() {
        let initialState = createSubject()
        let reducer = nativeErrorPageReducer()

        let testURL = URL(string: "https://example.com/page")!
        let model = ErrorPageModel.generic(GenericErrorModel(url: testURL))

        let action = getAction(model: model, for: .initialize)
        let newState = reducer.legacyReducer(initialState, action)

        XCTAssertEqual(newState.model, model)
    }

    @MainActor
    func testStateModel_withGenericModelWithoutURL() {
        let initialState = createSubject()
        let reducer = nativeErrorPageReducer()

        let model = ErrorPageModel.generic(GenericErrorModel(url: nil))

        let action = getAction(model: model, for: .initialize)
        let newState = reducer.legacyReducer(initialState, action)

        XCTAssertEqual(newState.model, model)
    }

    @MainActor
    func testStateDefaultStatePreservesModel() {
        let initialState = createSubject()
        let reducer = nativeErrorPageReducer()

        let model = ErrorPageModel.generic(GenericErrorModel(url: URL(string: "https://example.com")!))
        let action = getAction(model: model, for: .initialize)
        let state = reducer.legacyReducer(initialState, action)

        let defaultState = NativeErrorPageState.defaultState(from: state)

        XCTAssertEqual(defaultState.model, state.model)
    }

    // MARK: - Private
    private func createSubject() -> NativeErrorPageState {
        return NativeErrorPageState(windowUUID: .XCTestDefaultUUID)
    }

    private func nativeErrorPageReducer() -> Reducer<NativeErrorPageState> {
        return NativeErrorPageState.reducer
    }

    private func getAction(
        model: ErrorPageModel,
        for actionType: NativeErrorPageMiddlewareActionType
    ) -> NativeErrorPageAction {
        return  NativeErrorPageAction(
            nativePageErrorModel: model,
            windowUUID: .XCTestDefaultUUID,
            actionType: actionType
        )
    }
}
