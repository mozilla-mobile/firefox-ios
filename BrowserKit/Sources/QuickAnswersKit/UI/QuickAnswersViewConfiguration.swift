// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public struct QuickAnswersViewConfiguration: Sendable {
    public let optIn: OptInStrings
    public let contentView: ContentViewStrings
    public let errors: ErrorStrings
    public let closeAccessibilityLabel: String
    public let appName: String

    public struct OptInStrings: Sendable {
        public let title: String
        public let description: String
        public let learnMore: String
        public let continueButton: String

        public init(title: String, description: String, learnMore: String, continueButton: String) {
            self.title = title
            self.description = description
            self.learnMore = learnMore
            self.continueButton = continueButton
        }
    }

    public struct ContentViewStrings: Sendable {
        public let placeholder: String
        public let answering: String
        public let footerFormat: String
        public let sources: String

        public init(placeholder: String, answering: String, footerFormat: String, sources: String) {
            self.placeholder = placeholder
            self.answering = answering
            self.footerFormat = footerFormat
            self.sources = sources
        }
    }

    public struct ErrorStrings: Sendable {
        public let permissionAlertTitle: String
        public let microphonePermissionMessage: String
        public let speechRecognitionPermissionMessage: String
        public let openSettings: String
        public let cancel: String
        public let dailyLimitTitle: String
        public let dailyLimitMessage: String
        public let genericErrorTitle: String
        public let genericErrorMessage: String
        public let ok: String

        public init(
            permissionAlertTitle: String,
            microphonePermissionMessage: String,
            speechRecognitionPermissionMessage: String,
            openSettings: String,
            cancel: String,
            dailyLimitTitle: String,
            dailyLimitMessage: String,
            genericErrorTitle: String,
            genericErrorMessage: String,
            ok: String
        ) {
            self.permissionAlertTitle = permissionAlertTitle
            self.microphonePermissionMessage = microphonePermissionMessage
            self.speechRecognitionPermissionMessage = speechRecognitionPermissionMessage
            self.openSettings = openSettings
            self.cancel = cancel
            self.dailyLimitTitle = dailyLimitTitle
            self.dailyLimitMessage = dailyLimitMessage
            self.genericErrorTitle = genericErrorTitle
            self.genericErrorMessage = genericErrorMessage
            self.ok = ok
        }
    }

    public init(
        optIn: OptInStrings,
        contentView: ContentViewStrings,
        errors: ErrorStrings,
        closeAccessibilityLabel: String,
        appName: String
    ) {
        self.optIn = optIn
        self.contentView = contentView
        self.errors = errors
        self.closeAccessibilityLabel = closeAccessibilityLabel
        self.appName = appName
    }
}
