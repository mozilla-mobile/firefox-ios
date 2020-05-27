//
//  BreachAlertsManager.swift
//  Client
//
//  Created by Vanna Phong on 5/21/20.
//  Copyright © 2020 Mozilla. All rights reserved.
//

import Foundation
import Storage // or whichever module has the LoginsRecord class

/// Breach structure decoded from JSON
struct BreachRecord: Codable {
    var name: String
    var title: String
    var domain: String
    var breachDate: String
    var addedDate: String
    var modifiedDate: String
    var pwnCount: Int
    var description: String
    var isVerified: Bool
    var isFabricated: Bool
}

/// A manager for the user's breached login information, if any.
public class BreachAlertsManager {

    //
    // MARK: - Variables and Properties
    //
    fileprivate var dataTask: URLSessionDataTask?
    fileprivate var endpointURL = "https://monitor.firefox.com/hibp/breaches"
    var breaches: [BreachRecord] = []

    //
    // MARK: - Internal Methods
    //
    /// Loads breaches from Monitor endpoint.
    public func loadBreaches() {
        guard let url = URL(string: endpointURL) else {
            return
        }

        print("loadBreaches(): called")

        dataTask?.cancel()

        dataTask = URLSession.shared.dataTask(with: url) { data, response, error in
            guard self.validatedHTTPResponse(response) != nil else {
                print("loadBreaches(): invalid HTTP response")
                return
            }

            if let error = error {
                print("loadBreaches(): error: \(error)")
                return
            }

            guard let data = data, !data.isEmpty else {
                print("loadBreaches(): invalid data")
                return
            }

            let decoder = JSONDecoder()

            // .convertFromPascalCase
            decoder.keyDecodingStrategy = .custom { keys in
                if let key = keys.last {

                    // string manipulation
                    let keyStr = key.stringValue
                    let pascalToCamel = keyStr.prefix(1).lowercased() + keyStr.dropFirst()

                    // CodingKey conformity
                    let codingKeyType = type(of: key)
                    return codingKeyType.init(stringValue: pascalToCamel)!
                }

            }

            if let decoded = try? decoder.decode([BreachRecord].self, from: data) {
                DispatchQueue.main.async {
                    self.breaches = decoded
                }
            }
        }

        dataTask?.resume()

    }

    /// Compares a list of logins to a list of breaches and returns breached logins.
    ///    - Parameters:
    ///         - logins: a list of logins to compare breaches to
    func compareToBreaches(_ logins: [LoginRecord])  {

        for login in logins {
            for breach in self.breaches {
                // host check
                let loginHostURL = URL(string: login.hostname)
                if loginHostURL?.baseDomain == breach.domain {
                    print("compareToBreaches(): breach: \(breach.domain)")
                }

                // date check
                let pwLastChanged = Date.init(timeIntervalSince1970: TimeInterval(login.timePasswordChanged))

                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                let breachDate = dateFormatter.date(from: breach.breachDate)

                if let breachDate = breachDate, pwLastChanged < breachDate {
                    print("compareToBreaches(): ⚠️ password exposed ⚠️: \(breach.breachDate)")
                }

            }

        }

        print("compareToBreaches(): fin")
        }

    }


    //
    // MARK: - Internal Methods
    //
    // From firefox-ios/Shared/NetworkUtils.swift
    private func validatedHTTPResponse(_ response: URLResponse?, contentType: String? = nil, statusCode: Range<Int>?  = nil) -> HTTPURLResponse? {
        if let response = response as? HTTPURLResponse {
            if let range = statusCode {
                return range.contains(response.statusCode) ? response :  nil
            }
            if let type = contentType {
                if let responseType = response.allHeaderFields["Content-Type"] as? String {
                    return responseType.contains(type) ? response : nil
                }
                return nil
            }
            return response
        }
        return nil
    }
}
