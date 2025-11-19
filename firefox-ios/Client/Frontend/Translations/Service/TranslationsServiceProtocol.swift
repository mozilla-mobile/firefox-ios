// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common

/// A service responsible for coordinating in-page translations.
@MainActor
protocol TranslationsServiceProtocol {
    /// Determines whether translation should be offered to the user based on
    /// the detected page language and the device's current locale.
    func shouldOfferTranslation(for windowUUID: WindowUUID) async throws -> Bool
    /// Performs translation and returns immediately.
    func translateCurrentPage(for windowUUID: WindowUUID) async throws
    /// This method resolves when translations is done.
    /// NOTE: Translation is a living process ( e.g live chat in twitch ) so there is no single "done" state.
    /// In Gecko, we mark translations done when the engine is ready.
    /// In iOS, we will go a step further and wait for the first translation response to be received.
    func isTranslationsDone(for windowUUID: WindowUUID) async throws -> Bool
    /// Asks the engine to discard translations and tear down state for the current document.
    func discardTranslations(for windowUUID: WindowUUID) async throws
}
