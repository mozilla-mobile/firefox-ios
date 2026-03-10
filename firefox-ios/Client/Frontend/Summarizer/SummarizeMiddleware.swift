// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux
import SummarizeKit

@MainActor
final class SummarizerMiddleware {
    private let summarizerNimbusUtils: SummarizerNimbusUtils
    private let summarizationChecker: SummarizationCheckerProtocol
    private let summarizerServiceFactory: SummarizerServiceFactory
    private let logger: Logger
    private let windowManager: WindowManager

    init(
        logger: Logger = DefaultLogger.shared,
        windowManager: WindowManager = AppContainer.shared.resolve(),
        summarizerNimbusUtility: SummarizerNimbusUtils = DefaultSummarizerNimbusUtils(),
        summarizerServiceFactory: SummarizerServiceFactory = DefaultSummarizerServiceFactory(),
        summarizationChecker: SummarizationCheckerProtocol = SummarizationChecker()
    ) {
        self.logger = logger
        self.windowManager = windowManager
        self.summarizerNimbusUtils = summarizerNimbusUtility
        self.summarizationChecker = summarizationChecker
        self.summarizerServiceFactory = summarizerServiceFactory
    }

    lazy var summarizerProvider: Middleware<AppState> = { state, action in
        switch action.actionType {
        case GeneralBrowserActionType.didTapReaderModeBarSummarizerButton:
            Task { @MainActor in
                await self.dispatchSummarizeConfigurationAction(
                    for: action,
                    actionType: SummarizeMiddlewareActionType.configuredSummarizerForTapOnReaderModeButton
                )
            }
        case ToolbarActionType.didSummarizeSettingsChange:
            guard let action = action as? ToolbarAction else { return }
            guard action.canSummarize else {
                self.dispatchSummarizerNotAvailable(for: action)
                return
            }
            Task { @MainActor in
                await self.dispatchSummarizeConfigurationAction(
                    for: action,
                    actionType: SummarizeMiddlewareActionType.configuredSummarizerForReaderModeButton
                )
            }
        case GeneralBrowserActionType.showReaderMode:
            Task { @MainActor in
                await self.dispatchSummarizeConfigurationAction(
                    for: action,
                    actionType: SummarizeMiddlewareActionType.configuredSummarizerForReaderModeButton
                )
            }
        case GeneralBrowserActionType.shakeMotionEnded:
            Task { @MainActor in
                await self.dispatchSummarizeConfigurationAction(
                    for: action,
                    actionType: SummarizeMiddlewareActionType.configuredSummarizerForShakeMotion
                )
            }
        default:
            break
        }
    }

    func getConfig(for contentType: SummarizationContentType) -> SummarizerConfig {
        let summarizerType: SummarizerModel =
            summarizerNimbusUtils.isAppleSummarizerEnabled()
                ? .appleSummarizer
                : .liteLLMSummarizer
        return SummarizerConfigManager().getConfig(summarizerType, contentType: contentType)
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
    private func dispatchSummarizeConfigurationAction(for action: Action, actionType: ActionType) async {
        guard let tab = windowManager.tabManager(for: action.windowUUID).selectedTab else {
            dispatchSummarizerNotAvailable(for: action)
            return
        }
        let result = await checkSummarizationResult(tab)
        let contentType = result?.contentType ?? .generic
        guard result?.canSummarize == true else {
            dispatchSummarizerNotAvailable(for: action)
            return
        }
        store.dispatch(
            SummarizeAction(
                windowUUID: action.windowUUID,
                actionType: actionType,
                summarizerConfig: getConfig(for: contentType)
            )
        )
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





//case GeneralBrowserActionType.didTapReaderModeBarSummarizerButton:
//case ToolbarActionType.didSummarizeSettingsChange:
//case GeneralBrowserActionType.showReaderMode:
//case GeneralBrowserActionType.shakeMotionEnded:
