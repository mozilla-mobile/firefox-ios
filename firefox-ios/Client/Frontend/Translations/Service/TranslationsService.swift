// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import WebKit

/// Default implementation of `TranslationsServiceProtocol`
@MainActor
final class TranslationsService: TranslationsServiceProtocol {
    private let windowManager: WindowManager
    private let languageDetector: LanguageDetectorProvider
    private let modelsFetcher: TranslationModelsFetcherProtocol
    private let translationsEngine: TranslationsEngine
    private let logger: Logger

    init(
        windowManager: WindowManager = AppContainer.shared.resolve(),
        languageDetector: LanguageDetectorProvider = LanguageDetector(),
        modelsFetcher: TranslationModelsFetcherProtocol = ASTranslationModelsFetcher.shared,
        translationsEngine: TranslationsEngine = TranslationsEngine(),
        logger: Logger = DefaultLogger.shared
    ) {
        self.windowManager = windowManager
        self.languageDetector = languageDetector
        self.modelsFetcher = modelsFetcher
        self.translationsEngine = translationsEngine
        self.logger = logger
    }

    /// Determines whether translation should be offered by checking any of the given
    /// preferred target languages against the detected page language.
    /// Returns `true` if at least one preferred language has an available model pair.
    /// NOTE: `fetchModels` inspects Remote Settings metadata and returns JSON data
    /// describing the pipeline, it does not fetch large model attachments.
    func shouldOfferTranslation(for windowUUID: WindowUUID, using preferredLanguages: [String]) async throws -> Bool {
        guard !preferredLanguages.isEmpty else { return false }
        let pageLanguage = try await detectPageLanguage(for: windowUUID)
        for language in preferredLanguages {
            guard language != pageLanguage else { continue }
            if await modelsFetcher.fetchModels(from: pageLanguage, to: language) != nil {
                return true
            }
        }
        return false
    }

    /// Initiates translation of the current page to the specified target language.
    func translateCurrentPage(
        for windowUUID: WindowUUID,
        to targetLanguage: String,
        onLanguageIdentified: ((String, String) -> Void)?
    ) async throws {
        let pageLanguage = try await detectPageLanguage(for: windowUUID)
        onLanguageIdentified?(pageLanguage, targetLanguage)
        let webView = try currentWebView(for: windowUUID)
        // Prewarm resources prior to calling the JS translation API.
        await modelsFetcher.prewarmResources(for: pageLanguage, to: targetLanguage)
        // Create a bridge to the translations engine.
        _ = translationsEngine.bridge(to: webView)
        try await startTranslationsJS(on: webView, from: pageLanguage, to: targetLanguage)
    }

    /// Checks whether initial translation output has been produced.
    /// NOTE: This does not mean the entire page is fully translated.
    /// Translation is a living process ( e.g live chat in twitch ) so there is no single "done" state.
    /// In Gecko, we mark translations done when the engine is ready.
    /// In iOS, we will go a step further and wait for the first translation response to be received.
    func firstResponseReceived(for windowUUID: WindowUUID) async throws {
        let webView = try currentWebView(for: windowUUID)
        _ = try await firstResponseReceivedJS(on: webView)
    }

    /// Tells the engine to discard translations for a document.
    func discardTranslations(for windowUUID: WindowUUID) async throws {
        let pageLanguage = try await detectPageLanguage(for: windowUUID)
        guard let deviceLanguage = deviceLanguageCode() else {
            throw TranslationsServiceError.deviceLanguageUnavailable
        }

        let webView = try currentWebView(for: windowUUID)
        try await discardTranslationsJS(on: webView, from: pageLanguage, to: deviceLanguage)
    }

    /// Attempts to detect the language of the currently displayed page.
    /// Returns a BCP-47 language tag (e.g. "en", "fr") on success.
    /// Otherwise throws a typed `TranslationsServiceError`.
    private func detectPageLanguage(for windowUUID: WindowUUID) async throws -> String {
        let webView = try currentWebView(for: windowUUID)
        let source = WebViewLanguageSampleSource(webView: webView)
        do {
            guard let language = try await languageDetector.detectLanguage(from: source) else {
                throw TranslationsServiceError.pageLanguageDetectionFailed(description: "language_not_detected")
            }
            return language
        } catch {
            throw TranslationsServiceError.fromUnknown(error)
        }
    }

    /// Starts translations by calling into the JS bridge.
    private func startTranslationsJS(on webView: WKWebView,
                                     from: String,
                                     to: String) async throws {
        let jsArgs = "{from: \"\(from)\", to: \"\(to)\"}"
        let js = "window.__firefox__.Translations.startTranslations(\(jsArgs))"

        do {
            _ = try await webView.callAsyncJavaScript(js, contentWorld: .defaultClient)
        } catch {
            /// NOTE: It would be safe to pass in the js string directly here, but it would just add too much noise 
            /// since from and to could be any language code. We only care that startTranslationsJS failed.
            throw TranslationsServiceError.jsEvaluationFailed(reason: "JS evaluation failed: startTranslationsJS")
        }
    }

    /// Evaluates the JS hook to check whether initial translation output has been produced.
    private func firstResponseReceivedJS(on webView: WKWebView) async throws {
        let js = "return await window.__firefox__.Translations.isDone()"
        do {
            _ = try await webView.callAsyncJavaScript(js, contentWorld: .defaultClient)
        } catch {
            /// NOTE: It would be safe to pass in the js string directly here, but it would just add too much noise 
            /// since from and to could be any language code. We only care that firstResponseReceivedJS failed.
            throw TranslationsServiceError.jsEvaluationFailed(reason: "JS evaluation failed: firstResponseReceivedJS")
        }
    }

    /// Calls the JS `discardTranslations` hook.
    private func discardTranslationsJS(on webView: WKWebView, from: String, to: String) async throws {
        let jsArgs = "{from: \"\(from)\", to: \"\(to)\"}"
        let js = "window.__firefox__.Translations.discardTranslations(\(jsArgs))"

        do {
            _ = try await webView.callAsyncJavaScript(js, contentWorld: .defaultClient)
        } catch {
            /// NOTE: It would be safe to pass in the js string directly here, but it would just add too much noise
            /// since from and to could be any language code. We only care that discardTranslationsJS failed.
            throw TranslationsServiceError.jsEvaluationFailed(reason: "JS evaluation failed: discardTranslationsJS")
        }
    }

    /// Returns the current WebView for a given window, or throws if it is unavailable.
    private func currentWebView(for windowUUID: WindowUUID) throws -> WKWebView {
        guard let tab = windowManager.tabManager(for: windowUUID).selectedTab,
              let webView = tab.webView else {
            throw TranslationsServiceError.missingWebView
        }
        return webView
    }

    /// Returns the unique set of languages that can be used as translation targets.
    func fetchSupportedTargetLanguages() async -> [String] {
        return await modelsFetcher.fetchSupportedTargetLanguages()
    }

    func resetStorage() async {
        return await modelsFetcher.resetStorage()
    }

    /// Returns the device language code for a given locale, if available.
    private func deviceLanguageCode(using locale: Locale = .current) -> String? {
        return locale.languageCode
    }
}
