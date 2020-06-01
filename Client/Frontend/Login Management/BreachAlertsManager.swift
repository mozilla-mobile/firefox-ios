/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Storage // or whichever module has the LoginsRecord class
import Shared // or whichever module has the Maybe class

/// Breach structure decoded from JSON
struct BreachRecord: Codable, Equatable {
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
    func compareToBreaches(_ logins: [LoginRecord]) -> Maybe<[LoginRecord]> {
        var result: [LoginRecord] = []

        if self.breaches.count <= 0 {
            return Maybe(failure: BreachAlertsError(description: "cannot compare to an empty list of breaches"))
        } else if logins.count <= 0 {
            return Maybe(failure: BreachAlertsError(description: "cannot compare to an empty list of logins"))
        }

        // TODO: optimize this loop
        for login in logins {
            for breach in self.breaches {
                // host check
                let loginHostURL = URL(string: login.hostname)
                if loginHostURL?.baseDomain == breach.domain {
                    print("compareToBreaches(): breach: \(breach.domain)")

                    // date check
                    let pwLastChanged = Date(timeIntervalSince1970: TimeInterval(login.timePasswordChanged))

                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd"
                    if let breachDate = dateFormatter.date(from: breach.breachDate), pwLastChanged < breachDate {
                        print("compareToBreaches(): ⚠️ password exposed ⚠️: \(breach.breachDate)")
                        result.append(login)
                    }
                }
            }
        }
        print("compareToBreaches(): fin")
        return Maybe(success: result)
    }
}
