// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import Shared

import class MozillaAppServices.FeatureHolder
import enum MozillaAppServices.NimbusError
import protocol MozillaAppServices.NimbusMessagingHelperProtocol

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
    /// An optional UUID for the originating window can be provided to ensure any
    /// resulting UI is displayed in the correct window.
    /// Surface calls.
    func onMessagePressed(_ message: GleanPlumbMessage, window: WindowUUID?, shouldExpire: Bool)

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

    private let createMessagingHelper: NimbusMessagingHelperUtilityProtocol
    private let evaluationUtility: NimbusMessagingEvaluationUtility
    private let messagingStore: GleanPlumbMessageStoreProtocol
    private let messagingFeature: FeatureHolder<Messaging>
    private let applicationHelper: ApplicationHelper
    private let deepLinkScheme: String

    typealias MessagingKey = TelemetryWrapper.EventExtraKey

    private enum CreateMessageError: Error {
        case malformed
    }

    // MARK: - Inits

    init(
        createMessagingHelper: NimbusMessagingHelperUtilityProtocol = NimbusMessagingHelperUtility(),
        messagingUtility: NimbusMessagingEvaluationUtility = NimbusMessagingEvaluationUtility(),
        messagingStore: GleanPlumbMessageStoreProtocol = GleanPlumbMessageStore(),
        applicationHelper: ApplicationHelper = DefaultApplicationHelper(),
        messagingFeature: FeatureHolder<Messaging> = FxNimbusMessaging.shared.features.messaging,
        deepLinkScheme: String = URL.mozInternalScheme
    ) {
        self.createMessagingHelper = createMessagingHelper
        self.evaluationUtility = messagingUtility
        self.messagingStore = messagingStore
        self.applicationHelper = applicationHelper
        self.messagingFeature = messagingFeature
        self.deepLinkScheme = deepLinkScheme

        onStartup()
    }

    // MARK: - GleanPlumbMessageManagerProtocol Conformance

    /// Perform any startup setup if necessary.
    func onStartup() { }

    /// Returns the next valid and triggered message for the surface, if one exists.
    public func getNextMessage(for surface: MessageSurfaceId) -> GleanPlumbMessage? {
        // All these are non-expired, well formed, and descending priority ordered messages for a requested surface.
        return getNextMessage(for: surface, from: getMessages(messagingFeature.value()))
    }

    public func getNextMessage(
        for surface: MessageSurfaceId,
        from messages: [GleanPlumbMessage]
    ) -> GleanPlumbMessage? {
        let availableMessages = messages.filter {
            $0.data.surface == surface
        }.filter {
            !$0.isExpired && !$0.isInteractedWith
        }
        // If `NimbusMessagingHelper` creation fails, we cannot continue with this
        // feature! For that reason, return `nil`. We need to recreate the helper
        // for each request to get a message because device context can change.
        guard let messagingHelper = createMessagingHelper.createNimbusMessagingHelper() else { return nil }

        return getNextMessage(for: surface,
                              from: availableMessages,
                              excluded: [],
                              messagingHelper: messagingHelper)
    }

    private func getNextMessage(
        for surface: MessageSurfaceId,
        from availableMessages: [GleanPlumbMessage],
        excluded: Set<String>,
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

        // If there are no eligible messages, we can return.
        guard let message = message else { return nil }

        // If this isn't a control message, then we return it.
        // The surface should call into onMessageDisplayed when it gets displayed.
        if !message.data.isControl {
            return message
        }

        // Control messages need to do the bookkeeping *here*, rather than from where they're displayed,
        // because they're not displayed.
        onMessageDisplayedInternal(message)

        switch messagingFeature.value().onControl {
        case .showNone:
            return nil
        case .showNextMessage:
            let excluded = excluded + [message.id]
            return getNextMessage(for: surface,
                                  from: availableMessages,
                                  excluded: Set(excluded),
                                  messagingHelper: messagingHelper)
        }
    }

    /// Handle impression reporting and bookkeeping.
    func onMessageDisplayed(_ message: GleanPlumbMessage) {
        onMessageDisplayedInternal(message)

        TelemetryWrapper.recordEvent(category: .information,
                                     method: .view,
                                     object: .messaging,
                                     value: .messageImpression,
                                     extras: baseTelemetryExtras(using: message))
    }

    func onMessageDisplayedInternal(_ message: GleanPlumbMessage) {
        // Record an exposure event. We can tie the message directly to the experiment
        if let slug = message.data.experiment {
            messagingFeature.recordExperimentExposure(slug: slug)
        } else if message.data.isControl {
            onMalformedMessage(id: message.id, surface: message.surface)
        }

        // Increment the number of times this has been displayed.
        messagingStore.onMessageDisplayed(message)
    }

    /// Handle when a user hits the CTA of the surface, and forward the bookkeeping to the store.
    func onMessagePressed(_ message: GleanPlumbMessage, window: WindowUUID?, shouldExpire: Bool = true) {
        messagingStore.onMessagePressed(message, shouldExpire: shouldExpire)

        var extras = baseTelemetryExtras(using: message)
        if let action = message.action {
            if let uuid = handleLinkAction(for: message, action: action, window: window) {
                extras[MessagingKey.actionUUID.rawValue] = uuid
            }
        }

        TelemetryWrapper.recordEvent(category: .action,
                                     method: .tap,
                                     object: .messaging,
                                     value: .messageInteracted,
                                     extras: extras)
    }

    private func handleLinkAction(
        for message: GleanPlumbMessage,
        action: String,
        window: WindowUUID?
    ) -> String? {
        guard let helper = createMessagingHelper.createNimbusMessagingHelper() else { return nil }
        guard let (uuid, urlToOpen) = try? self.generateUuidAndFormatAction(
            for: action,
            with: message.data.actionParams,
            with: helper
        ) else {
            self.onMalformedMessage(id: message.id, surface: message.surface)
            return nil
        }

        // With our well-formed URL, we can handle the action here.
        if let specificWindow = window {
            applicationHelper.open(urlToOpen, inWindow: specificWindow)
        } else {
            applicationHelper.open(urlToOpen)
        }
        return uuid
    }

    private func generateUuidAndFormatAction(for action: String,
                                             with actionParams: [String: String],
                                             with helper: NimbusMessagingHelperProtocol) throws -> (String?, URL) {
        // Make substitutions where they're needed.
        let actionTemplate = action
        var uuid = helper.getUuid(template: actionTemplate)
        let action = helper.stringFormat(template: actionTemplate, uuid: uuid)

        let urlString: String = action.hasPrefix("://") ? deepLinkScheme + action : action
        guard var components = URLComponents(string: urlString) else {
            throw NimbusError.UrlParsingError(message: "\(urlString) is not a valid URL")
        }
        var queryItems = components.queryItems ?? []

        for (key, valueTemplate) in actionParams {
            if uuid == nil {
                uuid = helper.getUuid(template: valueTemplate)
            }
            let value = helper.stringFormat(template: valueTemplate, uuid: uuid)
            queryItems.append(URLQueryItem(name: key, value: value))
        }

        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }

        guard let url = components.url else {
            throw NimbusError.UrlParsingError(message: "Cannot create URL from action-params \(actionParams)")
        }

        return (uuid, url)
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
        var action: String?
        if !message.isControl {
            // Guard against a message with a blank `text` property.
            guard !message.text.isEmpty else { return .failure(.malformed) }

            // Message action can be null. If not null,
            // the message action should be either from the lookup table OR a URL.
            if let messageAction = message.action {
                guard let safeAction = sanitizeAction(messageAction, table: lookupTables.actions) else {
                    return .failure(.malformed)
                }
                action = safeAction
            }
        } else {
            action = "CONTROL_ACTION"
        }

        // Ascertain a Message's style, to know priority and max impressions.
        guard let style = sanitizeStyle(message.style, table: lookupTables.styles) else { return .failure(.malformed) }

        guard let triggerIfAll = sanitizeTriggers(message.triggerIfAll, table: lookupTables.triggers) else {
            return .failure(.malformed)
        }
        guard let exceptIfAny = sanitizeTriggers(message.exceptIfAny, table: lookupTables.triggers) else {
            return .failure(.malformed)
        }

        let messageMetadata = messagingStore.getMessageMetadata(messageId: messageId)
        return .success(
            GleanPlumbMessage(id: messageId,
                              data: message,
                              action: action,
                              triggerIfAll: triggerIfAll,
                              exceptIfAny: exceptIfAny,
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
