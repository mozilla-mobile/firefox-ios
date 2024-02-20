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

    /// Report impressions in Glean, and then pass the bookkeeping to increment
    /// the impression count and expire to `MessageStore`.
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
    private let messagingFeature: FeatureHolder<Messaging>
    private let applicationHelper: ApplicationHelper

    typealias MessagingKey = TelemetryWrapper.EventExtraKey

    private enum CreateMessageError: Error {
        case malformed
    }

    // MARK: - Inits

    init(
        helperUtility: NimbusMessagingHelperUtilityProtocol = NimbusMessagingHelperUtility(),
        messagingUtility: NimbusMessagingEvaluationUtility = NimbusMessagingEvaluationUtility(),
        messagingStore: GleanPlumbMessageStoreProtocol = GleanPlumbMessageStore(),
        applicationHelper: ApplicationHelper = DefaultApplicationHelper(),
        messagingFeature: FeatureHolder<Messaging> = FxNimbusMessaging.shared.features.messaging
    ) {
        self.helperUtility = helperUtility
        self.evaluationUtility = messagingUtility
        self.messagingStore = messagingStore
        self.applicationHelper = applicationHelper
        self.messagingFeature = messagingFeature

        onStartup()
    }

    // MARK: - GleanPlumbMessageManagerProtocol Conformance

    /// Perform any startup setup if necessary.
    func onStartup() { }

    /// Returns the next valid and triggered message for the surface, if one exists.
    public func getNextMessage(for surface: MessageSurfaceId) -> GleanPlumbMessage? {
        // All these are non-expired, well formed, and descending priority ordered messages for a requested surface.
        return getNextMessage(for: surface, availableMessages: getMessages(messagingFeature.value()))
    }

    public func getNextMessage(
        for surface: MessageSurfaceId,
        availableMessages messages: [GleanPlumbMessage]
    ) -> GleanPlumbMessage? {
        let availableMessages = messages.filter {
            $0.data.surface == surface
        }.filter {
            !$0.isExpired && !$0.isInteractedWith
        }
        // If `NimbusMessagingHelper` creation fails, we cannot continue with this
        // feature! For that reason, return `nil`. We need to recreate the helper
        // for each request to get a message because device context can change.
        guard let messagingHelper = helperUtility.createNimbusMessagingHelper() else { return nil }

        var excluded: Set<String> = []
        return getNextMessage(for: surface,
                              availableMessages: availableMessages,
                              excluded: &excluded,
                              messagingHelper: messagingHelper)
    }

    // TODO: inout removal ticket https://mozilla-hub.atlassian.net/browse/FXIOS-6572
    private func getNextMessage(
            for surface: MessageSurfaceId,
            availableMessages: [GleanPlumbMessage],
            excluded: inout Set<String>,
            messagingHelper: NimbusMessagingHelperProtocol
    ) -> GleanPlumbMessage? {
        let message = availableMessages.first { message in
            if excluded.contains(message.id) {
                return false
            }
            do {
                return try evaluationUtility.isMessageEligible(message,
                                                               messageHelper: messagingHelper)
            } catch {
                return false
            }
        }
        guard let message = message else { return nil }

        // 1. record an exposure event. We can tie the message directly to the experiment
        if let slug = message.data.experiment {
            messagingFeature.recordExperimentExposure(slug: slug)
        } else if message.data.isControl {
            onMalformedMessage(id: message.id, surface: surface)
        }

        // 2. handle control messages appropriately.
        if !message.data.isControl {
            return message
        }

        // Control messages need to do the bookkeeping *here*, rather than from where they're displayed,
        // because they're not displayed.
        messagingStore.onMessageDisplayed(message)

        switch messagingFeature.value().onControl {
        case .showNone:
            return nil
        case .showNextMessage:
            excluded.insert(message.id)
            return getNextMessage(for: surface,
                                  availableMessages: availableMessages,
                                  excluded: &excluded,
                                  messagingHelper: messagingHelper)
        }
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
        guard let url = URL(string: urlString, invalidCharacters: false) else {
            self.onMalformedMessage(id: message.id, surface: message.surface)
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
        messagingFeature.recordMalformedConfiguration(with: id)
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
        var action: String
        if !message.isControl {
            // Guard against a message with a blank `text` property.
            guard !message.text.isEmpty else { return .failure(.malformed) }

            // The message action should be either from the lookup table OR a URL.
            guard let safeAction = sanitizeAction(message.action, table: lookupTables.actions) else {
                return .failure(.malformed)
            }
            action = safeAction
        } else {
            action = "CONTROL_ACTION"
        }

        // Ascertain a Message's style, to know priority and max impressions.
        guard let style = sanitizeStyle(message.style, table: lookupTables.styles) else { return .failure(.malformed) }

        guard let triggers = sanitizeTriggers(message.trigger, table: lookupTables.triggers) else {
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

    private func sanitizeAction(_ unsafeAction: String, table: [String: String]) -> String? {
        let action = table[unsafeAction] ?? unsafeAction
        if action.contains("://") {
            return action
        } else {
            return nil
        }
    }

    private func sanitizeTriggers(_ unsafeTriggers: [String], table: [String: String]) -> [String]? {
        var triggers = [String]()
        for unsafeTrigger in unsafeTriggers {
            guard let safeTrigger = table[unsafeTrigger] else { return nil }
            triggers.append(safeTrigger)
        }
        return triggers
    }

    private func sanitizeStyle(_ unsafeStyle: String, table: [String: StyleData]) -> StyleData? {
        return table[unsafeStyle]
    }

    private func baseTelemetryExtras(using message: GleanPlumbMessage) -> [String: String] {
        return [MessagingKey.messageKey.rawValue: message.id,
                MessagingKey.messageSurface.rawValue: message.surface.rawValue]
    }
}
