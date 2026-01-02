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
    private let windowManager: WindowManager
    private let translationsService: TranslationsServiceProtocol
    private let translationsTelemetry: TranslationsTelemetryProtocol

    /// Multiple windows can be open simultaneously, so we track IDs in a map.
    /// On iPhone, only a single window exists, so this will contain at most one entry.
    private var translationFlowIds: [WindowUUID: UUID] = [:]

    init(profile: Profile = AppContainer.shared.resolve(),
         logger: Logger = DefaultLogger.shared,
         windowManager: WindowManager = AppContainer.shared.resolve(),
         translationsService: TranslationsServiceProtocol = TranslationsService(),
         translationsTelemetry: TranslationsTelemetryProtocol = TranslationsTelemetry(),
    ) {
        self.profile = profile
        self.logger = logger
        self.windowManager = windowManager
        self.translationsService = translationsService
        self.translationsTelemetry = translationsTelemetry
    }

    lazy var translationsProvider: Middleware<AppState> = { state, action in
        let windowUUID = action.windowUUID
        switch action.actionType {
        case ToolbarActionType.urlDidChange:
            guard let action = (action as? ToolbarAction) else { return }

            guard action.url?.isWebPage() == true else { return }
            self.clearFlowId(for: action)
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

        if translationConfiguration.state == .inactive {
            let newFlowId = UUID()
            translationFlowIds[action.windowUUID] = newFlowId
            translationsTelemetry.translateButtonTapped(
                isPrivate: toolbarState.isPrivateMode,
                actionType: .willTranslate,
                translationFlowId: newFlowId
            )
            self.handleUpdatingTranslationIcon(for: action, with: .loading)
            self.retrieveTranslations(for: action)
        } else if translationConfiguration.state == .active {
            translationsTelemetry.translateButtonTapped(
                isPrivate: toolbarState.isPrivateMode,
                actionType: .willRestore,
                translationFlowId: flowId(for: action.windowUUID)
            )
            self.handleUpdatingTranslationIcon(for: action, with: .inactive)
            self.reloadPage(for: action)
        }
    }

    private func handleTappingRetryButtonOnToast(for action: TranslationsAction, and state: AppState) {
        self.handleUpdatingTranslationIcon(for: action, with: .loading)
        retrieveTranslations(for: action)
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
            guard action.translationConfiguration?.isTranslationFeatureEnabled == true else { return }

            do {
                guard try await translationsService.shouldOfferTranslation(for: action.windowUUID) else { return }
                let toolbarAction = ToolbarAction(
                    translationConfiguration: TranslationConfiguration(
                        prefs: profile.prefs,
                        state: .inactive
                    ),
                    windowUUID: action.windowUUID,
                    actionType: ToolbarActionType.receivedTranslationLanguage
                )
                store.dispatch(toolbarAction)
            } catch {
                let serviceError = TranslationsServiceError.fromUnknown(error)
                translationsTelemetry.pageLanguageIdentificationFailed(
                    errorType: serviceError.telemetryDescription
                )
                logger.log(
                    "Unable to detect language from page to determine if eligible for translations.",
                    level: .warning,
                    category: .translations,
                    extra: ["LanguageDetector error": "\(error.localizedDescription)"]
                )
            }
        }
    }

    @MainActor
    private func retrieveTranslations(for action: Action) {
        // We dispatch an action for now, but eventually we want to inject a script
        // to check if the page language differs from our locale language
        // When translation completed, we want icon to be active mode.
        Task { @MainActor in
            do {
                try await translationsService.translateCurrentPage(
                    for: action.windowUUID,
                    onLanguageIdentified: { identifiedLanguage, deviceLanguage in
                        self.translationsTelemetry.pageLanguageIdentified(
                            identifiedLanguage: identifiedLanguage,
                            deviceLanguage: deviceLanguage
                        )
                    }
                )
                try await translationsService.firstResponseReceived(for: action.windowUUID)
                dispatchAction(
                    for: ToolbarActionType.translationCompleted,
                    with: .active,
                    and: action.windowUUID
                )
            } catch {
                let serviceError = TranslationsServiceError.fromUnknown(error)
                translationsTelemetry.translationFailed(
                    translationFlowId: flowId(for: action.windowUUID),
                    errorType: serviceError.telemetryDescription
                )
                logger.log(
                    "Unable to translate page, so translation failed.",
                    level: .warning,
                    category: .translations,
                    extra: ["Translations error": "\(error.localizedDescription)"]
                )
                self.handleErrorFromTranslatingPage(for: action)
            }
        }
    }

    // Reloads web view if user taps on translation button to view original page after translating
    private func reloadPage(for action: Action) {
        let reloadAction = GeneralBrowserAction(
            windowUUID: action.windowUUID,
            actionType: GeneralBrowserActionType.reloadWebsite
        )
        store.dispatch(reloadAction)
        translationsTelemetry.webpageRestored(translationFlowId: flowId(for: action.windowUUID))
        clearFlowId(for: action)
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

    /// Clears the flow ID for the given action's window.
    private func clearFlowId(for action: Action) {
        translationFlowIds[action.windowUUID] = nil
    }

    /// Returns the existing flow ID for this window, or generates a fallback one.
    /// NOTE: Flow IDs should normally always exist by the time we need them, since they are
    /// created when the user taps the translate button. If we ever observe
    /// `translation_failed` or `webpage_restored` events whose flow ID does not match
    /// any earlier `translate_button_tapped` event, that means we're losing session
    /// correlation somewhere.
    /// If this starts happening, we may need to revisit this logic or switch to using
    /// a dedicated `<unknown>` sentinel ID instead of generating a random fallback UUID.
    private func flowId(for windowUUID: WindowUUID) -> UUID {
        if let existing = translationFlowIds[windowUUID] {
            return existing
        }

        logger.log(
            "Missing translationFlowId for this window; generating fallback UUID.",
            level: .warning,
            category: .translations,
            extra: ["windowUUID": "\(windowUUID)"]
        )

        return UUID()
    }
}
