// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Redux
import Common

@MainActor
final class TranslationsMiddleware {
    private let profile: Profile
    private let logger: Logger
    private let languageDetector: LanguageDetectorProvider
    private let windowManager: WindowManager

    init(profile: Profile = AppContainer.shared.resolve(),
         languageDetector: LanguageDetectorProvider = LanguageDetector(),
         logger: Logger = DefaultLogger.shared,
         windowManager: WindowManager = AppContainer.shared.resolve()
    ) {
        self.profile = profile
        self.languageDetector = languageDetector
        self.logger = logger
        self.windowManager = windowManager
    }

    lazy var translationsProvider: Middleware<AppState> = { state, action in
        let windowUUID = action.windowUUID
        switch action.actionType {
        case ToolbarActionType.urlDidChange:
            guard let action = (action as? ToolbarAction) else { return }
            self.checkTranslationsAreEligible(for: action)

        case ToolbarMiddlewareActionType.didTapButton:
            guard let action = (action as? ToolbarMiddlewareAction) else { return }
            self.handleTappingOnTranslateButton(for: action, and: state)

        case TranslationsActionType.didTapRetryFailedTranslation:
            guard let action = (action as? TranslationsAction) else { return }
            self.handleTappingRetryButtonOnToast(for: action, and: state)

        default:
           break
        }
    }

    private func handleTappingOnTranslateButton(for action: ToolbarMiddlewareAction, and state: AppState) {
        guard let gestureType = action.gestureType,
              let type = action.buttonType,
              gestureType == .tap,
              type == .translate
        else { return }

        guard let toolbarState = state.screenState(
            ToolbarState.self,
            for: .toolbar,
            window: action.windowUUID
        ) else {
            return
        }

        guard let translationConfiguration = toolbarState.addressToolbar.translationConfiguration else {
            self.logger.log(
                "TranslationConfiguration is nil, redux action missing payload.",
                level: .warning,
                category: .redux
            )
            return
        }

        // When user taps on button when in inactive mode,
        // then we start translating the page and update the icon to loading.
        // When user taps on button when in active mode,
        // then we go back to inactive mode and page should reload to original language.

        // TODO: FXIOS-13844 - Only updates icon for now, connect with backend
        if translationConfiguration.state == .inactive {
            self.handleUpdatingTranslationIcon(for: action, with: .loading)
            self.retrieveTranslations(for: action)
        } else if translationConfiguration.state == .active {
            self.handleUpdatingTranslationIcon(for: action, with: .inactive)
        }
    }

    private func handleTappingRetryButtonOnToast(for action: TranslationsAction, and state: AppState) {
        self.handleUpdatingTranslationIcon(for: action, with: .loading)
        // TODO: FXIOS-13844 - Retrieve translations properly with backend, using fake call for now
        Task { @MainActor in
            try? await fetchData()
            dispatchAction(
                for: ToolbarActionType.translationCompleted,
                with: .active,
                and: action.windowUUID
            )
        }
    }

    @MainActor
    private func handleUpdatingTranslationIcon(
        for action: Action,
        with state: TranslationConfiguration.IconState
    ) {
        let toolbarAction = ToolbarAction(
            translationConfiguration: TranslationConfiguration(
                prefs: profile.prefs,
                state: state
            ),
            windowUUID: action.windowUUID,
            actionType: ToolbarActionType.didStartTranslatingPage
        )
        store.dispatch(toolbarAction)
    }

    /// Checks whether the current page in the active tab is eligible for translation,
    /// and if so, dispatches a toolbar action to update the translation state.
    private func checkTranslationsAreEligible(for action: ToolbarAction) {
        Task { @MainActor in
            guard action.translationConfiguration?.canTranslate == true else { return }

            guard let selectedTab = self.windowManager.tabManager(for: action.windowUUID).selectedTab,
                  let webView = selectedTab.webView
            else { return }

            let languageSampleSource = WebViewLanguageSampleSource(webView: webView)
            let pageLanguage = try await languageDetector.detectLanguage(from: languageSampleSource)

            guard let pageLanguage, pageLanguage != Locale.current.languageCode else { return }

            let toolbarAction = ToolbarAction(
                translationConfiguration: TranslationConfiguration(
                    prefs: profile.prefs,
                    state: .inactive
                ),
                windowUUID: action.windowUUID,
                actionType: ToolbarActionType.receivedTranslationLanguage
            )
            store.dispatch(toolbarAction)
        }
    }

    // TODO: FXIOS-13844 - Start translation a page and dispatch action after completion
    @MainActor
    private func retrieveTranslations(for action: Action) {
        // We dispatch an action for now, but eventually we want to inject a script
        // to check if the page language differs from our locale language
        // When translation completed, we want icon to be active mode.
        Task { @MainActor in
            do {
                try await fetchDataWithError()
                dispatchAction(
                    for: ToolbarActionType.translationCompleted,
                    with: .active,
                    and: action.windowUUID
                )
            } catch {
                self.handleErrorFromTranslatingPage(for: action)
            }
        }
    }

    // When we receive an error translating the page, we want to update the translation
    // icon on the toolbar to be inactive.
    // We also want to display a toast.
    private func handleErrorFromTranslatingPage(for action: Action) {
        dispatchAction(
            for: ToolbarActionType.didReceiveErrorTranslating,
            with: .inactive,
            and: action.windowUUID
        )
        dispatchShowRetryTranslationToastAction(for: action.windowUUID)
    }

    private func dispatchAction(
        for actionType: ToolbarActionType,
        with state: TranslationConfiguration.IconState,
        and windowUUID: WindowUUID
    ) {
        let toolbarAction = ToolbarAction(
            translationConfiguration: TranslationConfiguration(
                prefs: profile.prefs,
                state: state
            ),
            windowUUID: windowUUID,
            actionType: actionType
        )
        store.dispatch(toolbarAction)
    }

    private func dispatchShowRetryTranslationToastAction(
        for windowUUID: WindowUUID
    ) {
        let toastAction = GeneralBrowserAction(
            toastType: .retryTranslatingPage,
            windowUUID: windowUUID,
            actionType: GeneralBrowserActionType.showToast
        )
        store.dispatch(toastAction)
    }

    // TODO: FXIOS-13844 - Simulate a fake asynchronous call for now
    private func fetchDataWithError() async throws {
        enum ExampleError: Error { case example }
        throw ExampleError.example
    }

    private func fetchData() async throws {
        try? await Task.sleep(nanoseconds: 2_000_000_000)
    }
}
