// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import Shared
import Glean

enum TranslateButtonActionType: String {
    case willTranslate = "will_translate"
    case willRestore = "will_restore"
}

protocol TranslationsTelemetryProtocol {
    func pageLanguageIdentified(identifiedLanguage: String, deviceLanguage: String)
    func pageLanguageIdentificationFailed(errorType: String)
    func translationFailed(translationFlowId: UUID, errorType: String)
    func webpageRestored(translationFlowId: UUID)
    func translateButtonTapped(isPrivate: Bool, actionType: TranslateButtonActionType, translationFlowId: UUID)
}

final class TranslationsTelemetry: TranslationsTelemetryProtocol {
    private let gleanWrapper: GleanWrapper

    init(gleanWrapper: GleanWrapper = DefaultGleanWrapper()) {
        self.gleanWrapper = gleanWrapper
    }

    func pageLanguageIdentified(identifiedLanguage: String, deviceLanguage: String) {
        let extras = GleanMetrics.Translations.PageLanguageIdentifiedExtra(
            deviceLanguage: deviceLanguage,
            identifiedLanguage: identifiedLanguage
        )
        gleanWrapper.recordEvent(
            for: GleanMetrics.Translations.pageLanguageIdentified,
            extras: extras
        )
    }

    func pageLanguageIdentificationFailed(errorType: String) {
        let extras = GleanMetrics.Translations.PageLanguageIdentificationFailedExtra(
            errorType: errorType
        )
        gleanWrapper.recordEvent(
            for: GleanMetrics.Translations.pageLanguageIdentificationFailed,
            extras: extras
        )
    }

    func translationFailed(translationFlowId: UUID, errorType: String) {
        let extras = GleanMetrics.Translations.TranslationFailedExtra(
            errorType: errorType,
            translationFlowId: translationFlowId.uuidString
        )
        gleanWrapper.recordEvent(
            for: GleanMetrics.Translations.translationFailed,
            extras: extras
        )
    }

    func webpageRestored(translationFlowId: UUID) {
        let extras = GleanMetrics.Translations.WebpageRestoredExtra(
            translationFlowId: translationFlowId.uuidString
        )
        gleanWrapper.recordEvent(
            for: GleanMetrics.Translations.webpageRestored,
            extras: extras
        )
    }

    func translateButtonTapped(isPrivate: Bool, actionType: TranslateButtonActionType, translationFlowId: UUID) {
        let extras = GleanMetrics.Toolbar.TranslateButtonTappedExtra(
            actionType: actionType.rawValue,
            isPrivate: isPrivate,
            translationFlowId: translationFlowId.uuidString
        )
        gleanWrapper.recordEvent(
            for: GleanMetrics.Toolbar.translateButtonTapped,
            extras: extras
        )
    }
}
