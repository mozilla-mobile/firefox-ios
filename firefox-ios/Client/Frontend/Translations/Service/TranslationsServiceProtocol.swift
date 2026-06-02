// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common

/// Snapshot of the displayed document's translation state as reported by the in-page engine.
/// Modeled as an enum so the source/target languages only exist when the page is actually
/// translated — illegal combinations like "translated with no languages" are unrepresentable.
enum PageTranslationState: Equatable, Sendable {
    case notTranslated
    case translated(from: String, to: String)
}

/// A service responsible for coordinating in-page translations.
@MainActor
protocol TranslationsServiceProtocol {
    /// Determines whether translation should be offered by checking the detected page language
    /// against the given preferred target languages. Returns `true` if:
    /// - The page language is already one of the user's preferred languages and there is at
    ///   least one other preferred language to translate to (language-picker flow), OR
    /// - The page language is not in the preferred list and at least one preferred language
    ///   has an available model pair.
    func shouldOfferTranslation(for windowUUID: WindowUUID, using preferredLanguages: [String]) async throws -> Bool
    /// Performs translation and returns immediately.
    /// TODO(FXIOS-14213): We should implement a lifecycle for the service similar to `SummarizerServiceLifecycle`.
    /// For now `onLanguageIdentified` is used to notify caller when language detection is done.
    func translateCurrentPage(
        for windowUUID: WindowUUID,
        from sourceLanguage: String?,
        to targetLanguage: String,
        onLanguageIdentified: ((String, String) -> Void)?
    ) async throws
    /// This method resolves when the document receives the first translations response.
    /// NOTE: Translation is a living process ( e.g live chat in twitch ) so there is no single "done" state.
    /// In Gecko, we mark translations done when the engine is ready.
    /// In iOS, we will go a step further and wait for the first translation response to be received.
    func firstResponseReceived(for windowUUID: WindowUUID) async throws
    /// Asks the engine to discard translations and tear down state for the current document.
    func discardTranslations(for windowUUID: WindowUUID) async throws
    /// Returns the unique set of languages that can be used as translation targets.
    func fetchSupportedTargetLanguages() async -> [String]
    /// Returns the BCP-47 language code of the currently displayed page (e.g. "ja", "en").
    func detectPageLanguage(for windowUUID: WindowUUID) async throws -> String
    /// Returns the in-page engine's ground-truth translation state for the currently displayed
    /// document. Survives back/forward cache restores and resets on a fresh load, so it is the
    /// authoritative source for deriving the toolbar translation state on navigation.
    func currentTranslationState(for windowUUID: WindowUUID) async throws -> PageTranslationState
}
