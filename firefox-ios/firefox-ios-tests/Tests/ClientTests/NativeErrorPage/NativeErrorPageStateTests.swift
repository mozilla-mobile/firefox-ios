// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux
import XCTest

@testable import Client

final class NativeErrorPageStateTests: XCTestCase {
    func testInitialState() {
        let initialState = createSubject()

        XCTAssertEqual(initialState.title, "")
        XCTAssertEqual(initialState.description, "")
        XCTAssertEqual(initialState.foxImage, "")
        XCTAssertNil(initialState.url)
        XCTAssertNil(initialState.advancedSection)
        XCTAssertFalse(initialState.showGoBackButton)
    }

    @MainActor
    func testLoadErrorpageData() {
        let initialState = createSubject()
        let reducer = nativeErrorPageReducer()

        let mockModel = ErrorPageModel(
            errorTitle: "NoInternetConnection",
            errorDescription: "There’s a problem with your internet connection.",
            foxImageName: "foxLogo",
            url: URL(
                string: "url.com"
            ),
            advancedSection: nil,
            showGoBackButton: false
        )

        let action = getAction(model: mockModel, for: .initialize)
        let newState = reducer(initialState, action)

        XCTAssertEqual(newState.title, mockModel.errorTitle)
        XCTAssertEqual(newState.description, mockModel.errorDescription)
        XCTAssertEqual(newState.foxImage, mockModel.foxImageName)
        XCTAssertEqual(newState.url, mockModel.url)
        XCTAssertNil(newState.advancedSection)
        XCTAssertFalse(newState.showGoBackButton)
    }

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

        let mockModel = ErrorPageModel(
            errorTitle: "Be careful. Something doesn’t look right.",
            errorDescription: "Someone pretending to be the site could try to steal your personal info.",
            foxImageName: "securityError",
            url: URL(string: "https://example.com"),
            advancedSection: advancedSection,
            showGoBackButton: true
        )

        let action = getAction(model: mockModel, for: .initialize)
        let newState = reducer(initialState, action)

        XCTAssertEqual(newState.title, mockModel.errorTitle)
        XCTAssertEqual(newState.description, mockModel.errorDescription)
        XCTAssertEqual(newState.foxImage, mockModel.foxImageName)
        XCTAssertEqual(newState.url, mockModel.url)
        XCTAssertTrue(newState.showGoBackButton)
        XCTAssertNotNil(newState.advancedSection)
        XCTAssertEqual(newState.advancedSection?.buttonText, advancedSection.buttonText)
        XCTAssertEqual(newState.advancedSection?.infoText, advancedSection.infoText)
        XCTAssertEqual(newState.advancedSection?.warningText, advancedSection.warningText)
        XCTAssertEqual(newState.advancedSection?.certificateErrorCode, advancedSection.certificateErrorCode)
        XCTAssertEqual(newState.advancedSection?.showProceedButton, advancedSection.showProceedButton)
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
