// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Redux
import Common
import Shared

@MainActor
final class TranslationsMiddleware: LegacyFeatureFlaggable {
    private let profile: Profile
    private let logger: Logger
    private let windowManager: WindowManager
    private let translationsService: TranslationsServiceProtocol
    private let translationsTelemetry: TranslationsTelemetryProtocol
    private let manager: PreferredTranslationLanguagesManager
    private let localeProvider: LocaleProvider

    /// Multiple windows can be open simultaneously, so we track IDs in a map.
    /// On iPhone, only a single window exists, so this will contain at most one entry.
    private var translationFlowIds: [WindowUUID: UUID] = [:]

    /// Stores the last target language used per window, so retry can re-use the same language.
    private var selectedTargetLanguages: [WindowUUID: String] = [:]

    /// Tracks windows where the user explicitly restored the original (untranslated) page.
    /// Without this flag, the restore-triggered reload would fire urlDidChange and cause
    /// auto-translate to immediately re-translate the page the user just opted out of.
    /// Each entry is a one-shot flag: auto-translate is skipped for the immediately following
    /// page load for that window, then the entry is removed. On iPhone only one window exists.
    private var restoringWindows: Set<WindowUUID> = []

    init(profile: Profile = AppContainer.shared.resolve(),
         logger: Logger = DefaultLogger.shared,
         windowManager: WindowManager = AppContainer.shared.resolve(),
         translationsService: TranslationsServiceProtocol = TranslationsService(),
         translationsTelemetry: TranslationsTelemetryProtocol = TranslationsTelemetry(),
         manager: PreferredTranslationLanguagesManager? = nil,
         localeProvider: LocaleProvider = SystemLocaleProvider()
    ) {
        self.profile = profile
        self.logger = logger
        self.windowManager = windowManager
        self.translationsService = translationsService
        self.translationsTelemetry = translationsTelemetry
        self.manager = manager ?? PreferredTranslationLanguagesManager(prefs: profile.prefs)
        self.localeProvider = localeProvider
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

        case TranslationsActionType.didSelectTargetLanguage:
            guard let action = (action as? TranslationLanguageSelectedAction) else { return }
            self.handleLanguageSelected(for: action, and: state)

        case TranslationsActionType.didTapEnableAutoTranslate:
            self.profile.prefs.setBool(true, forKey: PrefsKeys.Settings.translationAutoTranslate)

        case ToolbarActionType.didTranslationSettingsChange:
            guard let action = (action as? ToolbarAction) else { return }
            // Clear stale per-window state so eligibility is re-evaluated from scratch
            // rather than acting on cached flow data from before the settings change.
            self.selectedTargetLanguages[windowUUID] = nil
            self.translationFlowIds[windowUUID] = nil
            self.restoringWindows.remove(windowUUID)
            guard action.translationConfiguration?.isTranslationFeatureEnabled == true else { return }
            self.checkTranslationsAreEligible(for: action)

        default:
           break
        }
    }

    private func handleTappingOnTranslateButton(for action: ToolbarMiddlewareAction, and state: AppState) {
        guard let gestureType = action.gestureType,
              let type = action.buttonType,
              type == .translate
        else { return }

        guard let toolbarState = state.componentState(
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

        if gestureType == .longPress {
            guard translationConfiguration.state == .active,
                  featureFlags.isFeatureEnabled(.translationLanguagePicker, checking: .buildOnly)
            else { return }
            showLanguagePickerForActiveTranslation(
                for: action,
                translatedToLanguage: translationConfiguration.translatedToLanguage,
                sourceLanguage: translationConfiguration.sourceLanguage
            )
            return
        }

        guard gestureType == .tap else { return }

        if translationConfiguration.state == .inactive,
           featureFlags.isFeatureEnabled(.translationLanguagePicker, checking: .buildOnly) {
            let capturedButton = action.buttonTapped
            Task {
                let manager = PreferredTranslationLanguagesManager(prefs: profile.prefs)
                let supported = await translationsService.fetchSupportedTargetLanguages()
                let languages = manager.preferredLanguages(supportedTargetLanguages: supported)
                let pageLanguage = try? await translationsService.detectPageLanguage(for: action.windowUUID)
                let filteredLanguages = languages.filter { $0 != pageLanguage }
                if !translationConfiguration.isMultiLanguageFlow, let singleLanguage = filteredLanguages.first {
                    store.dispatch(TranslationLanguageSelectedAction(
                        windowUUID: action.windowUUID,
                        targetLanguage: singleLanguage,
                        actionType: TranslationsActionType.didSelectTargetLanguage
                    ))
                } else {
                    store.dispatch(GeneralBrowserAction(
                        buttonTapped: capturedButton,
                        translationLanguages: filteredLanguages,
                        windowUUID: action.windowUUID,
                        actionType: GeneralBrowserActionType.showTranslationLanguagePicker
                    ))
                }
            }
        } else if translationConfiguration.state == .inactive {
            guard let deviceLanguage = Locale.current.languageCode else { return }
            let newFlowId = UUID()
            translationFlowIds[action.windowUUID] = newFlowId
            selectedTargetLanguages[action.windowUUID] = deviceLanguage
            translationsTelemetry.translateButtonTapped(
                isPrivate: toolbarState.isPrivateMode,
                actionType: .willTranslate,
                translationFlowId: newFlowId
            )
            self.handleUpdatingTranslationIcon(for: action, with: .loading)
            self.retrieveTranslations(for: action, targetLanguage: deviceLanguage, isPrivate: toolbarState.isPrivateMode)
        } else if translationConfiguration.state == .active {
            translationsTelemetry.translateButtonTapped(
                isPrivate: toolbarState.isPrivateMode,
                actionType: .willRestore,
                translationFlowId: flowId(for: action.windowUUID)
            )
            self.handleUpdatingTranslationIcon(for: action, with: .inactive)
            restoringWindows.insert(action.windowUUID)
            self.reloadPage(for: action)
        }
    }

    private func showLanguagePickerForActiveTranslation(
        for action: ToolbarMiddlewareAction,
        translatedToLanguage: String?,
        sourceLanguage: String?
    ) {
        let capturedButton = action.buttonTapped
        Task {
            let manager = PreferredTranslationLanguagesManager(prefs: profile.prefs)
            let supported = await translationsService.fetchSupportedTargetLanguages()
            let languages = manager.preferredLanguages(supportedTargetLanguages: supported)
            let filteredLanguages = languages.filter { $0 != sourceLanguage && $0 != translatedToLanguage }
            store.dispatch(GeneralBrowserAction(
                buttonTapped: capturedButton,
                translationLanguages: filteredLanguages,
                isPageTranslated: true,
                translatedToLanguage: translatedToLanguage,
                windowUUID: action.windowUUID,
                actionType: GeneralBrowserActionType.showTranslationLanguagePicker
            ))
        }
    }

    private func handleTappingRetryButtonOnToast(for action: TranslationsAction, and state: AppState) {
        guard let language = selectedTargetLanguages[action.windowUUID] else {
            logger.log(
                "Missing stored target language for retry.",
                level: .warning,
                category: .translations
            )
            return
        }
        let isPrivate = state.componentState(
            ToolbarState.self,
            for: .toolbar,
            window: action.windowUUID
        )?.isPrivateMode ?? false
        self.handleUpdatingTranslationIcon(for: action, with: .loading)
        retrieveTranslations(for: action, targetLanguage: language, isPrivate: isPrivate)
    }

    private func handleLanguageSelected(for action: TranslationLanguageSelectedAction, and state: AppState) {
        guard let toolbarState = state.componentState(
            ToolbarState.self,
            for: .toolbar,
            window: action.windowUUID
        ) else { return }

        let newFlowId = UUID()
        translationFlowIds[action.windowUUID] = newFlowId
        selectedTargetLanguages[action.windowUUID] = action.targetLanguage
        translationsTelemetry.translateButtonTapped(
            isPrivate: toolbarState.isPrivateMode,
            actionType: .willTranslate,
            translationFlowId: newFlowId
        )
        self.handleUpdatingTranslationIcon(for: action, with: .loading)
        self.retrieveTranslations(for: action, targetLanguage: action.targetLanguage, isPrivate: toolbarState.isPrivateMode)
    }

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

    /// If auto-translate is enabled, triggers translation to the user's top preferred language.
    /// Returns `true` if auto-translation was initiated (caller should skip manual offer).
    private func tryAutoTranslate(for action: ToolbarAction) async -> Bool {
        if restoringWindows.remove(action.windowUUID) != nil { return false }
        guard profile.prefs.boolForKey(PrefsKeys.Settings.translationAutoTranslate) ?? false else { return false }
        let manager = PreferredTranslationLanguagesManager(prefs: profile.prefs)
        let supported = await translationsService.fetchSupportedTargetLanguages()
        let preferred = manager.preferredLanguages(supportedTargetLanguages: supported)
        let pageLanguage = try? await translationsService.detectPageLanguage(for: action.windowUUID)
        let filteredPreferred = preferred.filter { $0 != pageLanguage }
        guard let targetLanguage = filteredPreferred.first else { return false }
        let isPrivate = store.state.componentState(
            ToolbarState.self,
            for: .toolbar,
            window: action.windowUUID
        )?.isPrivateMode ?? false
        let newFlowId = UUID()
        translationFlowIds[action.windowUUID] = newFlowId
        selectedTargetLanguages[action.windowUUID] = targetLanguage
        handleUpdatingTranslationIcon(for: action, with: .loading)
        retrieveTranslations(for: action, targetLanguage: targetLanguage, isPrivate: isPrivate, autoTranslate: true)
        return true
    }

    /// Returns the list of target languages to check for translation eligibility.
    /// When the language picker flag is ON, returns the user's full preferred list.
    /// When OFF, returns only the primary device language (preserving legacy behavior).
    private func targetLanguagesForEligibilityCheck() async -> [String] {
        if featureFlags.isFeatureEnabled(.translationLanguagePicker, checking: .buildOnly) {
            let supported = await translationsService.fetchSupportedTargetLanguages()
            return manager.preferredLanguages(supportedTargetLanguages: supported)
        }
        return [localeProvider.current.languageCode].compactMap { $0 }
    }

    /// Checks whether the current page in the active tab is eligible for translation,
    /// and if so, dispatches a toolbar action to update the translation state.
    private func checkTranslationsAreEligible(for action: ToolbarAction) {
        Task {
            guard action.translationConfiguration?.isTranslationFeatureEnabled == true else { return }

            do {
                let preferredLanguages = await targetLanguagesForEligibilityCheck()
                let isEligible = try await translationsService.shouldOfferTranslation(
                    for: action.windowUUID,
                    using: preferredLanguages
                )
                guard isEligible else {
                    self.dispatchClearTranslationIcon(windowUUID: action.windowUUID)
                    return
                }

                // Auto-translate handled the page load — skip the manual offer.
                if await self.tryAutoTranslate(for: action) { return }

                // Auto-translate didn't run; offer manual translation instead.
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

    private func dispatchClearTranslationIcon(windowUUID: WindowUUID) {
        store.dispatch(ToolbarAction(
            translationConfiguration: nil,
            windowUUID: windowUUID,
            actionType: ToolbarActionType.receivedTranslationLanguage
        ))
    }

    private func retrieveTranslations(
        for action: Action,
        targetLanguage: String,
        isPrivate: Bool,
        autoTranslate: Bool = false
    ) {
        Task {
            await self.performTranslation(
                for: action,
                targetLanguage: targetLanguage,
                isPrivate: isPrivate,
                autoTranslate: autoTranslate
            )
        }
    }

    private func performTranslation(for action: Action, targetLanguage: String, isPrivate: Bool, autoTranslate: Bool) async {
        do {
            var detectedSourceLanguage: String?
            try await translationsService.translateCurrentPage(
                for: action.windowUUID,
                to: targetLanguage,
                onLanguageIdentified: { identifiedLanguage, deviceLanguage in
                    detectedSourceLanguage = identifiedLanguage
                    self.translationsTelemetry.pageLanguageIdentified(
                        identifiedLanguage: identifiedLanguage,
                        deviceLanguage: deviceLanguage
                    )
                    self.translationsTelemetry.translationRequested(
                        isPrivate: isPrivate,
                        translationFlowId: self.flowId(for: action.windowUUID),
                        fromLanguage: identifiedLanguage,
                        toLanguage: targetLanguage,
                        autoTranslate: autoTranslate
                    )
                }
            )
            try await translationsService.firstResponseReceived(for: action.windowUUID)
            dispatchAction(
                for: ToolbarActionType.translationCompleted,
                with: .active,
                translatedToLanguage: targetLanguage,
                sourceLanguage: detectedSourceLanguage,
                and: action.windowUUID
            )
            maybeShowAutoTranslatePrompt(windowUUID: action.windowUUID)
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
        translatedToLanguage: String? = nil,
        sourceLanguage: String? = nil,
        and windowUUID: WindowUUID
    ) {
        let toolbarAction = ToolbarAction(
            translationConfiguration: TranslationConfiguration(
                prefs: profile.prefs,
                state: state,
                translatedToLanguage: translatedToLanguage,
                sourceLanguage: sourceLanguage
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

    private func maybeShowAutoTranslatePrompt(windowUUID: WindowUUID) {
        let promptShown = profile.prefs.boolForKey(PrefsKeys.Settings.translationAutoTranslatePromptShown) ?? false
        let autoTranslateEnabled = profile.prefs.boolForKey(PrefsKeys.Settings.translationAutoTranslate) ?? false
        guard !promptShown && !autoTranslateEnabled else { return }
        profile.prefs.setBool(true, forKey: PrefsKeys.Settings.translationAutoTranslatePromptShown)
        store.dispatch(TranslationsAction(
            windowUUID: windowUUID,
            actionType: TranslationsActionType.showAutoTranslatePrompt
        ))
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
