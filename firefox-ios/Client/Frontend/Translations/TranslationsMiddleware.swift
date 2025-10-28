// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Redux
import Common

@MainActor
final class TranslationsMiddleware {
    private let windowManager: WindowManager
    init(windowManager: WindowManager = AppContainer.shared.resolve()) {
        self.windowManager = windowManager
    }

    lazy var translationsProvider: Middleware<AppState> = { state, action in
        let windowUUID = action.windowUUID
        switch action.actionType {
        case ToolbarMiddlewareActionType.urlDidChange:
            guard let action = (action as? ToolbarMiddlewareAction) else { return }
            self.checkTranslations(for: action)

        case ToolbarMiddlewareActionType.didTapButton:
            guard let action = (action as? ToolbarMiddlewareAction) else { return }
            guard let gestureType = action.gestureType,
                  let type = action.buttonType else { return }
            guard gestureType == .tap,
                  type == .translate else { return }

            guard let selectedTab = self.windowManager.tabManager(for: action.windowUUID).selectedTab,
                    let webView = selectedTab.webView
            else { return }
            if action.buttonImage == StandardImageIdentifiers.Medium.translateActive {
                self.discardTranslations(for: action)
                webView.reload()
            } else {
                self.startTranslation(for: action)
            }
            break

        default:
           break
        }
    }

    private func checkTranslations(for action: ToolbarMiddlewareAction) {
        Task { @MainActor in
            guard let selectedTab = self.windowManager.tabManager(for: action.windowUUID).selectedTab else { return }
            let pageLanguage = await self.checkTranslations(selectedTab)
            let shouldTranslate = pageLanguage != Locale.current.languageCode
            let toolbarAction = ToolbarAction(
                translationConfiguration: TranslationConfiguration(
                    isTranslateActive: false,
                    isLoading: false,
                    pageLanguage: shouldTranslate ? pageLanguage : nil
                ),
                windowUUID: action.windowUUID,
                actionType: ToolbarActionType.receivedTranslationLanguage
            )
            store.dispatch(toolbarAction)
        }
    }

    private func startTranslation(for action: ToolbarMiddlewareAction) {
        Task { @MainActor in
            guard let selectedTab = self.windowManager.tabManager(for: action.windowUUID).selectedTab,
                    let webView = selectedTab.webView
            else { return }
            guard let deviceLanguage = Locale.current.languageCode else { return }
            guard let pageLanguage = await self.checkTranslations(selectedTab) else { return }
            TranslationsEngine.shared.bridge(to: webView)
            /// TODO(Issam): `window.__firefox__.Translations` can be a namespace constant
            let jsCallArgs = """
            {from: "\(pageLanguage)", to: "\(deviceLanguage)"}
            """
            webView.evaluateJavascriptInDefaultContentWorld("window.__firefox__.Translations.startEverything(\(jsCallArgs))")
            try? await LanguageDetector.isDone(from: webView)
            let toolbarAction = ToolbarAction(
                translationConfiguration: TranslationConfiguration(
                    isTranslateActive: true,
                    isLoading: false,
                    pageLanguage: pageLanguage
                ),
                windowUUID: action.windowUUID,
                actionType: ToolbarActionType.translationCompleted
            )
            store.dispatch(toolbarAction)
        }
    }

    private func discardTranslations(for action: ToolbarMiddlewareAction) {
        Task { @MainActor in
            guard let selectedTab = self.windowManager.tabManager(for: action.windowUUID).selectedTab,
                    let webView = selectedTab.webView
            else { return }
            webView.evaluateJavascriptInDefaultContentWorld("window.__firefox__.Translations.discardTranslations()")
        }
    }

    @MainActor
    func checkTranslations(_ tab: Tab) async -> String? {
        guard let webView = tab.webView else { return nil }
        do {
            let sample = try await LanguageDetector.extractSample(from: webView)
            guard let textSample = sample else { return nil }
            return LanguageDetector.detectLanguage(of: textSample)
        } catch {
            print("[dbg][issam]Translations language sample error: \(error)")
            return nil
        }
    }
}
