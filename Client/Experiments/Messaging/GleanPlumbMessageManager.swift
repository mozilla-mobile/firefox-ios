// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

import MozillaAppServices
import Shared

protocol GleanPlumbMessageManagerProtocol {
    /// Delegate protocol to open Glean message when pressed
    var pressedDelegate: GleanPlumbMessagePressedDelegate? { get set }

    /// Performs the bookkeeping and preparation of messages for their respective surfaces.
    /// We can build our collection of eligible messages for a surface in here.
    func onStartup()

    /// Finds the next message to be displayed out of all showable messages.
    /// Surface calls.
    func getNextMessage(for surface: MessageSurfaceId) -> GleanPlumbMessage?

    /// Report impressions in Glean, and then pass the bookkeeping to increment the impression count and expire to `MessageStore`.
    /// Surface calls.
    func onMessageDisplayed(_ message: GleanPlumbMessage)

    /// Using the helper, this should get the message action string ready for use.
    /// Surface calls.
    func onMessagePressed(_ message: GleanPlumbMessage)

    /// Handles what to do with a message when a user has dismissed it.
    /// Surface calls.
    func onMessageDismissed(_ message: GleanPlumbMessage)

    /// If the message is malformed (missing key elements the surface expects), then
    /// report the malformed message.
    /// Manager calls.
    func onMalformedMessage(id: String, surface: MessageSurfaceId)

    /// Finds a message for a specified id on a specified surface.
    func messageForId(_ id: String, surface: MessageSurfaceId) -> GleanPlumbMessage?
}

protocol GleanPlumbMessagePressedDelegate: AnyObject {
    func openURLInNewTab(url: URL)
}

/// To the surface that requests messages, it provides valid and triggered messages in priority order.
///
/// Note: The term "valid" in `GleanPlumbMessage` context means a well-formed, non-expired, priority ordered message.
///
/// The `GleanPlumbMessageManager` is responsible for several things including:
/// - preparing Messages for a given UI surface
/// - reporting telemetry for `GleanPlumbMessage`s:
///     - impression counts
///     - user dismissal of a message
///     - expiration logic
///     - exposure
///     - malformed message
///     - expiration (handled in the store)
class GleanPlumbMessageManager: GleanPlumbMessageManagerProtocol {
    // MARK: - Properties
    static let shared = GleanPlumbMessageManager()

    private let messagingUtility: GleanPlumbMessageUtility
    private let messagingStore: GleanPlumbMessageStoreProtocol
    private let feature = FxNimbus.shared.features.messaging.value()

    weak var pressedDelegate: GleanPlumbMessagePressedDelegate?

    typealias MessagingKey = TelemetryWrapper.EventExtraKey

    // MARK: - Inits

    init(messagingUtility: GleanPlumbMessageUtility = GleanPlumbMessageUtility(),
         messagingStore: GleanPlumbMessageStoreProtocol = GleanPlumbMessageStore()) {
        self.messagingUtility = messagingUtility
        self.messagingStore = messagingStore

        onStartup()
    }

    // MARK: - GleanPlumbMessageManagerProtocol Conformance

    /// Perform any startup setup if necessary.
    func onStartup() { }

    func hasMessage(for surface: MessageSurfaceId) -> Bool {
        return getNextMessage(for: surface) != nil
    }

    /// Returns the next valid and triggered message for the surface, if one exists.
    func getNextMessage(for surface: MessageSurfaceId) -> GleanPlumbMessage? {
        // All these are non-expired, well formed, and descending priority ordered messages for a requested surface.
        let messages = getAllValidMessagesFor(surface, with: feature)

        // If `GleanPlumbHelper` creation fails, we cannot continue with this feature! For that reason, return `nil`.
        // We need to recreate the helper for each request to get a message because device context can change.
        guard let gleanPlumbHelper = messagingUtility.createGleanPlumbHelper() else { return nil }

        // Take the first triggered message.
        guard let message = getNextTriggeredMessage(messages, gleanPlumbHelper) else { return nil }

        // If it's a message under experiment, we need to react to whether it's a control or not.
        if message.isUnderExperimentWith(key: feature.messageUnderExperiment) {
            guard let nextTriggeredMessage = handleMessageUnderExperiment(message,
                                                                          messages,
                                                                          gleanPlumbHelper,
                                                                          feature.onControl)
            else { return nil }

            return nextTriggeredMessage
        }

        return message
    }

    /// Handle impression reporting and bookkeeping.
    func onMessageDisplayed(_ message: GleanPlumbMessage) {
        messagingStore.onMessageDisplayed(message)

        let extras = baseTelemetryExtras(using: message)
        TelemetryWrapper.recordEvent(category: .information,
                                     method: .view,
                                     object: .messaging,
                                     value: .messageImpression,
                                     extras: extras)
    }

    /// Handle when a user hits the CTA of the surface, and forward the bookkeeping to the store.
    func onMessagePressed(_ message: GleanPlumbMessage) {
        messagingStore.onMessagePressed(message)

        guard let messageUtility = messagingUtility.createGleanPlumbHelper() else { return }

        // Make substitutions where they're needed.
        let template = message.action
        let uuid = messageUtility.getUuid(template: template)
        let action = messageUtility.stringFormat(template: template, uuid: uuid)

        // Create the message action URL.
        let urlString = action.hasPrefix("://") ? URL.mozInternalScheme + action : action
        guard let url = URL(string: urlString) else {
            self.onMalformedMessage(id: message.id, surface: message.data.surface)
            return
        }

        // With our well-formed URL, we can handle the action here.
        if url.isWebPage() {
            pressedDelegate?.openURLInNewTab(url: url)
        } else {
            UIApplication.shared.open(url, options: [:])
        }

        var extras = baseTelemetryExtras(using: message)
        extras[MessagingKey.actionUUID.rawValue] = uuid ?? "nil"
        TelemetryWrapper.recordEvent(category: .action,
                                     method: .tap,
                                     object: .messaging,
                                     value: .messageInteracted,
                                     extras: extras)
    }

    /// For now, we will assume all dismissed messages should become expired right away. The
    /// store handles this bookkeeping.
    func onMessageDismissed(_ message: GleanPlumbMessage) {
        messagingStore.onMessageDismissed(message)

        let extras = baseTelemetryExtras(using: message)
        TelemetryWrapper.recordEvent(category: .action,
                                     method: .tap,
                                     object: .messaging,
                                     value: .messageDismissed,
                                     extras: extras)
    }

    func onMalformedMessage(id: String, surface: MessageSurfaceId) {
        TelemetryWrapper.recordEvent(
            category: .information,
            method: .application,
            object: .messaging,
            value: .messageMalformed,
            extras: [
                MessagingKey.messageKey.rawValue: id,
                MessagingKey.messageSurface.rawValue: surface.rawValue,
            ]
        )
    }

    /// Finds a message for a specified id on a specified surface.
    /// - Parameters:
    ///   - id: the id of the message.
    ///   - surface: the surface the message should be disaplayed on.
    /// - Returns: the message if existent, otherwise nil.
    func messageForId(_ id: String, surface: MessageSurfaceId) -> GleanPlumbMessage? {
        let messageData = feature.messages.first { key, messageData in
            return key == id && messageData.surface == surface
        }

        guard let messageData = messageData,
              let message = self.createMessage(messageId: messageData.key,
                                               message: messageData.value,
                                               lookupTables: feature)
        else { return nil }

        return message
    }

    // MARK: - Misc. Private helpers

    /// - Returns: All well-formed, non-expired messages for a surface in descending priority order for a specified surface.
    private func getAllValidMessagesFor(
        _ surface: MessageSurfaceId,
        with feature: Messaging
    ) -> [GleanPlumbMessage] {
        // All these are non-expired, well formed, and descending priority messages for a requested surface.
        let messages = feature.messages.compactMap { key, messageData -> GleanPlumbMessage? in
            guard let message = self.createMessage(messageId: key,
                                                   message: messageData,
                                                   lookupTables: feature)
            else {
                onMalformedMessage(id: key, surface: messageData.surface)
                return nil
            }

            return message
        }.filter { message in
            !message.isExpired
        }.filter { message in
            message.data.surface == surface
        }.sorted { message1, message2 in
            message1.style.priority > message2.style.priority
        }

        return messages
    }

    /// We assemble one message at a time. If there's any issue with it, return `nil`.
    /// Reporting a malformed message is done at the call site when reacting to a `nil`.
    private func createMessage(
        messageId: String,
        message: MessageData,
        lookupTables: Messaging
    ) -> GleanPlumbMessage? {
        // Guard against a message with a blank `text` property.
        guard !message.text.isEmpty else { return nil }

        // Ascertain a Message's style, to know priority and max impressions.
        guard let style = lookupTables.styles[message.style] else { return nil }

        // The message action should be either from the lookup table OR a URL.
        let action = lookupTables.actions[message.action] ?? message.action
        guard action.contains("://") else { return nil }

        let triggers = message.trigger.compactMap { trigger in
            lookupTables.triggers[trigger]
        }

        // Be sure the count on `triggers` and `message.triggers` are equal.
        // If these mismatch, that means a message contains a trigger not in the triggers lookup table.
        // JEXLS can only be evaluated on supported triggers. Otherwise, consider the message malformed.
        if triggers.count != message.trigger.count {
            return nil
        }

        let messageMetadata = messagingStore.getMessageMetadata(messageId: messageId)
        if messageMetadata.impressions >= style.maxDisplayCount || messageMetadata.isExpired {
            _ = messagingStore.onMessageExpired(
                messageMetadata,
                surface: message.surface,
                shouldReport: true)
            return nil
        }

        return GleanPlumbMessage(id: messageId,
                                 data: message,
                                 action: action,
                                 triggers: triggers,
                                 style: style,
                                 metadata: messageMetadata)
    }

    /// From the list of messages that are well-formed and non-expired, we return the next / first triggered message.
    ///
    /// - Returns: The next triggered message, if one exists.
    private func getNextTriggeredMessage(_ messages: [GleanPlumbMessage], _ helper: GleanPlumbMessageHelper) -> GleanPlumbMessage? {
        messages.first( where: { message in
            do {
                return try messagingUtility.isMessageEligible(message, messageHelper: helper)
            } catch {
                return false
            }
        })
    }

    /// If a message is under experiment, we need to handle it a certain way.
    ///
    /// First, messages under experiment should always report exposure.
    ///
    /// Second, for messages under experiment, there's a chance we may encounter a "control message." If a message
    /// under experiment IS a control message, we're told how the surface should handle it.
    ///
    /// How we handle a control message is provided by `nimbus.fml.yaml`.
    ///
    /// The only two options are:
    /// - showNextMessage
    /// - showNone
    ///
    /// - Returns: The next triggered message, if one exists.
    private func handleMessageUnderExperiment(_ message: GleanPlumbMessage,
                                              _ messages: [GleanPlumbMessage],
                                              _ helper: GleanPlumbMessageHelper,
                                              _ onControl: ControlMessageBehavior) -> GleanPlumbMessage? {
        FxNimbus.shared.features.messaging.recordExposure()
        let onControlActions = onControl

        if !message.data.isControl {
            return message
        }
        switch onControlActions {
        case .showNone:
            return nil
        case .showNextMessage:
            return messages.first { message in
                do {
                    return try messagingUtility.isMessageEligible(message, messageHelper: helper)
                    && !message.data.isControl
                } catch {
                    onMalformedMessage(id: message.id, surface: message.data.surface)
                    return false
                }
            }
        }
    }

    private func baseTelemetryExtras(using message: GleanPlumbMessage) -> [String: String] {
        return [MessagingKey.messageKey.rawValue: message.id,
                MessagingKey.messageSurface.rawValue: message.data.surface.rawValue]
    }
}
