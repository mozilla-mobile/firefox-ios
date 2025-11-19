// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import WebKit

/// Errors thrown by `TranslationsService` when preconditions or WebView state are invalid.
enum TranslationsServiceError: Error, Equatable {
    case missingWebView
    case missingSourceLanguage
    case missingDeviceLanguage
    case jsEvaluationFailed(reason: String)
}

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
        modelsFetcher: TranslationModelsFetcherProtocol = ASTranslationModelsFetcher(),
        translationsEngine: TranslationsEngine = TranslationsEngine(),
        logger: Logger = DefaultLogger.shared
    ) {
        self.windowManager = windowManager
        self.languageDetector = languageDetector
        self.modelsFetcher = modelsFetcher
        self.translationsEngine = translationsEngine
        self.logger = logger
    }

    /// Determines whether translation should be offered to the user based on
    /// the detected page language and the device locale.
    func shouldOfferTranslation(for windowUUID: WindowUUID) async throws -> Bool {
        // Do not offer translations if device language is not accessible.
        guard let deviceLanguage = deviceLanguageCode() else { return false }
        // Do not offer translations if we cannot detect the page language.
        guard let pageLanguage = try await detectPageLanguage(for: windowUUID) else { return false }
        // Do not offer translations if device language is the same as detected page language.
        guard pageLanguage != deviceLanguage else { return false }
        // Only offer translation if we have a model pair (direct or via pivot).
        // NOTE: `fetchModels` inspects Remote Settings metadata and returns JSON data
        // describing the pipeline, it does not fetch large model attachments.
        guard modelsFetcher.fetchModels(from: pageLanguage, to: deviceLanguage) != nil else { return false }
        return true
    }

    /// Initiates translation of the current page.
    func translateCurrentPage(for windowUUID: WindowUUID) async throws {
        // This shouldn't happen since `shouldOfferTranslation` is called first.
        // This is just a safeguard.
        guard let pageLanguage = try await detectPageLanguage(for: windowUUID) else {
            throw TranslationsServiceError.missingSourceLanguage
        }
        // This shouldn't happen since `shouldOfferTranslation` is called first.
        // This is just a safeguard.
        guard let deviceLanguage = deviceLanguageCode() else {
            throw TranslationsServiceError.missingDeviceLanguage
        }
        let webView = try currentWebView(for: windowUUID)
        // Prewarm resources prior to calling the JS translation API.
        modelsFetcher.prewarmResources(for: pageLanguage, to: deviceLanguage)
        // Create a bridge to the translations engine.
        _ = translationsEngine.bridge(to: webView)
        try await startTranslationsJS(on: webView, from: pageLanguage, to: deviceLanguage)
    }

    /// Checks whether initial translation output has been produced.
    /// NOTE: This does not mean the entire page is fully translated.
    /// Translation is a living process ( e.g live chat in twitch ) so there is no single "done" state.
    /// In Gecko, we mark translations done when the engine is ready.
    /// In iOS, we will go a step further and wait for the first translation response to be received.
    func isTranslationsDone(for windowUUID: WindowUUID) async throws -> Bool {
        let webView = try currentWebView(for: windowUUID)
        return try await isTranslationsDoneJS(on: webView)
    }

    /// Tells the engine to discard translations for a document.
    func discardTranslations(for windowUUID: WindowUUID) async throws {
        guard let pageLanguage = try await detectPageLanguage(for: windowUUID) else {
            throw TranslationsServiceError.missingSourceLanguage
        }

        guard let deviceLanguage = deviceLanguageCode() else {
            throw TranslationsServiceError.missingDeviceLanguage
        }

        let webView = try currentWebView(for: windowUUID)
        try await discardTranslationsJS(on: webView, from: pageLanguage, to: deviceLanguage)
    }

    /// Attempts to detect the language of the currently displayed page.
    private func detectPageLanguage(for windowUUID: WindowUUID) async throws -> String? {
        let webView = try currentWebView(for: windowUUID)
        let source = WebViewLanguageSampleSource(webView: webView)
        let language = try await languageDetector.detectLanguage(from: source)
        return language
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
            throw TranslationsServiceError.jsEvaluationFailed(reason: "JS evaluation failed: \(js)")
        }
    }

    /// Evaluates the JS `isDone()` hook to check whether initial translation output has been produced.
    private func isTranslationsDoneJS(on webView: WKWebView) async throws -> Bool {
        let js = "return await window.__firefox__.Translations.isDone()"
        do {
            let result = try await webView.callAsyncJavaScript(js, contentWorld: .defaultClient)
            return (result as? Bool) ?? false
        } catch {
            throw TranslationsServiceError.jsEvaluationFailed(reason: "JS evaluation failed: \(js)")
        }
    }

    /// Calls the JS `discardTranslations` hook.
    private func discardTranslationsJS(on webView: WKWebView, from: String, to: String) async throws {
        let jsArgs = "{from: \"\(from)\", to: \"\(to)\"}"
        let js = "window.__firefox__.Translations.discardTranslations(\(jsArgs))"

        do {
            _ = try await webView.callAsyncJavaScript(js, contentWorld: .defaultClient)
        } catch {
            throw TranslationsServiceError.jsEvaluationFailed(reason: "JS evaluation failed: \(js)")
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

    /// Returns the device language code for a given locale, if available.
    private func deviceLanguageCode(using locale: Locale = .current) -> String? {
        return locale.languageCode
    }
}
