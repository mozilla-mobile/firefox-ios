import Redux
import XCTest

@testable import Client

final class NativeErrorPageStateTests: XCTestCase {
    func testInitialState() {
        let initialState = createSubject()

        XCTAssertNil(initialState.model)
        XCTAssertEqual(initialState.title, "")
        XCTAssertEqual(initialState.description, "")
        XCTAssertEqual(initialState.foxImage, "")
        XCTAssertNil(initialState.url)
        XCTAssertNil(initialState.advancedSection)
        XCTAssertFalse(initialState.isRegularUI)
    }

    @MainActor
    func testLoadErrorpageData() {
        let initialState = createSubject()
        let reducer = nativeErrorPageReducer()

        let model = ErrorPageModel.internetConnection

        let action = getAction(model: model, for: .initialize)
        let newState = reducer(initialState, action)

        XCTAssertEqual(newState.title, model.title)
        XCTAssertEqual(newState.description, model.description)
        XCTAssertEqual(newState.foxImage, model.foxImageName)
        XCTAssertNil(newState.url)
        XCTAssertNil(newState.advancedSection)
        XCTAssertTrue(newState.isRegularUI)
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
            url: URL(string: "https://example.com"),
            advancedSection: advancedSection
        ))

        let action = getAction(model: model, for: .initialize)
        let newState = reducer(initialState, action)

        XCTAssertEqual(newState.title, model.title)
        XCTAssertEqual(newState.description, model.description)
        XCTAssertEqual(newState.foxImage, model.foxImageName)
        XCTAssertEqual(newState.url, model.url)
        XCTAssertFalse(newState.isRegularUI)
        XCTAssertNotNil(newState.advancedSection)
        XCTAssertEqual(newState.advancedSection?.buttonText, advancedSection.buttonText)
        XCTAssertEqual(newState.advancedSection?.infoText, advancedSection.infoText)
        XCTAssertEqual(newState.advancedSection?.warningText, advancedSection.warningText)
        XCTAssertEqual(newState.advancedSection?.certificateErrorCode, advancedSection.certificateErrorCode)
        XCTAssertEqual(newState.advancedSection?.showProceedButton, advancedSection.showProceedButton)
    }

    @MainActor
    func testStateComputedProperties_withGenericModelWithURL() {
        let initialState = createSubject()
        let reducer = nativeErrorPageReducer()

        let testURL = URL(string: "https://example.com/page")!
        let model = ErrorPageModel.generic(GenericErrorModel(url: testURL))

        let action = getAction(model: model, for: .initialize)
        let newState = reducer(initialState, action)

        XCTAssertEqual(newState.title, .NativeErrorPage.GenericError.TitleLabel)
        XCTAssertEqual(newState.description, .NativeErrorPage.GenericError.Description)
        XCTAssertEqual(newState.foxImage, ImageIdentifiers.NativeErrorPage.securityError)
        XCTAssertEqual(newState.url, testURL)
        XCTAssertNil(newState.advancedSection)
        XCTAssertTrue(newState.isRegularUI)
    }

    @MainActor
    func testStateComputedProperties_withGenericModelWithoutURL() {
        let initialState = createSubject()
        let reducer = nativeErrorPageReducer()

        let model = ErrorPageModel.generic(GenericErrorModel(url: nil))

        let action = getAction(model: model, for: .initialize)
        let newState = reducer(initialState, action)

        XCTAssertEqual(newState.title, .NativeErrorPage.GenericError.TitleLabel)
        XCTAssertNil(newState.url)
        XCTAssertNil(newState.advancedSection)
        XCTAssertTrue(newState.isRegularUI)
    }

    @MainActor
    func testStateDefaultStatePreservesModel() {
        let initialState = createSubject()
        let reducer = nativeErrorPageReducer()

        let model = ErrorPageModel.generic(GenericErrorModel(url: URL(string: "https://example.com")!))
        let action = getAction(model: model, for: .initialize)
        let state = reducer(initialState, action)

        let defaultState = NativeErrorPageState.defaultState(from: state)

        XCTAssertEqual(defaultState.model, state.model)
        XCTAssertEqual(defaultState.title, state.title)
        XCTAssertEqual(defaultState.url, state.url)
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
