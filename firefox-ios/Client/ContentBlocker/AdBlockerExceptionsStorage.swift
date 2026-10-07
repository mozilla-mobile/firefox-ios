// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation

@MainActor
protocol AdBlockerExceptionsStorageProtocol {
    var domains: [String] { get }
    var count: Int { get }
    func addDomain(_ domain: String)
    func removeDomain(_ domain: String)
    func removeDomains(_ domains: Set<String>)
    func removeAllDomains()
    func containsDomain(_ domain: String) -> Bool
}

@MainActor
final class AdBlockerExceptionsStorage: AdBlockerExceptionsStorageProtocol {
    static let shared = AdBlockerExceptionsStorage()

    private let fileName = "adBlockerExceptions"
    private(set) var domains: [String] = []
    private let logger: Logger

    init(logger: Logger = DefaultLogger.shared) {
        self.logger = logger
        loadFromDisk()
    }

    var count: Int { domains.count }

    func addDomain(_ domain: String) {
        let normalized = normalizeDomain(domain)
        guard !normalized.isEmpty, !domains.contains(normalized) else { return }
        domains.append(normalized)
        saveToDisk()
    }

    func removeDomain(_ domain: String) {
        let normalized = normalizeDomain(domain)
        domains.removeAll { $0 == normalized }
        saveToDisk()
    }

    func removeDomains(_ domainsToRemove: Set<String>) {
        domains.removeAll { domainsToRemove.contains($0) }
        saveToDisk()
    }

    func removeAllDomains() {
        domains.removeAll()
        saveToDisk()
    }

    func containsDomain(_ domain: String) -> Bool {
        return domains.contains(normalizeDomain(domain))
    }

    func domainRegexList() -> [String] {
        return domains.compactMap { wildcardContentBlockerDomainToRegex(domain: "*" + $0) }
    }

    func exceptionsAsJSON() -> String {
        guard !domains.isEmpty else { return "" }
        let list = "\"*" + domains.joined(separator: "\",\"*") + "\""
        return """
        , {"action": { "type": "ignore-previous-rules" }, "trigger": { "url-filter": ".*", "if-domain": [\(list)] }}
        """
    }

    // MARK: - Private

    private func normalizeDomain(_ domain: String) -> String {
        var d = domain.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if d.hasPrefix("http://") { d = String(d.dropFirst(7)) }
        if d.hasPrefix("https://") { d = String(d.dropFirst(8)) }
        if d.hasPrefix("www.") { d = String(d.dropFirst(4)) }
        if d.hasSuffix("/") { d = String(d.dropLast()) }
        return d
    }

    private func fileURL() -> URL? {
        guard let dir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else { return nil }
        return dir.appendingPathComponent(fileName)
    }

    private func loadFromDisk() {
        guard let fileURL = fileURL(),
              FileManager.default.fileExists(atPath: fileURL.path),
              let text = try? String(contentsOf: fileURL, encoding: .utf8),
              !text.isEmpty else {
            return
        }
        domains = text.components(separatedBy: .newlines).filter { !$0.isEmpty }
    }

    private func saveToDisk() {
        guard let fileURL = fileURL() else { return }
        if domains.isEmpty {
            try? FileManager.default.removeItem(at: fileURL)
            return
        }
        let text = domains.joined(separator: "\n")
        do {
            try text.write(to: fileURL, atomically: true, encoding: .utf8)
        } catch {
            logger.log("Failed to save ad blocker exceptions: \(error)",
                       level: .warning,
                       category: .adblock)
        }
    }
}
