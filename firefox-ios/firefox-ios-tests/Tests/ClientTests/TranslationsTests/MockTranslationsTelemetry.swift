// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
@testable import Client

final class MockTranslationsTelemetry: TranslationsTelemetryProtocol {
    var pageLanguageIdentifiedCalledCount = 0
    var pageLanguageIdentificationFailedCalledCount = 0
    var translationRequestedCalledCount = 0
    var translationFailedCalledCount = 0
    var webpageRestoredCalledCount = 0
    var translateButtonTappedCalledCount = 0

    var lastIdentifiedLanguage: String?
    var lastDeviceLanguage: String?
    var lastErrorType: String?
    var lastTranslationFlowId: UUID?
    var lastIsPrivate: Bool?
    var lastActionType: TranslateButtonActionType?
    var lastFromLanguage: String?
    var lastToLanguage: String?
    var lastAutoTranslate: Bool?

    func pageLanguageIdentified(identifiedLanguage: String, deviceLanguage: String) {
        pageLanguageIdentifiedCalledCount += 1
        lastIdentifiedLanguage = identifiedLanguage
        lastDeviceLanguage = deviceLanguage
    }

    func pageLanguageIdentificationFailed(errorType: String) {
        pageLanguageIdentificationFailedCalledCount += 1
        lastErrorType = errorType
    }

    func translationRequested(
        isPrivate: Bool,
        translationFlowId: UUID,
        fromLanguage: String,
        toLanguage: String,
        autoTranslate: Bool
    ) {
        translationRequestedCalledCount += 1
        lastIsPrivate = isPrivate
        lastTranslationFlowId = translationFlowId
        lastFromLanguage = fromLanguage
        lastToLanguage = toLanguage
        lastAutoTranslate = autoTranslate
    }

    func translationFailed(translationFlowId: UUID, errorType: String) {
        translationFailedCalledCount += 1
        lastTranslationFlowId = translationFlowId
        lastErrorType = errorType
    }

    func webpageRestored(translationFlowId: UUID) {
        webpageRestoredCalledCount += 1
        lastTranslationFlowId = translationFlowId
    }

    func translateButtonTapped(
        isPrivate: Bool,
        actionType: TranslateButtonActionType,
        translationFlowId: UUID
    ) {
        translateButtonTappedCalledCount += 1
        lastIsPrivate = isPrivate
        lastActionType = actionType
        lastTranslationFlowId = translationFlowId
    }

    func reset() {
        pageLanguageIdentifiedCalledCount = 0
        pageLanguageIdentificationFailedCalledCount = 0
        translationRequestedCalledCount = 0
        translationFailedCalledCount = 0
        webpageRestoredCalledCount = 0
        translateButtonTappedCalledCount = 0
        lastIdentifiedLanguage = nil
        lastDeviceLanguage = nil
        lastErrorType = nil
        lastTranslationFlowId = nil
        lastIsPrivate = nil
        lastActionType = nil
        lastFromLanguage = nil
        lastToLanguage = nil
        lastAutoTranslate = nil
    }
}
