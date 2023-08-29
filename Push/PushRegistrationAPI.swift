// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import SwiftyJSON

public typealias PushRegistrationResult = Result<PushRegistration, Error>

public protocol PushRegistrationAPI {
    func fetchPushRegistration(request: URLRequest,
                               completion: @escaping (PushRegistrationResult?) -> Void)

    func executeRequest(_ request: URLRequest,
                        completion: @escaping () -> Void)
}

public class PushRegistrationAPIImplementation: PushRegistrationAPI {
    private static let PushClientErrorDomain = "org.mozilla.push.error"
    private let PushClientUnknownError = NSError(domain: PushRegistrationAPIImplementation.PushClientErrorDomain,
                                                 code: 999,
                                                 userInfo: [NSLocalizedDescriptionKey: "Invalid server response"])

    private lazy var urlSession = makeURLSession(userAgent: UserAgent.fxaUserAgent,
                                                 configuration: URLSessionConfiguration.ephemeral)

    public init() {}

    public func fetchPushRegistration(request: URLRequest,
                                      completion: @escaping (PushRegistrationResult?) -> Void) {
        fetchJSONData(request: request) { result in
            guard case .success(let json) = result,
                  let pushRegistration = PushRegistration.from(json: json)
            else {
                completion(.failure(PushClientError.Local(self.PushClientUnknownError)))
                return
            }

            completion(.success(pushRegistration))
        }
    }

    public func executeRequest(_ request: URLRequest,
                               completion: @escaping () -> Void) {
        fetchJSONData(request: request) { _ in
            completion()
        }
    }

    private func fetchJSONData(request: URLRequest,
                               completion: @escaping (Result<JSON, Error>) -> Void) {
        urlSession.dataTask(with: request) { (data, response, error) in
            if let error = error {
                completion(.failure(PushClientError.Local(error)))
                return
            }

            guard validatedHTTPResponse(response, contentType: "application/json") != nil,
                  let data = data,
                  !data.isEmpty
            else {
                let error = PushClientError.Local(self.PushClientUnknownError)
                completion(.failure(error))
                return
            }

            do {
                let json = try JSON(data: data)
                if let remoteError = PushRemoteError.from(json: json) {
                    completion(.failure(PushClientError.Remote(remoteError)))
                    return
                }
                completion(.success(json))
            } catch {
                completion(.failure(PushClientError.Local(error)))
                return
            }
        }.resume()
    }
}
