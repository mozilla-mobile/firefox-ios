/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

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
final public class BreachAlertsManager {
    var breaches = Set<BreachRecord>()
    var breachAlertsClient: BreachAlertsClientProtocol

    init(_ client: BreachAlertsClientProtocol = BreachAlertsClient()) {
        self.breachAlertsClient = client
    }

    /// Loads breaches from Monitor endpoint using BreachAlertsClient.
    ///    - Parameters:
    ///         - completion: a completion handler for the processed breaches
    func loadBreaches(completion: @escaping (Maybe<Set<BreachRecord>>) -> Void) {
        print("loadBreaches(): called")

        self.breachAlertsClient.fetchData(endpoint: .breachedAccounts) { maybeData in
            guard let data = maybeData.successValue else {
                completion(Maybe(failure: BreachAlertsError(description: "failed to load breaches data")))
                return
            }
            guard let decoded = try? JSONDecoder().decode(Set<BreachRecord>.self, from: data) else {
                completion(Maybe(failure: BreachAlertsError(description: "JSON data decode failure")))
                return
            }

            self.breaches = decoded
            self.breaches.insert(BreachRecord(
             name: "MockBreach",
             title: "A Mock BreachRecord",
             domain: "abreachedwithalongstringname.com",
             breachDate: "1970-01-02",
             description: "A mock BreachRecord for testing purposes."
            ))
            self.breaches.insert(BreachRecord(
             name: "MockBreach",
             title: "A Mock BreachRecord",
             domain: "abreach.com",
             breachDate: "1970-01-02",
             description: "A mock BreachRecord for testing purposes."
            ))
            completion(Maybe(success: self.breaches))
        }
    }

    /// Compares a list of logins to a list of breaches and returns breached logins.
    ///    - Parameters:
    ///         - logins: a list of logins to compare breaches to
    ///    - Returns:
    ///         - an array of LoginRecords of breaches in the original list.
    func findUserBreaches(_ logins: [LoginRecord]) -> Maybe<Set<LoginRecord>> {
        var result = Set<LoginRecord>()

        if self.breaches.count <= 0 {
            return Maybe(failure: BreachAlertsError(description: "cannot compare to an empty list of breaches"))
        } else if logins.count <= 0 {
            return Maybe(failure: BreachAlertsError(description: "cannot compare to an empty list of logins"))
        }

        let loginsDictionary = loginsByHostname(logins)
        for breach in self.breaches {
            guard let potentialBreaches = loginsDictionary[breach.domain] else {
                continue
            }
            for item in potentialBreaches {
                let pwLastChanged = TimeInterval(item.timePasswordChanged/1000)
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                guard let breachDate = dateFormatter.date(from: breach.breachDate)?.timeIntervalSince1970, pwLastChanged < breachDate else {
                    continue
                }
                print("compareToBreaches(): ⚠️ password exposed ⚠️: \(breach.breachDate)")
                result.insert(item)
            }
        }
        print("compareToBreaches(): fin")
        return Maybe(success: result)
    }

    /// Helper function to creat a dictionary of LoginRecords separated by hostname.
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

    private func baseDomainForLogin(_ login: LoginRecord) -> String {
        guard let result = login.hostname.asURL?.baseDomain else { return login.hostname }
        return result
    }

    func breachRecordForLogin(_ login: LoginRecord) -> BreachRecord? {
        let baseDomain = self.baseDomainForLogin(login)
        for breach in self.breaches {
            if breach.domain == baseDomain {
                let pwLastChanged = TimeInterval(login.timePasswordChanged/1000)
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                guard let breachDate = dateFormatter.date(from: breach.breachDate)?.timeIntervalSince1970, pwLastChanged < breachDate else {
                    continue
                }
                return breach
            }
        }
        return nil
    }
}
