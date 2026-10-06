// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Testing

@testable import QuickAnswersKit

@Suite
struct QuickAnswersViewConfigurationTests {
    @Test
    func testOptInStrings_storesValues() {
        let subject = QuickAnswersViewConfiguration.OptInStrings(
            title: "title",
            description: "desc",
            learnMore: "learn",
            continueButton: "go"
        )

        #expect(subject.title == "title")
        #expect(subject.description == "desc")
        #expect(subject.learnMore == "learn")
        #expect(subject.continueButton == "go")
    }

    @Test
    func testContentViewStrings_storesValues() {
        let subject = QuickAnswersViewConfiguration.ContentViewStrings(
            placeholder: "ask",
            answering: "loading",
            footerFormat: "Powered by %@",
            sources: "Sources"
        )

        #expect(subject.placeholder == "ask")
        #expect(subject.answering == "loading")
        #expect(subject.footerFormat == "Powered by %@")
        #expect(subject.sources == "Sources")
    }

    @Test
    func testErrorStrings_storesValues() {
        let subject = QuickAnswersViewConfiguration.ErrorStrings(
            permissionAlertTitle: "perm",
            microphonePermissionMessage: "mic",
            speechRecognitionPermissionMessage: "speech",
            openSettings: "settings",
            cancel: "cancel",
            dailyLimitTitle: "limit",
            dailyLimitMessage: "limitMsg",
            genericErrorTitle: "error",
            genericErrorMessage: "errorMsg",
            ok: "ok"
        )

        #expect(subject.permissionAlertTitle == "perm")
        #expect(subject.microphonePermissionMessage == "mic")
        #expect(subject.speechRecognitionPermissionMessage == "speech")
        #expect(subject.openSettings == "settings")
        #expect(subject.cancel == "cancel")
        #expect(subject.dailyLimitTitle == "limit")
        #expect(subject.dailyLimitMessage == "limitMsg")
        #expect(subject.genericErrorTitle == "error")
        #expect(subject.genericErrorMessage == "errorMsg")
        #expect(subject.ok == "ok")
    }

    @Test
    func testConfiguration_storesAllSections() {
        let subject = QuickAnswersViewConfiguration(
            optIn: .init(title: "t", description: "d", learnMore: "l", continueButton: "c"),
            contentView: .init(placeholder: "p", answering: "a", footerFormat: "f", sources: "s"),
            errors: .init(
                permissionAlertTitle: "",
                microphonePermissionMessage: "",
                speechRecognitionPermissionMessage: "",
                openSettings: "",
                cancel: "",
                dailyLimitTitle: "",
                dailyLimitMessage: "",
                genericErrorTitle: "",
                genericErrorMessage: "",
                ok: ""
            ),
            closeAccessibilityLabel: "close",
            appName: "Firefox"
        )

        #expect(subject.optIn.title == "t")
        #expect(subject.contentView.placeholder == "p")
        #expect(subject.closeAccessibilityLabel == "close")
        #expect(subject.appName == "Firefox")
    }
}
