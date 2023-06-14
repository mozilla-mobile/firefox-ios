// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

import MozillaAppServices
import Shared

protocol GleanPlumbMessageManagerProtocol {
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
    func messageForId(_ id: String) -> GleanPlumbMessage?
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

    private let helperUtility: NimbusMessagingHelperUtilityProtocol
    private let evaluationUtility: NimbusMessagingEvaluationUtility
    private let messagingStore: GleanPlumbMessageStoreProtocol
    private let messagingFeature = FxNimbus.shared.features.messaging
    private let applicationHelper: ApplicationHelper

    typealias MessagingKey = TelemetryWrapper.EventExtraKey

    private enum CreateMessageError: Error {
        case expired
        case malformed
    }

    // MARK: - Inits

    init(
        helperUtility: NimbusMessagingHelperUtilityProtocol = NimbusMessagingHelperUtility(),
        messagingUtility: NimbusMessagingEvaluationUtility = NimbusMessagingEvaluationUtility(),
        messagingStore: GleanPlumbMessageStoreProtocol = GleanPlumbMessageStore(),
        applicationHelper: ApplicationHelper = DefaultApplicationHelper()
    ) {
        self.helperUtility = helperUtility
        self.evaluationUtility = messagingUtility
        self.messagingStore = messagingStore
        self.applicationHelper = applicationHelper

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
        let feature = messagingFeature.value()
        let messages = getMessages(feature)
            .filter {
                $0.data.surface == surface
            }

        // If `NimbusMessagingHelper` creation fails, we cannot continue with this
        // feature! For that reason, return `nil`. We need to recreate the helper
        // for each request to get a message because device context can change.
        guard let messagingHelper = helperUtility.createNimbusMessagingHelper() else { return nil }

        // Take the first triggered message.
        guard let message = getNextTriggeredMessage(messages, messagingHelper) else { return nil }

        // If it's a message under experiment, we need to react to whether it's a control or not.
        if message.isUnderExperimentWith(key: feature.messageUnderExperiment) {
            guard let nextTriggeredMessage = handleMessageUnderExperiment(message,
                                                                          messages,
                                                                          messagingHelper,
                                                                          feature.onControl)
            else { return nil }

            return nextTriggeredMessage
        }

        return message
    }

    /// Handle impression reporting and bookkeeping.
    func onMessageDisplayed(_ message: GleanPlumbMessage) {
        messagingStore.onMessageDisplayed(message)

        TelemetryWrapper.recordEvent(category: .information,
                                     method: .view,
                                     object: .messaging,
                                     value: .messageImpression,
                                     extras: baseTelemetryExtras(using: message))
    }

    /// Handle when a user hits the CTA of the surface, and forward the bookkeeping to the store.
    func onMessagePressed(_ message: GleanPlumbMessage) {
        messagingStore.onMessagePressed(message)

        guard let helper = helperUtility.createNimbusMessagingHelper() else { return }

        // Make substitutions where they're needed.
        let template = message.action
        let uuid = helper.getUuid(template: template)
        let action = helper.stringFormat(template: template, uuid: uuid)

        // Create the message action URL.
        let urlString = action.hasPrefix("://") ? URL.mozInternalScheme + action : action
        guard let url = URL(string: urlString) else {
            self.onMalformedMessage(id: message.id, surface: message.data.surface)
            return
        }

        var urlToOpen = url

        // We open webpages using our internal URL scheme
        if url.isWebPage(), var components = URLComponents(string: "\(URL.mozInternalScheme)://open-url") {
            components.queryItems = [URLQueryItem(name: "url", value: url.absoluteString)]
            urlToOpen = components.url ?? url
        }

        // With our well-formed URL, we can handle the action here.
        applicationHelper.open(urlToOpen)

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

        TelemetryWrapper.recordEvent(category: .action,
                                     method: .tap,
                                     object: .messaging,
                                     value: .messageDismissed,
                                     extras: baseTelemetryExtras(using: message))
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
    /// - Returns: the message if existent, otherwise nil.
    func messageForId(_ id: String) -> GleanPlumbMessage? {
        let feature = messagingFeature.value()
        guard let messageData = feature.messages[id] else { return nil }

        switch createMessage(messageId: id,
                             message: messageData,
                             lookupTables: feature) {
        case .success(let newMessage): return newMessage
        case .failure: return nil
        }
    }

    // MARK: - Misc. Private helpers

    /// - Returns: All well-formed, non-expired messages in descending priority order.
    func getMessages(_ feature: Messaging) -> [GleanPlumbMessage] {
        // All these are non-expired, well formed, and descending priority messages.
        let messages = feature.messages.compactMap { key, messageData -> GleanPlumbMessage? in
            switch createMessage(messageId: key, message: messageData, lookupTables: feature) {
            case .success(let newMessage):
                return newMessage
            case .failure(let failureReason):
                if failureReason == .malformed {
                    onMalformedMessage(id: key, surface: messageData.surface)
                }
                return nil
            }
        }.filter { message in
            !message.isExpired
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
    ) -> Result<GleanPlumbMessage, CreateMessageError> {
        // Guard against a message with a blank `text` property.
        guard !message.text.isEmpty else { return .failure(.malformed) }

        // Ascertain a Message's style, to know priority and max impressions.
        guard let style = lookupTables.styles[message.style] else { return .failure(.malformed) }

        // The message action should be either from the lookup table OR a URL.
        let action = lookupTables.actions[message.action] ?? message.action
        guard action.contains("://") else { return .failure(.malformed) }

        let triggers = message.trigger.compactMap { trigger in
            lookupTables.triggers[trigger]
        }

        // Be sure the count on `triggers` and `message.triggers` are equal.
        // If these mismatch, that means a message contains a trigger not in the triggers lookup table.
        // JEXLS can only be evaluated on supported triggers. Otherwise, consider the message malformed.
        if triggers.count != message.trigger.count {
            return .failure(.malformed)
        }

        let messageMetadata = messagingStore.getMessageMetadata(messageId: messageId)
        return .success(
            GleanPlumbMessage(id: messageId,
                              data: message,
                              action: action,
                              triggers: triggers,
                              style: style,
                              metadata: messageMetadata)
        )
    }

    /// From the list of messages that are well-formed and non-expired, we return the next / first triggered message.
    ///
    /// - Returns: The next triggered message, if one exists.
    private func getNextTriggeredMessage(_ messages: [GleanPlumbMessage], _ helper: NimbusMessagingHelperProtocol) -> GleanPlumbMessage? {
        var jexlCache = [String: Bool]()
        return messages.first { message in
            do {
                return try evaluationUtility.isMessageEligible(message, messageHelper: helper, jexlCache: &jexlCache)
            } catch {
                return false
            }
        }
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
                                              _ helper: NimbusMessagingHelperProtocol,
                                              _ onControl: ControlMessageBehavior) -> GleanPlumbMessage? {
        messagingFeature.recordExposure()
        let onControlActions = onControl

        if !message.data.isControl { return message }

        switch onControlActions {
        case .showNone:
            return nil
        case .showNextMessage:
            var jexlCache = [String: Bool]()
            return messages.first { message in
                do {
                    return try evaluationUtility.isMessageEligible(message, messageHelper: helper, jexlCache: &jexlCache)
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
