//
//  BreachAlertsManager.swift
//  Client
//
//  Created by Vanna Phong on 5/21/20.
//  Copyright © 2020 Mozilla. All rights reserved.
//

import Foundation
import Storage // or whichever module has the LoginsRecord class
import Shared // or whichever module has the Maybe class

/// Breach structure decoded from JSON
struct BreachRecord: Codable {
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
            if maybeData.isSuccess, let data = maybeData.successValue {
                let decoder = JSONDecoder()
                if let decoded = try? decoder.decode([BreachRecord].self, from: data) {
                    self.breaches = decoded
                    completion(Maybe(success: self.breaches))
                }
            } else {
                completion(Maybe(failure: BreachAlertsError(description: "failed to load breaches")))
            }
        }
    }

    /// Compares a list of logins to a list of breaches and returns breached logins.
    ///    - Parameters:
    ///         - logins: a list of logins to compare breaches to
    func compareToBreaches(_ logins: [LoginRecord])  {

        if self.breaches.count <= 0 {
            print("compareToBreaches(): empty breach list")
            return
        }

        // TODO: optimize this loop
        for login in logins {
            for breach in self.breaches {
                // host check
                let loginHostURL = URL(string: login.hostname)
                if loginHostURL?.baseDomain == breach.domain {
                    print("compareToBreaches(): breach: \(breach.domain)")

                    // date check
                    let pwLastChanged = Date.init(timeIntervalSince1970: TimeInterval(login.timePasswordChanged))

                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd"
                    let breachDate = dateFormatter.date(from: breach.breachDate)
                    print("compareToBreaches(): breach date: \(String(describing: breachDate))")

                    if let breachDate = breachDate, pwLastChanged < breachDate {
                        print("compareToBreaches(): ⚠️ password exposed ⚠️: \(breach.breachDate)")
                    }
                }
            }
        }
        print("compareToBreaches(): fin")
    }
}
