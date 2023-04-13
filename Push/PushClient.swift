// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import SwiftyJSON

protocol PushClient {
    func register(_ apnsToken: String,
                  completion: @escaping (PushRegistration?) -> Void)

    func unregister(_ credentials: PushRegistration,
                    completion: @escaping () -> Void)
}

public class PushClientImplementation: PushClient {
    /// Bug 1364403 – This is to be put into the push registration
    private let apsEnvironment: [String: Any] = [
        "mutable-content": 1,
        "alert": [
            "title": " ",
            "body": " "
        ],
    ]

    private let endpointURL: NSURL
    private let experimentalMode: Bool
    private let api: PushRegistrationAPI

    public init(endpointURL: NSURL,
                experimentalMode: Bool = false,
                pushRegistrationAPI: PushRegistrationAPI = PushRegistrationAPIImplementation()) {
        self.endpointURL = endpointURL
        self.experimentalMode = experimentalMode
        self.api = pushRegistrationAPI
    }
}

// MARK: - PushClient
public extension PushClientImplementation {
    func register(_ apnsToken: String,
                  completion: @escaping (PushRegistration?) -> Void) {
        let registerURL = endpointURL.appendingPathComponent("registration")!
        var mutableURLRequest = URLRequest(url: registerURL)
        mutableURLRequest.httpMethod = HTTPMethod.post.rawValue

        mutableURLRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let parameters: [String: Any]
        if experimentalMode {
            parameters = [
                "token": apnsToken,
                "aps": apsEnvironment,
            ]
        } else {
            parameters = ["token": apnsToken]
        }

        mutableURLRequest.httpBody = JSON(parameters).stringify()?.utf8EncodedData

        api.fetchPushRegistration(request: mutableURLRequest) { result in
            if case .success(let push) = result {
                completion(push)
            } else {
                completion(nil)
            }
        }
    }

    func unregister(_ credentials: PushRegistration,
                    completion: @escaping () -> Void) {
        // DELETE /v1/{type}/{app_id}/registration/{uaid}
        let unregisterURL = endpointURL.appendingPathComponent("registration/\(credentials.uaid)")

        var mutableURLRequest = URLRequest(url: unregisterURL!)
        mutableURLRequest.httpMethod = HTTPMethod.delete.rawValue
        mutableURLRequest.addValue("Bearer \(credentials.secret)", forHTTPHeaderField: "Authorization")

        api.fetchPushRegistration(request: mutableURLRequest) { _ in
            completion()
        }
    }
}
