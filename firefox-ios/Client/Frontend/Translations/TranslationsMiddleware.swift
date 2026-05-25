// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Redux
import Common
import Shared
import UIKit

@MainActor
final class TranslationsMiddleware: FeatureFlaggable, Notifiable {
    private let profile: Profile
    private let logger: Logger
    private let windowManager: WindowManager
    private let translationsService: TranslationsServiceProtocol
    private let translationsTelemetry: TranslationsTelemetryProtocol
    private let manager: PreferredTranslationLanguagesManager
    private let localeProvider: LocaleProvider
    private let notificationCenter: NotificationProtocol

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
    /// Stores a target language for windows mid language-switch. When the page reloads after
    /// the active translation is discarded, tryAutoTranslate picks this up and translates to the
    /// requested language instead of the user's top preferred language.
    private var pendingLanguageSwitchTargets: [WindowUUID: String] = [:]
    private var translationTasks: [WindowUUID: Task<Void, Never>] = [:]
    var backgroundTimestamp: Date?
    private static let backgroundRecoveryThreshold: TimeInterval = 3

    init(profile: Profile = AppContainer.shared.resolve(),
         logger: Logger = DefaultLogger.shared,
         windowManager: WindowManager = AppContainer.shared.resolve(),
         translationsService: TranslationsServiceProtocol = TranslationsService(),
         translationsTelemetry: TranslationsTelemetryProtocol = TranslationsTelemetry(),
         manager: PreferredTranslationLanguagesManager? = nil,
         localeProvider: LocaleProvider = SystemLocaleProvider(),
         notificationCenter: NotificationProtocol = NotificationCenter.default
    ) {
        self.profile = profile
        self.logger = logger
        self.windowManager = windowManager
        self.translationsService = translationsService
        self.translationsTelemetry = translationsTelemetry
        self.manager = manager ?? PreferredTranslationLanguagesManager(prefs: profile.prefs)
        self.localeProvider = localeProvider
        self.notificationCenter = notificationCenter
        startObservingNotifications(
            withNotificationCenter: notificationCenter,
            forObserver: self,
            observing: [
                UIApplication.didEnterBackgroundNotification,
                UIApplication.willEnterForegroundNotification
            ]
        )
    }

    nonisolated func handleNotifications(_ notification: Notification) {
        let notificationName = notification.name
        ensureMainThread {
            switch notificationName {
            case UIApplication.didEnterBackgroundNotification:
                self.backgroundTimestamp = Date()
                self.cancelInFlightTranslations()
            case UIApplication.willEnterForegroundNotification:
                self.recoverInterruptedTranslations()
            default:
                break
            }
        }
    }

    lazy var translationsProvider: Middleware<AppState> = { state, action in
        let windowUUID = action.windowUUID
        switch action.actionType {
        case ToolbarActionType.urlDidChange:
            guard let action = (action as? ToolbarAction) else { return }
            self.handleUrlDidChange(action: action, windowUUID: windowUUID)

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

        case TranslationsActionType.didTranslationSettingsChange:
            guard let action = (action as? TranslationsAction) else { return }
            self.handleTranslationSettingsChange(action: action, windowUUID: windowUUID)

        default:
           break
        }
    }

    private func handleTranslationSettingsChange(action: TranslationsAction, windowUUID: WindowUUID) {
        if action.isTranslationsEnabled == false {
            for uuid in translationFlowIds.keys {
                let translationState = store.state.componentState(
                    ToolbarState.self,
                    for: .toolbar,
                    window: uuid
                )?.addressToolbar.translationConfiguration?.state
                guard translationState == .active || translationState == .loading else { continue }
                store.dispatch(GeneralBrowserAction(
                    windowUUID: uuid,
                    actionType: GeneralBrowserActionType.reloadWebsite
                ))
            }
        }
        // Clear stale per-window state so eligibility is re-evaluated from scratch
        // rather than acting on cached flow data from before the settings change.
        selectedTargetLanguages[windowUUID] = nil
        translationFlowIds[windowUUID] = nil
        translationTasks[windowUUID]?.cancel()
        translationTasks[windowUUID] = nil
        restoringWindows.remove(windowUUID)
        guard featureFlagsProvider.isEnabled(.translation),
              action.isTranslationsEnabled ?? true else { return }
        checkTranslationsAreEligible(for: action)
    }

    private func handleUrlDidChange(action: ToolbarAction, windowUUID: WindowUUID) {
        guard action.url?.isWebPage() == true else { return }
        // Tab-tray round-trip OR mid-translation tab switch: the action carries the tab's
        // persisted state. Skipping eligibility keeps Redux in sync with the WKWebView —
        // re-running would dispatch `.inactive`/`nil` and clobber `.active` (translated DOM
        // still on screen) or `.loading` (in-flight translation we'd otherwise race against).
        // `.inactive`/restore-flow paths still run so `restoringWindows` is consumed and
        // auto-translate behaves correctly.
        let persistedState = action.translationConfiguration?.state
        if persistedState == .active || persistedState == .loading { return }

        translationTasks[windowUUID]?.cancel()
        translationTasks[windowUUID] = nil
        clearFlowId(for: action)
        checkTranslationsAreEligible(for: action)
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
            handleLongPressOnTranslateButton(for: action, translationConfiguration: translationConfiguration)
            return
        }

        guard gestureType == .tap else { return }

        if translationConfiguration.state == .inactive,
           featureFlagsProvider.isEnabled(.translationLanguagePicker) {
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
            let originatingTab = selectedTab(for: action.windowUUID)
            let isPrivate = toolbarState.isPrivateMode
            Task {
                guard let deviceLanguage = await self.supportedDeviceLanguage() else { return }
                let newFlowId = UUID()
                self.translationFlowIds[action.windowUUID] = newFlowId
                self.selectedTargetLanguages[action.windowUUID] = deviceLanguage
                self.translationsTelemetry.translateButtonTapped(
                    isPrivate: isPrivate,
                    actionType: .willTranslate,
                    translationFlowId: newFlowId
                )
                self.handleUpdatingTranslationIcon(
                    windowUUID: action.windowUUID,
                    with: .loading,
                    on: originatingTab
                )
                self.retrieveTranslations(
                    windowUUID: action.windowUUID,
                    targetLanguage: deviceLanguage,
                    isPrivate: isPrivate,
                    on: originatingTab
                )
            }
        } else if translationConfiguration.state == .active {
            let originatingTab = selectedTab(for: action.windowUUID)
            translationsTelemetry.translateButtonTapped(
                isPrivate: toolbarState.isPrivateMode,
                actionType: .willRestore,
                translationFlowId: flowId(for: action.windowUUID)
            )
            self.handleUpdatingTranslationIcon(windowUUID: action.windowUUID, with: .inactive, on: originatingTab)
            restoringWindows.insert(action.windowUUID)
            // Mark the next same-URL reload as a restore-flow reload so `webView(_:didCommit:)`
            // keeps the just-dispatched `.inactive` (FXIOS-15227). Manual reloads, with this
            // flag unset, will clear the cache and re-run eligibility.
            markPendingRestoreReload(on: originatingTab)
            self.reloadPage(for: action)
        }
    }

    private func markPendingRestoreReload(on tab: Tab?) {
        tab?.onNextCommit = {}
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

    private func handleLongPressOnTranslateButton(
        for action: ToolbarMiddlewareAction,
        translationConfiguration: TranslationConfiguration
    ) {
        guard featureFlagsProvider.isEnabled(.translationLanguagePicker) else { return }

        if translationConfiguration.state == .inactive {
            let capturedButton = action.buttonTapped
            Task {
                let manager = PreferredTranslationLanguagesManager(prefs: profile.prefs)
                let supported = await translationsService.fetchSupportedTargetLanguages()
                let languages = manager.preferredLanguages(supportedTargetLanguages: supported)
                let pageLanguage = try? await translationsService.detectPageLanguage(for: action.windowUUID)
                let filteredLanguages = languages.filter { $0 != pageLanguage }
                store.dispatch(GeneralBrowserAction(
                    buttonTapped: capturedButton,
                    translationLanguages: filteredLanguages,
                    windowUUID: action.windowUUID,
                    actionType: GeneralBrowserActionType.showTranslationLanguagePicker
                ))
            }
        } else if translationConfiguration.state == .active {
            showLanguagePickerForActiveTranslation(
                for: action,
                translatedToLanguage: translationConfiguration.translatedToLanguage,
                sourceLanguage: translationConfiguration.sourceLanguage
            )
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
        let originatingTab = selectedTab(for: action.windowUUID)
        self.handleUpdatingTranslationIcon(windowUUID: action.windowUUID, with: .loading, on: originatingTab)
        retrieveTranslations(
            windowUUID: action.windowUUID,
            targetLanguage: language,
            isPrivate: isPrivate,
            on: originatingTab
        )
    }

    private func handleLanguageSelected(for action: TranslationLanguageSelectedAction, and state: AppState) {
        guard let toolbarState = state.componentState(
            ToolbarState.self,
            for: .toolbar,
            window: action.windowUUID
        ) else { return }

        let originatingTab = selectedTab(for: action.windowUUID)
        let isCurrentlyTranslated = toolbarState.addressToolbar.translationConfiguration?.state == .active
        let newFlowId = UUID()
        translationFlowIds[action.windowUUID] = newFlowId
        selectedTargetLanguages[action.windowUUID] = action.targetLanguage
        translationsTelemetry.translateButtonTapped(
            isPrivate: toolbarState.isPrivateMode,
            actionType: .willTranslate,
            translationFlowId: newFlowId
        )
        if isCurrentlyTranslated {
            pendingLanguageSwitchTargets[action.windowUUID] = action.targetLanguage
            handleUpdatingTranslationIcon(windowUUID: action.windowUUID, with: .inactive, on: originatingTab)
            store.dispatch(GeneralBrowserAction(
                windowUUID: action.windowUUID,
                actionType: GeneralBrowserActionType.reloadWebsite
            ))
        } else {
            handleUpdatingTranslationIcon(windowUUID: action.windowUUID, with: .loading, on: originatingTab)
            retrieveTranslations(
                windowUUID: action.windowUUID,
                targetLanguage: action.targetLanguage,
                isPrivate: toolbarState.isPrivateMode,
                on: originatingTab
            )
        }
    }

    private func handleUpdatingTranslationIcon(
        windowUUID: WindowUUID,
        with state: TranslationConfiguration.IconState,
        on tab: Tab? = nil
    ) {
        let config = TranslationConfiguration(prefs: profile.prefs, state: state)
        persistTranslationConfig(config, on: tab ?? selectedTab(for: windowUUID))
        let translationsAction = TranslationsAction(
            translationConfiguration: config,
            windowUUID: windowUUID,
            actionType: TranslationsActionType.didStartTranslatingPage
        )
        store.dispatch(translationsAction)
    }

    /// Mirrors the dispatched translation config onto the originating tab so it survives tab-tray
    /// round-trips — the WKWebView's translated DOM persists across tab switches and the toolbar
    /// state must stay coherent with it. Async paths must pre-capture the tab so a tab switch
    /// mid-flight does not stomp the new active tab's state.
    private func persistTranslationConfig(_ config: TranslationConfiguration?, on tab: Tab?) {
        tab?.translationConfiguration = config
    }

    private func selectedTab(for windowUUID: WindowUUID) -> Tab? {
        windowManager.tabManager(for: windowUUID)?.selectedTab
    }

    /// If auto-translate is enabled, triggers translation to the user's top preferred language.
    /// Returns `true` if auto-translation was initiated (caller should skip manual offer).
    private func tryAutoTranslate(windowUUID: WindowUUID, on tab: Tab?) async -> Bool {
        if restoringWindows.remove(windowUUID) != nil { return false }

        if let pendingLanguage = pendingLanguageSwitchTargets.removeValue(forKey: windowUUID) {
            let isPrivate = store.state.componentState(
                ToolbarState.self,
                for: .toolbar,
                window: windowUUID
            )?.isPrivateMode ?? false
            let newFlowId = UUID()
            translationFlowIds[windowUUID] = newFlowId
            selectedTargetLanguages[windowUUID] = pendingLanguage
            handleUpdatingTranslationIcon(windowUUID: windowUUID, with: .loading, on: tab)
            retrieveTranslations(windowUUID: windowUUID, targetLanguage: pendingLanguage, isPrivate: isPrivate, on: tab)
            return true
        }

        guard profile.prefs.boolForKey(PrefsKeys.Settings.translationAutoTranslate) ?? false else { return false }
        let manager = PreferredTranslationLanguagesManager(prefs: profile.prefs)
        let supported = await translationsService.fetchSupportedTargetLanguages()
        let preferred = manager.preferredLanguages(supportedTargetLanguages: supported)
        let pageLanguage = try? await translationsService.detectPageLanguage(for: windowUUID)
        if let pageLanguage, preferred.contains(pageLanguage) { return false }
        guard let targetLanguage = preferred.first else { return false }
        let isPrivate = store.state.componentState(
            ToolbarState.self,
            for: .toolbar,
            window: windowUUID
        )?.isPrivateMode ?? false
        let newFlowId = UUID()
        translationFlowIds[windowUUID] = newFlowId
        selectedTargetLanguages[windowUUID] = targetLanguage
        handleUpdatingTranslationIcon(windowUUID: windowUUID, with: .loading, on: tab)
        retrieveTranslations(
            windowUUID: windowUUID,
            targetLanguage: targetLanguage,
            isPrivate: isPrivate,
            autoTranslate: true,
            on: tab
        )
        return true
    }

    /// Returns the list of target languages to check for translation eligibility.
    /// When the language picker flag is ON, returns the user's full preferred list.
    /// When OFF, returns only the primary device language (preserving legacy behavior).
    private func targetLanguagesForEligibilityCheck() async -> [String] {
        let supported = await translationsService.fetchSupportedTargetLanguages()
        if featureFlagsProvider.isEnabled(.translationLanguagePicker) {
            return manager.preferredLanguages(supportedTargetLanguages: supported)
        }
        return [matchedDeviceLanguage(supportedTargetLanguages: supported)].compactMap { $0 }
    }

    /// Resolves the device language to the most specific code present in the supported set.
    /// Uses BCP-47 tags from `localeProvider.preferredLanguages` so script subtags like
    /// `zh-Hans` survive the lookup (Locale.languageCode would reduce them to `zh`).
    private func matchedDeviceLanguage(supportedTargetLanguages: [String]) -> String? {
        let supportedSet = Set(supportedTargetLanguages)
        for tag in localeProvider.preferredLanguages {
            if let match = PreferredTranslationLanguagesManager.matchingSupportedCode(
                for: tag,
                in: supportedSet
            ) {
                return match
            }
        }
        return nil
    }

    /// Convenience for callers (button taps, prewarm-style flows) that need just the
    /// best-matching device language string after fetching supported languages.
    private func supportedDeviceLanguage() async -> String? {
        let supported = await translationsService.fetchSupportedTargetLanguages()
        return matchedDeviceLanguage(supportedTargetLanguages: supported)
    }

    /// Checks whether the current page in the active tab is eligible for translation,
    /// and if so, dispatches a translation action to update the translation state.
    private func checkTranslationsAreEligible(for action: Action) {
        // Pre-capture the tab so a tab switch mid-flight doesn't stomp the new active tab's state.
        let originatingTab = selectedTab(for: action.windowUUID)
        // The action's `isTranslationsEnabled` carries the explicit new value for settings-change
        // actions (where store.state hasn't been updated yet). For `urlDidChange` it is nil, so we
        // fall back to ToolbarState which is always up-to-date by the time `urlDidChange` fires.
        let translationsEnabled = isTranslationsEnabled(from: action) ?? (store.state.componentState(
            ToolbarState.self,
            for: .toolbar,
            window: action.windowUUID
        )?.isTranslationsEnabled ?? true)

        guard featureFlagsProvider.isEnabled(.translation), translationsEnabled else {
            dispatchClearTranslationIcon(windowUUID: action.windowUUID, on: originatingTab)
            return
        }

        // Translation requires a live HTML DOM. PDFs and images have no translatable
        // text structure, so suppress the icon without running language detection.
        if let mimeType = originatingTab?.mimeType, mimeType != MIMEType.HTML {
            dispatchClearTranslationIcon(windowUUID: action.windowUUID, on: originatingTab)
            return
        }

        Task {
            do {
                let preferredLanguages = await targetLanguagesForEligibilityCheck()
                let isEligible = try await translationsService.shouldOfferTranslation(
                    for: action.windowUUID,
                    using: preferredLanguages
                )
                guard isEligible else {
                    self.dispatchClearTranslationIcon(windowUUID: action.windowUUID, on: originatingTab)
                    return
                }

                // Auto-translate handled the page load — skip the manual offer.
                if await self.tryAutoTranslate(windowUUID: action.windowUUID, on: originatingTab) { return }

                // Auto-translate didn't run; offer manual translation instead.
                let config = TranslationConfiguration(prefs: profile.prefs, state: .inactive)
                self.persistTranslationConfig(config, on: originatingTab)
                let translationsAction = TranslationsAction(
                    translationConfiguration: config,
                    windowUUID: action.windowUUID,
                    actionType: TranslationsActionType.receivedTranslationLanguage
                )
                store.dispatch(translationsAction)
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

    private func dispatchClearTranslationIcon(windowUUID: WindowUUID, on tab: Tab? = nil) {
        persistTranslationConfig(nil, on: tab ?? selectedTab(for: windowUUID))
        store.dispatch(TranslationsAction(
            translationConfiguration: nil,
            windowUUID: windowUUID,
            actionType: TranslationsActionType.receivedTranslationLanguage
        ))
    }

    // Pulls the optional `isTranslationsEnabled` payload from whichever action carries it.
    private func isTranslationsEnabled(from action: Action) -> Bool? {
        if let toolbarAction = action as? ToolbarAction { return toolbarAction.isTranslationsEnabled }
        if let translationsAction = action as? TranslationsAction { return translationsAction.isTranslationsEnabled }
        return nil
    }

    private func retrieveTranslations(
        windowUUID: WindowUUID,
        targetLanguage: String,
        isPrivate: Bool,
        autoTranslate: Bool = false,
        on tab: Tab? = nil
    ) {
        translationTasks[windowUUID]?.cancel()
        translationTasks[windowUUID] = Task {
            await self.performTranslation(
                windowUUID: windowUUID,
                targetLanguage: targetLanguage,
                isPrivate: isPrivate,
                autoTranslate: autoTranslate,
                on: tab
            )
            self.translationTasks[windowUUID] = nil
        }
    }

    private func performTranslation(
        windowUUID: WindowUUID,
        targetLanguage: String,
        isPrivate: Bool,
        autoTranslate: Bool,
        on tab: Tab?
    ) async {
        do {
            var detectedSourceLanguage: String?
            try await translationsService.translateCurrentPage(
                for: windowUUID,
                from: nil,
                to: targetLanguage,
                onLanguageIdentified: { identifiedLanguage, deviceLanguage in
                    detectedSourceLanguage = identifiedLanguage
                    self.translationsTelemetry.pageLanguageIdentified(
                        identifiedLanguage: identifiedLanguage,
                        deviceLanguage: deviceLanguage
                    )
                    self.translationsTelemetry.translationRequested(
                        isPrivate: isPrivate,
                        translationFlowId: self.flowId(for: windowUUID),
                        fromLanguage: identifiedLanguage,
                        toLanguage: targetLanguage,
                        autoTranslate: autoTranslate
                    )
                }
            )
            try await translationsService.firstResponseReceived(for: windowUUID)
            guard !Task.isCancelled else { return }
            dispatchAction(
                for: TranslationsActionType.translationCompleted,
                with: .active,
                translatedToLanguage: targetLanguage,
                sourceLanguage: detectedSourceLanguage,
                and: windowUUID,
                on: tab
            )
            maybeShowAutoTranslatePrompt(windowUUID: windowUUID)
        } catch {
            guard !Task.isCancelled else { return }
            let serviceError = TranslationsServiceError.fromUnknown(error)
            translationsTelemetry.translationFailed(
                translationFlowId: flowId(for: windowUUID),
                errorType: serviceError.telemetryDescription
            )
            logger.log(
                "Unable to translate page, so translation failed.",
                level: .warning,
                category: .translations,
                extra: ["Translations error": "\(error.localizedDescription)"]
            )
            self.handleErrorFromTranslatingPage(windowUUID: windowUUID, on: tab)
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

    private func cancelInFlightTranslations() {
        for (windowUUID, task) in translationTasks {
            task.cancel()
            translationTasks[windowUUID] = nil
            guard let targetLanguage = selectedTargetLanguages[windowUUID] else { continue }
            let tab = selectedTab(for: windowUUID)
            pendingLanguageSwitchTargets[windowUUID] = targetLanguage
            handleUpdatingTranslationIcon(windowUUID: windowUUID, with: .loading, on: tab)
            store.dispatch(GeneralBrowserAction(
                windowUUID: windowUUID,
                actionType: GeneralBrowserActionType.reloadWebsite
            ))
        }
    }

    private func recoverInterruptedTranslations() {
        guard let timestamp = backgroundTimestamp,
              Date().timeIntervalSince(timestamp) > Self.backgroundRecoveryThreshold else { return }
        backgroundTimestamp = nil

        for uuid in translationFlowIds.keys {
            let translationState = store.state.componentState(
                ToolbarState.self,
                for: .toolbar,
                window: uuid
            )?.addressToolbar.translationConfiguration?.state
            guard translationState == .active else { continue }
            guard let targetLanguage = selectedTargetLanguages[uuid] else { continue }

            let tab = selectedTab(for: uuid)
            pendingLanguageSwitchTargets[uuid] = targetLanguage
            handleUpdatingTranslationIcon(windowUUID: uuid, with: .loading, on: tab)
            store.dispatch(GeneralBrowserAction(
                windowUUID: uuid,
                actionType: GeneralBrowserActionType.reloadWebsite
            ))
        }
    }

    private func handleErrorFromTranslatingPage(windowUUID: WindowUUID, on tab: Tab? = nil) {
        dispatchAction(
            for: TranslationsActionType.didReceiveErrorTranslating,
            with: .inactive,
            and: windowUUID,
            on: tab
        )
        dispatchShowRetryTranslationToastAction(for: windowUUID)
    }

    private func dispatchAction(
        for actionType: TranslationsActionType,
        with state: TranslationConfiguration.IconState,
        translatedToLanguage: String? = nil,
        sourceLanguage: String? = nil,
        and windowUUID: WindowUUID,
        on tab: Tab? = nil
    ) {
        let config = TranslationConfiguration(
            prefs: profile.prefs,
            state: state,
            translatedToLanguage: translatedToLanguage,
            sourceLanguage: sourceLanguage
        )
        persistTranslationConfig(config, on: tab ?? selectedTab(for: windowUUID))
        let translationsAction = TranslationsAction(
            translationConfiguration: config,
            windowUUID: windowUUID,
            actionType: actionType
        )
        store.dispatch(translationsAction)
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
