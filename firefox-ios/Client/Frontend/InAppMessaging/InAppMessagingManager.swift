// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation

protocol InAppMessagingManagerProtocol {
    func fetchMessages() async
    func nextMessage(for surface: InAppMessage.Surface) -> InAppMessage?
    func recordImpression(for messageID: String)
    func recordDismissal(for messageID: String)
}

final class InAppMessagingManager: InAppMessagingManagerProtocol {
    private let client: InAppMessagingClientProtocol
    private let storage: InAppMessagingStorage
    private let logger: Logger
    private var messages: [InAppMessage] = []

    init(
        client: InAppMessagingClientProtocol,
        storage: InAppMessagingStorage = InAppMessagingStorage(),
        logger: Logger = DefaultLogger.shared
    ) {
        self.client = client
        self.storage = storage
        self.logger = logger
    }

    func fetchMessages() async {
        do {
            let manifest = try await client.fetchManifest()
            messages = manifest.messages
        } catch {
            logger.log(
                "Failed to fetch in-app messages: \(error.localizedDescription)",
                level: .warning,
                category: .lifecycle
            )
        }
    }

    func nextMessage(for surface: InAppMessage.Surface) -> InAppMessage? {
        return messages
            .filter { $0.surface == surface }
            .filter { isEligible($0) }
            .sorted { $0.priority > $1.priority }
            .first
    }

    func recordImpression(for messageID: String) {
        storage.incrementImpressionCount(for: messageID)
    }

    func recordDismissal(for messageID: String) {
        storage.markDismissed(messageID)
    }

    private func isEligible(_ message: InAppMessage) -> Bool {
        if storage.isDismissed(message.id) { return false }

        if let max = message.maxImpressions,
           storage.impressionCount(for: message.id) >= max {
            return false
        }

        if let targeting = message.targeting {
            if !matchesLocale(targeting) { return false }
            if !matchesAppVersion(targeting) { return false }
            if !matchesDateRange(targeting) { return false }
            if !matchesRollout(targeting, messageID: message.id) { return false }
        }

        return true
    }

    private func matchesLocale(_ targeting: InAppMessage.Targeting) -> Bool {
        guard let locales = targeting.locales, !locales.isEmpty else { return true }
        let current = Locale.current.identifier
        let language = Locale.current.language.languageCode?.identifier ?? ""
        return locales.contains(where: { current.hasPrefix($0) || language == $0 })
    }

    private func matchesAppVersion(_ targeting: InAppMessage.Targeting) -> Bool {
        guard let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        else { return true }

        if let min = targeting.minAppVersion, appVersion.compare(min, options: .numeric) == .orderedAscending {
            return false
        }
        if let max = targeting.maxAppVersion, appVersion.compare(max, options: .numeric) == .orderedDescending {
            return false
        }
        return true
    }

    private func matchesDateRange(_ targeting: InAppMessage.Targeting) -> Bool {
        let now = Date()
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        if let start = targeting.startDate, let startDate = formatter.date(from: start), now < startDate {
            return false
        }
        if let end = targeting.endDate, let endDate = formatter.date(from: end), now > endDate {
            return false
        }
        return true
    }

    private func matchesRollout(_ targeting: InAppMessage.Targeting, messageID: String) -> Bool {
        guard let percent = targeting.rolloutPercent else { return true }
        let hash = abs(messageID.hashValue ^ (Bundle.main.bundleIdentifier ?? "").hashValue)
        let bucket = Double(hash % 100)
        return bucket < percent
    }
}
