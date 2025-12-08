// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client
import Common

class MockGleanPlumbMessageManagerProtocol: GleanPlumbMessageManagerProtocol, @unchecked Sendable {
    func onStartup() {}

    var message: GleanPlumbMessage?
    var recordedSurface: MessageSurfaceId?
    func getNextMessage(for surface: MessageSurfaceId) -> GleanPlumbMessage? {
        recordedSurface = surface
        if message?.surface == recordedSurface { return message }

        return nil
    }

    var onMessageDisplayedCalled = 0
    func onMessageDisplayed(_ message: GleanPlumbMessage) {
        onMessageDisplayedCalled += 1
    }

    var onMessagePressedCalled = 0
    func onMessagePressed(_ message: GleanPlumbMessage, window: WindowUUID?, shouldExpire: Bool) {
        onMessagePressedCalled += 1
    }

    var onMessageDismissedCalled = 0
    func onMessageDismissed(_ message: GleanPlumbMessage) {
        onMessageDismissedCalled += 1
    }

    func onMalformedMessage(id: String, surface: MessageSurfaceId) {}

    func messageForId(_ id: String) -> Client.GleanPlumbMessage? {
        if message?.id == id { return message }

        return nil
    }
}

// MARK: - MockStyleDataProtocol
class MockStyleDataProtocol: StyleDataProtocol {
    var priority = 0
    var maxDisplayCount = 3
}

// MARK: - MockMessageDataProtocol
class MockMessageDataProtocol: MessageDataProtocol {
    var surface: MessageSurfaceId = .newTabCard
    var isControl = true
    var title: String? = "Test"
    var text = "This is a test"
    var buttonLabel: String? = "This is a test button label"
    var experiment: String?
    var actionParams: [String: String] = [:]
    var microsurveyConfig: MicrosurveyConfig?
}
