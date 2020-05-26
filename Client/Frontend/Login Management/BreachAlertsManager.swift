//
//  BreachAlertsManager.swift
//  Client
//
//  Created by Vanna Phong on 5/21/20.
//  Copyright © 2020 Mozilla. All rights reserved.
//

import Foundation
import Storage // or whichever module has the LoginsRecord class

/* principles: modular and flexible */
struct EndpointResponse: Codable {
    var results: [BreachRecord]
}
struct BreachRecord: Codable {
    var name: String
    var title: String
    var domain: String
    var breachDate: String
    var addedDate: String
    var modifiedDate: String
    var pwnCount: Int
    var description: String
    var logoPath: String
    var isVerified: Bool
    var isFabricated: Bool
    var isSensitive: Bool
    var isRetired: Bool
    var isSpamList: Bool
    var logoUrl: String?
}


// class so that we don't make copies of large vars that might slow things down
public class BreachAlertsManager {
    //
    // MARK: - Constants
    //
    let urlSession = URLSession(configuration: .default)

    //
    // MARK: - Variables and Properties
    //
    var dataTask: URLSessionDataTask?
    var endpointComponents = URLComponents()
    var breaches: [BreachRecord] = []

    //
    // MARK: - Internal Methods
    //
    /**
     Loads breaches from Monitor endpoint.
     */
    public func loadBreaches() {
        guard let url = URL(string: "https://monitor.firefox.com/hibp/breaches") else {
            return
        }

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
                let key = keys.last! // make sure array not empty

                // string manipulation
                let keyStr = key.stringValue
                let pascalToCamel = keyStr.prefix(1).lowercased() + keyStr.dropFirst()

                // CodingKey conformity
                let codingKeyType = type(of: key)
                return codingKeyType.init(stringValue: pascalToCamel)!

            }

            if let decoded = try? decoder.decode([BreachRecord].self, from: data) {
                DispatchQueue.main.async {
                    self.breaches = decoded
                }

            }

        }

        dataTask?.resume()

    }


    /**
     Compares a list of logins to a list of breaches and returns breached logins.
        @param logins: an array of Any login information classes.
            Any is used for flexibility - if this file is placed in another project,
            the function will be able to take any object structure in.
        !!! can be changed to [LoginRecords] or Deferred variants

     ...for now, tries to read/return any object passed from LoginsListVC
    **/
    func compareBreached(_ logins: [Any])  {


        for entry in logins {
            let login = entry as! LoginRecord; // typecast for ease of use
//            guard login.hasMalformedHostname else {
//                return
//            }

            for breach in breaches {
                let loginHostURL = URL(string: login.hostname)

                if loginHostURL?.baseDomain == breach.domain {
                    print("compareBreached(): breach: \(breach.domain)")
                }
            }

        }

        print("compareBreached(): fin")

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
