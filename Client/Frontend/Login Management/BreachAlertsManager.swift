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
    var breaches: [BreachRecord] = []
    var breachAlertsClient: BreachAlertsClientProtocol

    init(_ client: BreachAlertsClientProtocol = BreachAlertsClient()) {
        self.breachAlertsClient = client
    }

    /// Loads breaches from Monitor endpoint using BreachAlertsClient.
    ///    - Parameters:
    ///         - completion: a completion handler for the processed breaches
    func loadBreaches(completion: @escaping (Maybe<[BreachRecord]>) -> Void) {
        print("loadBreaches(): called")

        self.breachAlertsClient.fetchData(endpoint: .breachedAccounts) { maybeData in
            guard let data = maybeData.successValue else {
                completion(Maybe(failure: BreachAlertsError(description: "failed to load breaches data")))
                return
            }
            guard let decoded = try? JSONDecoder().decode([BreachRecord].self, from: data) else {
                completion(Maybe(failure: BreachAlertsError(description: "JSON data decode failure")))
                return
            }

            self.breaches = decoded
            completion(Maybe(success: self.breaches))
        }
    }

    /// Compares a list of logins to a list of breaches and returns breached logins.
    ///    - Parameters:
    ///         - logins: a list of logins to compare breaches to
    ///    - Returns:
    ///         - an array of LoginRecords of breaches in the original list.
    func findUserBreaches(_ logins: [LoginRecord]) -> Maybe<[LoginRecord]> {
        var result: [LoginRecord] = []

        if self.breaches.count <= 0 {
            return Maybe(failure: BreachAlertsError(description: "cannot compare to an empty list of breaches"))
        } else if logins.count <= 0 {
            return Maybe(failure: BreachAlertsError(description: "cannot compare to an empty list of logins"))
        }

        let loginsDictionary = loginsByHostname(logins)
        for breach in self.breaches {
            if let potentialBreaches = loginsDictionary[breach.domain] {
                for item in potentialBreaches {
                    let pwLastChanged = TimeInterval(item.timePasswordChanged/1000)
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd"
                    if let breachDate = dateFormatter.date(from: breach.breachDate)?.timeIntervalSince1970, pwLastChanged < breachDate {
                        print("compareToBreaches(): ⚠️ password exposed ⚠️: \(breach.breachDate)")
                        result.append(item)
                    }
                }
            }
        }
        print("compareToBreaches(): fin")
        return Maybe(success: result)
    }

    func loginsByHostname(_ logins: [LoginRecord]) -> [String: [LoginRecord]] {
        var result = [String: [LoginRecord]]()
        var baseDomains = Set<String>()
        for login in logins {
            baseDomains.insert(baseDomainForLogin(login))
        }
        for base in baseDomains {
            result[base] = [LoginRecord]()
        }

        for login in logins {
            result[self.baseDomainForLogin(login)]?.append(login)
        }
        return result
    }

    private func baseDomainForLogin(_ login: LoginRecord) -> String {
        guard let result = login.hostname.asURL?.baseDomain else { return login.hostname }
        return result
    }
}
