// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

import MozillaAppServices
import Shared

protocol GleanPlumbMessageManagable { }

extension GleanPlumbMessageManagable {
    var messagingManager: GleanPlumbMessageManager {
        return GleanPlumbMessageManager.shared
    }
}

protocol GleanPlumbMessageManagerProtocol {

    /// Does the bookkeeping and preparation of messages for their respective surfaces.
    /// We can build our collection of eligible messages for the surface in here.
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
    func onMalformedMessage(messageKey: String)
}

/// The `GleanPlumbMessageManager` is responsible for several things including:
/// - preparing Messages for a given UI surface
///
/// - reporting telemetry for `GleanPlumbMessage`s:
///     - impression counts
///     - user dismissal of a message
///     - expiration logic
///     - exposure
///     - malformed message
///     - expiration (handled in the store)
///
/// To the surface that requests messages, it provides well-formed, triggered, non-expired messages in priority order.
///
class GleanPlumbMessageManager: GleanPlumbMessageManagerProtocol {

    // MARK: - Properties

    static let shared = GleanPlumbMessageManager()

    private let messagingHelper: GleanPlumbHelper
    private let messagingStore: GleanPlumbMessageStore

    // MARK: - Inits

    init(messagingHelper: GleanPlumbHelper = GleanPlumbHelper(),
         messagingStore: GleanPlumbMessageStore = GleanPlumbMessageStore()) {
        self.messagingHelper = messagingHelper
        self.messagingStore = messagingStore

        onStartup()
    }

    // MARK: - Messaging Protocol Conformance

    /// Perform any startup setup if necessary.
    func onStartup() {
        // placeholder
    }

    /// We assemble one message at a time. If there's any issue with it, return `nil`.
    /// Reporting a malformed message is done at the call site when reacting to a `nil`.
    func createMessage(messageId: String, message: MessageData, lookupTables: Messaging) -> GleanPlumbMessage? {

        /// Ascertain a Message's style, to know priority and max impressions.
        guard let style = lookupTables.styles[message.style] else { return nil }

        /// The message action should be either from the lookup table OR a URL.
        let action = lookupTables.actions[message.action] ?? message.action
        guard action.contains("://") else { return nil }

        let triggers = message.trigger.compactMap { trigger in
            lookupTables.triggers[trigger]
        }

        /// Be sure the count on `triggers` and `message.triggers` are equal.
        /// If these mismatch, that means a message contains a trigger not in the triggers lookup table.
        /// JEXLS can only be evaluated on supported triggers. Otherwise, consider the message malformed.
        if triggers.count != message.trigger.count {
            return nil
        }

        return GleanPlumbMessage(id: messageId,
                                 data: message,
                                 action: action,
                                 triggers: triggers,
                                 style: style,
                                 metadata: messagingStore.getMessageMetadata(messageId: messageId))
    }

    /// Returns the next well-formed, non-expired, triggered message in descending priority order.
    func getNextMessage(for surface: MessageSurfaceId) -> GleanPlumbMessage? {
        let feature = FxNimbus.shared.features.messaging.value()
        guard let helper = messagingHelper.createGleanPlumbHelper() else { return nil }

        /// All these are non-expired, well formed messages for a requested surface.
        let messages = feature.messages.compactMap { key, messageData -> GleanPlumbMessage? in
            if let message = self.createMessage(messageId: key,
                                                message: messageData,
                                                lookupTables: feature) {
                return message
            }

            onMalformedMessage(messageKey: key)

            return nil

        }.filter { message in
            !messagingHelper.checkExpiryFor(message)
        }.filter { message in
            message.data.surface == surface
        }.sorted { message1, message2 in
            message1.style.priority > message2.style.priority
        }

        /// Take the first triggered message.
        guard let message = messages.first(where: { message in
            do {
                return try messagingHelper.isMessageEligible(message, messageHelper: helper)
            } catch {
                return false
            }
        }) else {
            return nil
        }

        /// If it's a message under experiment, we need to react to whether it's a control or not.
        if messagingHelper.isMessageUnderExperiment(experimentKey: feature.messageUnderExperiment, message: message) {
            FxNimbus.shared.features.messaging.recordExposure()
            let onControlActions = feature.onControl

            if message.data.isControl {
                switch onControlActions {
                case .showNone:
                    return nil
                case .showNextMessage:
                    return messages.first { message in
                        do {
                            return try messagingHelper.isMessageEligible(message, messageHelper: helper)
                            && !message.data.isControl
                        } catch {
                            onMalformedMessage(messageKey: message.id)
                            return false
                        }
                    }
                }
            }
        }

        return message
    }

    /// Handle impression reporting and bookkeeping.
    func onMessageDisplayed(_ message: GleanPlumbMessage) {
        messagingStore.onMessageDisplayed(message)

        TelemetryWrapper.recordEvent(category: .information,
                                     method: .view,
                                     object: .homeTabBanner,
                                     value: .messageImpression,
                                     extras: [TelemetryWrapper.EventExtraKey.messageKey.rawValue: message.id])
    }

    /// Handle when a user hits the CTA of the surface, and forward the bookkeeping to the store.
    func onMessagePressed(_ message: GleanPlumbMessage) {
        messagingStore.onMessagePressed(message)

        guard let helper = messagingHelper.createGleanPlumbHelper() else { return }

        /// Make substitutions where they're needed.
        let template = message.action
        let uuid = helper.getUuid(template: template)
        let action = helper.stringFormat(template: template, uuid: uuid)

        /// Create the message action URL.
        let urlString = action.hasPrefix("://") ? URL.mozInternalScheme + action : action
        guard let url = URL(string: urlString) else {
            self.onMalformedMessage(messageKey: message.id)
            return
        }

        /// With our well-formed URL, we can handle the action here.
        if url.isWebPage() {
            let bvc = BrowserViewController.foregroundBVC()
            bvc.openURLInNewTab(url)
        } else {
            UIApplication.shared.open(url, options: [:])
        }

        TelemetryWrapper.recordEvent(category: .action,
                                     method: .tap,
                                     object: .homeTabBanner,
                                     value: .messageInteracted,
                                     extras: [TelemetryWrapper.EventExtraKey.messageKey.rawValue: message.id,
                                              TelemetryWrapper.EventExtraKey.actionUUID.rawValue: UUID()])
    }

    /// For now, we will assume all dismissed messages should become expired right away. The
    /// store handles this bookkeeping.
    func onMessageDismissed(_ message: GleanPlumbMessage) {
        messagingStore.onMessageDismissed(message)

        TelemetryWrapper.recordEvent(category: .action,
                                     method: .tap,
                                     object: .homeTabBanner,
                                     value: .messageDismissed,
                                     extras: [TelemetryWrapper.EventExtraKey.messageKey.rawValue: message.id])
    }

    func onMalformedMessage(messageKey: String) {
        TelemetryWrapper.recordEvent(category: .information,
                                     method: .application,
                                     object: .homeTabBanner,
                                     value: .messageMalformed,
                                     extras: [TelemetryWrapper.EventExtraKey.messageKey.rawValue: messageKey])
    }

}
