// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux
import SummarizeKit
import WebKit

/// Creates summarizer configuration from a web view.
protocol SummarizerConfigFactory: Sendable {
    /// Returns config if summarization is possible, nil otherwise (e.g., unsupported language, feature disabled).
    func makeConfiguration(from webView: WKWebView) async -> SummarizerConfig?
}

@MainActor
final class SummarizerMiddleware: SummarizerConfigFactory {
    private let summarizerNimbusUtils: SummarizerNimbusUtils
    private let summarizationChecker: SummarizationCheckerProtocol
    private let summarizerServiceFactory: SummarizerServiceFactory
    private let summarizerLanguageProvider: SummarizerLanguageProvider
    private let summarizerConfigProvider: SummarizerConfigProvider
    private let logger: Logger
    private let windowManager: WindowManager
    private let profile: Profile

    init(
        logger: Logger = DefaultLogger.shared,
        windowManager: WindowManager = AppContainer.shared.resolve(),
        profile: Profile = AppContainer.shared.resolve(),
        summarizerNimbusUtility: SummarizerNimbusUtils = DefaultSummarizerNimbusUtils(),
        summarizerServiceFactory: SummarizerServiceFactory = DefaultSummarizerServiceFactory(),
        summarizationChecker: SummarizationCheckerProtocol = SummarizationChecker(),
        summarizerLanguageProvider: SummarizerLanguageProvider = DefaultSummarizerLanguageProvider(
            websiteLanguageProvider: LanguageDetector()
        ),
        summarizerConfigProvider: SummarizerConfigProvider = DefaultSummarizerConfigProvider()
    ) {
        self.logger = logger
        self.windowManager = windowManager
        self.profile = profile
        self.summarizerNimbusUtils = summarizerNimbusUtility
        self.summarizationChecker = summarizationChecker
        self.summarizerServiceFactory = summarizerServiceFactory
        self.summarizerLanguageProvider = summarizerLanguageProvider
        self.summarizerConfigProvider = summarizerConfigProvider
    }

    lazy var summarizerProvider: Middleware<AppState> = { state, action in
        switch action.actionType {
        case GeneralBrowserActionType.didTapReaderModeBarSummarizerButton:
            self.dispatchInTask(for: action, actionType: .triggerSummarizationFromReaderModeBarButton)
        case ToolbarActionType.didSummarizeSettingsChange:
            guard let action = action as? ToolbarAction else { return }
            guard action.canSummarize else {
                self.dispatchSummarizerNotAvailable(for: action)
                return
            }
            self.dispatchInTask(for: action, actionType: .showReaderModeBarSummarizerButton)
        case GeneralBrowserActionType.showReaderMode:
            self.dispatchInTask(for: action, actionType: .showReaderModeBarSummarizerButton)
        case GeneralBrowserActionType.shakeMotionEnded:
            self.dispatchInTask(for: action, actionType: .triggerSummarizationFromShakeMotion)
        default:
            break
        }
    }

    private func dispatchInTask(for action: Action, actionType: SummarizeMiddlewareActionType) {
        Task {
            await self.dispatchSummarizeConfigurationAction(for: action, actionType: actionType)
        }
    }

    private var maxWords: Int {
        summarizerServiceFactory.maxWords(
            isAppleSummarizerEnabled: summarizerNimbusUtils.isAppleSummarizerEnabled(),
            isHostedSummarizerEnabled: summarizerNimbusUtils.isHostedSummarizerEnabled()
        )
    }

    @MainActor
    private func dispatchSummarizeConfigurationAction(
        for action: Action,
        actionType: SummarizeMiddlewareActionType
    ) async {
        guard let webView = windowManager.tabManager(for: action.windowUUID).selectedTab?.webView else { return }
        guard let summarizerConfig = await makeConfiguration(from: webView) else {
            dispatchSummarizerNotAvailable(for: action)
            return
        }

        store.dispatch(
            SummarizeAction(
                windowUUID: action.windowUUID,
                actionType: actionType,
                summarizerConfig: summarizerConfig
            )
        )
    }

    func makeConfiguration(from webView: WKWebView) async -> SummarizerConfig? {
        guard summarizerNimbusUtils.isSummarizeFeatureToggledOn else { return nil }

        let preSummarizationCheckResults = await summarizationChecker.check(on: webView, maxWords: maxWords)
        guard preSummarizationCheckResults.canSummarize else { return nil }
        guard let summarizerLocale = await getSummarizerLocale(for: webView) else { return nil }

        let contentType = preSummarizationCheckResults.contentType ?? .generic
        let summarizerModel: SummarizerModel =
            summarizerNimbusUtils.isAppleSummarizerEnabled() ? .appleSummarizer : .liteLLMSummarizer

        return summarizerConfigProvider.getConfig(
            summarizerModel: summarizerModel,
            contentType: contentType,
            locale: summarizerLocale
        )
    }

    private func getSummarizerLocale(for webView: WKWebView) async -> Locale? {
        if summarizerNimbusUtils.isLanguageExpansionEnabled {
            let langExpansionConfiguration = summarizerNimbusUtils.languageExpansionConfiguration()
            return await summarizerLanguageProvider.getLanguage(
                userPreference: langExpansionConfiguration.selectedPreference(prefs: profile.prefs),
                supportedLocales: langExpansionConfiguration.supportedLocales,
                languageSampleSource: WebViewLanguageSampleSource(webView: webView)
            )
        }
        // This branch is a fallback in case Language expansion is not enabled. In this case
        // we default to the old experiment where the summarizer is available only for english websites.
        if summarizerNimbusUtils.isSummarizeFeatureEnabled {
            return await summarizerLanguageProvider.getLanguage(
                userPreference: .websiteLanguage,
                supportedLocales: [Locale(identifier: "en")],
                languageSampleSource: WebViewLanguageSampleSource(webView: webView)
            )
        }
        return nil
    }
    
    private func dispatchSummarizerNotAvailable(for action: Action) {
        store.dispatch(
            SummarizeAction(
                windowUUID: action.windowUUID,
                actionType: SummarizeMiddlewareActionType.summarizerNotAvailable,
                summarizerConfig: .defaultConfig
            )
        )
    }
}
