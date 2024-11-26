// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Storage // or whichever module has the LoginsRecord class
import Shared // or whichever module has the Maybe class

/// Breach structure decoded from JSON
struct BreachRecord: Codable, Equatable, Hashable {
    var name: String
    var title: String
    var domain: String
    var breachDate: String
    var description: String

    enum CodingKeys: String, CodingKey {
        case name = "Name"
        case title = "Title"
        case domain = "Domain"
        case breachDate = "BreachDate"
        case description = "Description"
    }
}

/// A manager for the user's breached login information, if any.
final class BreachAlertsManager {
    static let monitorAboutUrl = URL(string: "https://monitor.firefox.com/about")
    var breaches = Set<BreachRecord>()
    var client: BreachAlertsClientProtocol
    var profile: Profile!
    private lazy var cacheURL: URL? = {
        guard let path = try? self.profile.files.getAndEnsureDirectory() else { return nil }
        return URL(fileURLWithPath: path, isDirectory: true).appendingPathComponent("breaches.json")
    }()
    private let dateFormatter = DateFormatter()
    init(_ client: BreachAlertsClientProtocol = BreachAlertsClient(), profile: Profile) {
        self.client = client
        self.profile = profile
    }

    /// Loads breaches from Monitor endpoint using BreachAlertsClient.
    ///    - Parameters:
    ///         - completion: a completion handler for the processed breaches
    func loadBreaches(completion: @escaping (Maybe<Set<BreachRecord>>) -> Void) {
        guard let cacheURL = self.cacheURL else {
            self.fetchAndSaveBreaches(completion)
            return
        }

        // 1. check for local breaches file
        guard FileManager.default.fileExists(atPath: cacheURL.path) else {
            // 1a. no local file, so fetch and save as normal and hand off
            self.fetchAndSaveBreaches(completion)
            return
        }

        // 1b. local file exists, so load from that
        guard let fileData = FileManager.default.contents(atPath: cacheURL.path) else {
            completion(Maybe(failure: BreachAlertsError(description: "failed to get data from breach.json")))
            try? FileManager.default.removeItem(at: cacheURL) // bad file, so delete it
            self.fetchAndSaveBreaches(completion)
            return
        }

        // 2. check the last time breach endpoint was accessed
        guard let dateLastAccessed = profile.prefs.timestampForKey(BreachAlertsClient.etagDateKey) else {
            profile.prefs.removeObjectForKey(BreachAlertsClient.etagDateKey) // bad key, so delete it
            self.fetchAndSaveBreaches(completion)
            return
        }
        let timeUntilNextUpdate = UInt64(60 * 60 * 24 * 3 * 1000) // 3 days in milliseconds
        let shouldUpdateDate = dateLastAccessed + timeUntilNextUpdate

        // 3. if 3 days have not passed since last update...
        guard Date.now() >= shouldUpdateDate else {
            // 3a. no need to refetch. decode local data and hand off
            decodeData(data: fileData, completion)
            return
        }

        // 3b. should update - check if the etag is different
        client.fetchEtag(endpoint: .breachedAccounts, profile: self.profile) { etag in
            guard let etag = etag else {
                self.profile.prefs.removeObjectForKey(BreachAlertsClient.etagKey) // bad key, so delete it
                self.fetchAndSaveBreaches(completion)
                return
            }
            let savedEtag = self.profile.prefs.stringForKey(BreachAlertsClient.etagKey)

            // 4. if it is, refetch the data and hand entire Set of BreachRecords off
            if etag != savedEtag {
                self.fetchAndSaveBreaches(completion)
            } else {
                self.profile.prefs.setTimestamp(Date.now(), forKey: BreachAlertsClient.etagDateKey)
                self.decodeData(data: fileData, completion)
            }
        }
    }

    /// Compares a list of logins to a list of breaches and returns breached logins.
    ///    - Parameters:
    ///         - logins: a list of logins to compare breaches to
    ///    - Returns:
    ///         - an array of LoginRecords of breaches in the original list.
    func findUserBreaches(_ logins: [LoginRecord]) -> Maybe<Set<LoginRecord>> {
        var result = Set<LoginRecord>()

        if self.breaches.isEmpty {
            return Maybe(failure: BreachAlertsError(description: "cannot compare to an empty list of breaches"))
        } else if logins.isEmpty {
            return Maybe(failure: BreachAlertsError(description: "cannot compare to an empty list of logins"))
        }

        let loginsDictionary = loginsByHostname(logins)
        for breach in self.breaches {
            guard let potentialUserBreaches = loginsDictionary[breach.domain] else {
                continue
            }
            for item in potentialUserBreaches {
                let pwLastChanged = TimeInterval(item.timePasswordChanged/1000)
                self.dateFormatter.dateFormat = "yyyy-MM-dd"
                guard let breachDate = self.dateFormatter.date(from: breach.breachDate)?.timeIntervalSince1970,
                      pwLastChanged < breachDate
                else { continue }

                result.insert(item)
            }
        }
        return Maybe(success: result)
    }

    /// Helper function to create a dictionary of LoginRecords separated by hostname.
    /// - Parameters:
    ///     - logins: an array of LoginRecords to sort.
    /// - Returns:
    ///     - a dictionary of [String(<hostname>): [LoginRecord]].
    func loginsByHostname(_ logins: [LoginRecord]) -> [String: [LoginRecord]] {
        var result = [String: [LoginRecord]]()
        for login in logins {
            let base = baseDomainForLogin(login)
            if !result.keys.contains(base) {
                result[base] = [login]
            } else {
                result[base]?.append(login)
            }
        }
        return result
    }

    /// Helper function to find a breach associated with a LoginRecord.
    /// - Parameters:
    ///     - login: an array of LoginRecords to sort.
    /// - Returns:
    ///     - the first BreachRecord associated with login, if any.
    func breachRecordForLogin(_ login: LoginRecord) -> BreachRecord? {
        let baseDomain = self.baseDomainForLogin(login)
        for breach in self.breaches where breach.domain == baseDomain {
            let pwLastChanged = TimeInterval(login.timePasswordChanged/1000)
            self.dateFormatter.dateFormat = "yyyy-MM-dd"
            guard let breachDate = self.dateFormatter.date(from: breach.breachDate)?.timeIntervalSince1970,
                  pwLastChanged < breachDate
            else { continue }

            return breach
        }
        return nil
    }

    // MARK: - Helper Functions
    private func baseDomainForLogin(_ login: LoginRecord) -> String {
        guard let result = login.hostname.asURL?.baseDomain else { return login.hostname }
        return result
    }

    private func fetchAndSaveBreaches(_ completion: @escaping (Maybe<Set<BreachRecord>>) -> Void) {
        guard let cacheURL = self.cacheURL else { return }
        self.client.fetchData(endpoint: .breachedAccounts, profile: self.profile) { maybeData in
            guard let fetchedData = maybeData.successValue else { return }
            try? FileManager.default.removeItem(atPath: cacheURL.path)
            FileManager.default.createFile(atPath: cacheURL.path, contents: fetchedData, attributes: nil)

            guard let data = FileManager.default.contents(atPath: cacheURL.path) else { return }
            self.decodeData(data: data, completion)
        }
    }

    private func decodeData(data: Data, _ completion: @escaping (Maybe<Set<BreachRecord>>) -> Void) {
        guard let decoded = try? JSONDecoder().decode(Set<BreachRecord>.self, from: data) else {
            assertionFailure("Error decoding JSON data")
            return
        }

        self.breaches = decoded

        completion(Maybe(success: self.breaches))
    }
}
