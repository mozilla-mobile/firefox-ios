// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux
import SummarizeKit
import WebKit

@MainActor
final class SummarizerMiddleware {
    private let summarizerNimbusUtils: SummarizerNimbusUtils
    private let summarizationChecker: SummarizationCheckerProtocol
    private let summarizerServiceFactory: SummarizerServiceFactory
    private let summarizerLanguageProvider: SummarizerLanguageProvider
    private let logger: Logger
    private let windowManager: WindowManager
    private let profile: Profile
    private var summarizerType: SummarizerModel {
        return summarizerNimbusUtils.isAppleSummarizerEnabled() ? .appleSummarizer : .liteLLMSummarizer
    }

    init(
        logger: Logger = DefaultLogger.shared,
        windowManager: WindowManager = AppContainer.shared.resolve(),
        profile: Profile = AppContainer.shared.resolve(),
        summarizerNimbusUtility: SummarizerNimbusUtils = DefaultSummarizerNimbusUtils(),
        summarizerServiceFactory: SummarizerServiceFactory = DefaultSummarizerServiceFactory(),
        summarizationChecker: SummarizationCheckerProtocol = SummarizationChecker()
    ) {
        self.logger = logger
        self.windowManager = windowManager
        self.profile = profile
        self.summarizerNimbusUtils = summarizerNimbusUtility
        self.summarizationChecker = summarizationChecker
        self.summarizerServiceFactory = summarizerServiceFactory
        self.summarizerLanguageProvider = DefaultSummarizerLanguageProvider(
            appLanguageProvider: SystemLocaleProvider(),
            websiteLanguageProvider: LanguageDetector()
        )
    }

    lazy var summarizerProvider: Middleware<AppState> = { state, action in
        switch action.actionType {
        case GeneralBrowserActionType.shakeMotionEnded:
            Task { @MainActor in
                await self.dispatchSummarizeConfigurationAction(for: action)
            }
        default:
            break
        }
    }

    @MainActor
    func checkSummarizationResult(_ tab: Tab) async -> SummarizationCheckResult? {
        guard let webView = tab.webView else { return nil }
        let result = await summarizationChecker.check(on: webView, maxWords: maxWords)
        return result
    }

    private var maxWords: Int {
        summarizerServiceFactory.maxWords(
            isAppleSummarizerEnabled: summarizerNimbusUtils.isAppleSummarizerEnabled(),
            isHostedSummarizerEnabled: summarizerNimbusUtils.isHostedSummarizerEnabled()
        )
    }

    @MainActor
    private func dispatchSummarizeConfigurationAction(for action: Action) async {
        guard let webView = windowManager.tabManager(for: action.windowUUID).selectedTab?.webView else { return }
        guard let summarizerConfig = await getSummarizerConfiguration(webView) else { return }
        
        store.dispatch(
            SummarizeAction(
                windowUUID: action.windowUUID,
                actionType: SummarizeMiddlewareActionType.configuredSummarizer,
                summarizerConfig: summarizerConfig
            )
        )
    }
    
    func getSummarizerConfiguration(_ webView: WKWebView) async -> SummarizerConfig? {
        guard summarizerNimbusUtils.isSummarizeFeatureToggledOn else { return nil }
        
        let preSummarizationCheckResults = await summarizationChecker.check(on: webView, maxWords: maxWords)
        guard preSummarizationCheckResults.canSummarize else { return nil }
        
        if summarizerNimbusUtils.isLanguageExpansionEnabled {
            let langExpansionConfiguration = summarizerNimbusUtils.languageExpansionConfiguration()
            guard let summarizerLocale = await summarizerLanguageProvider.getLanguage(
                userPreference: langExpansionConfiguration.selectedPreference(
                    prefs: profile.prefs
                ),
                supportedLocales: langExpansionConfiguration.supportedLocales,
                languageSampleSource: WebViewLanguageSampleSource(webView: webView)
            ) else {
                return nil
            }
            // TODO: inject local locale config
            return SummarizerConfigManager(sources: [SummarizerConfigSourceLanguageAware()]).getConfig(
                summarizerType,
                contentType: preSummarizationCheckResults.contentType ?? .generic,
                locale: summarizerLocale
            )
        }
        if summarizerNimbusUtils.isSummarizeFeatureEnabled {
            // For previous experiments where lang is default to en we need to check just if web site language
            // is en otherwise no configuration for the summarizer can be built.
            let isSupportedLocale = await summarizerLanguageProvider.getLanguage(
                userPreference: .websiteLanguage,
                supportedLocales: [Locale(identifier: "en")],
                languageSampleSource: WebViewLanguageSampleSource(webView: webView)
            ) != nil
            guard isSupportedLocale else { return nil }
            return SummarizerConfigManager().getConfig(
                summarizerType,
                contentType: preSummarizationCheckResults.contentType ?? .generic,
            )
        }
        return nil
    }
}
