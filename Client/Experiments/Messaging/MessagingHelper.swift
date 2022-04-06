// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

import MozillaAppServices
import Shared

protocol MessagingHelperProtocol { }

extension MessagingHelperProtocol {
    var messagingHelper: MessagingHelper {
        return MessagingHelper.shared
    }
}

/// The Message Helper is responsible for preparing fetched messages to appear in a UI surface.
/// It should do all operations on a message and return only valid, eligible, non-expired messages FOR the associated surface.
class MessagingHelper: Loggable {
    
    // MARK: - Properties
    
    static let shared = MessagingHelper()
    
    init() {
        
    }
    
    // MARK: - Public helpers
    
    /// JEXLs are more accurately evaluated when given certain details about the app on device.
    /// There is a limited amount of context you can give. See:
    /// - https://experimenter.info/mobile-messaging/#list-of-attributes
    func createAdditionalContext() -> [String: Any] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-mm-dd"
        let todaysDate = dateFormatter.string(from: Date())
        
        return ["date_string": todaysDate]
    }
    
    /// We check whether this message is triggered by evaluating message JEXLs.
    func isMessageEligible(message: Message, messageHelper: GleanPlumbMessageHelper) throws -> Bool {
        /// TODO: Save these in a lookup table so we don't need to reevaluate triggers every time.
        try message.triggers.reduce(true) { acc, trigger in
            guard acc else { return false }
            
            return try messageHelper.evalJexl(expression: trigger)
        }
    }
    
    /// Check message expiration.
    func isMessageExpired(message: Message) -> Bool {
        return message.metadata.isExpired || message.metadata.messageImpressions >= message.styleData.maxDisplayCount
    }
    
    /// The NewTabCard (HomeTabBanner) expects certain things from a message. We need
    /// to check that all these are NOT nil. The also ends up checking if a message is malformed.
    /// - title
    /// - text
    /// - button-label
    /// - action
    /// - trigger
    /// - style
    func evalNewTabCardNils(message: MessageData) -> Bool {
        let areAnyPropertiesNil = [message.title,
                                   message.text,
                                   message.buttonLabel,
                                   message.action,
                                   message.style].anyNil() && !message.trigger.isEmpty
        
        return areAnyPropertiesNil
    }
    
    /// If the message is under experiment, the call site needs to handle it in a special way.
    func isMessageUnderExperiment(experimentKey: String?, message: Message) -> Bool {
        guard let key = experimentKey else { return false }

        if message.messageData.isControl { return true }
        
        if message.messageId.hasSuffix("-") {
            return message.messageId.hasPrefix(key)
        }
        
        return message.messageId == key
    }
    
    func createHelper() -> GleanPlumbMessageHelper? {
        /// Create our GleanPlumbMessageHelper, to evaluate triggers later.
        do {
            return try Experiments.shared.createMessageHelper(additionalContext: createAdditionalContext())
        } catch {
            /// If we're here, then all of Messaging is in limbo! Report the error and let the surface handle this `nil`
            Logger.browserLogger.error("GleanPlumbMessageHelper could not be created! With error \(error)")
            return nil
        }
        
    }
    
}
