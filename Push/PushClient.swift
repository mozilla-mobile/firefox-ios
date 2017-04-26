/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Alamofire
import Deferred
import Shared
import SwiftyJSON

//public struct PushRemoteError {
//    static let MissingNecessaryCryptoKeys: Int32 = 101
//    static let InvalidURLEndpoint: Int32         = 102
//    static let ExpiredURLEndpoint: Int32         = 103
//    static let DataPayloadTooLarge: Int32        = 104
//    static let EndpointBecameUnavailable: Int32  = 105
//    static let InvalidSubscription: Int32        = 106
//    static let RouterTypeIsInvalid: Int32        = 108
//    static let InvalidAuthentication: Int32      = 109
//    static let InvalidCryptoKeysSpecified: Int32 = 110
//    static let MissingRequiredHeader: Int32      = 111
//    static let InvalidTTLHeaderValue: Int32      = 112
//    static let UnknownError: Int32               = 999
//}

public let PushClientErrorDomain = "org.mozilla.push.error"
private let PushClientUnknownError = NSError(domain: PushClientErrorDomain, code: 999,
                                             userInfo: [NSLocalizedDescriptionKey: "Invalid server response"])
private let log = Logger.browserLogger

public struct PushRemoteError {
    let code: Int
    let errno: Int
    let error: String
    let message: String?

    public static func from(json: JSON) -> PushRemoteError? {
        guard let code = json["code"].int,
              let errno = json["errno"].int,
              let error = json["error"].string else {
            return nil
        }

        let message = json["message"].string
        return PushRemoteError(code: code, errno: errno, error: error, message: message)
    }
}

public enum PushClientError: MaybeErrorType {
    case Remote(PushRemoteError)
    case Local(Error)

    public var description: String {
        switch self {
        case let .Remote(error):
            let errorString = error.error
            let messageString = error.message ?? ""
            return "<FxAClientError.Remote \(error.code)/\(error.errno): \(errorString) (\(messageString))>"
        case let .Local(error):
            return "<FxAClientError.Local Error \"\(error.localizedDescription)\">"
        }
    }
}

public class PushClient {
    let endpointURL: NSURL

    lazy fileprivate var alamofire: SessionManager = {
        let ua = UserAgent.fxaUserAgent
        let configuration = URLSessionConfiguration.ephemeral
        return SessionManager.managerWithUserAgent(ua, configuration: configuration)
    }()

    public init(endpointURL: NSURL) {
        self.endpointURL = endpointURL
    }

}

public extension PushClient {
    public func register(_ apnsToken: String) -> Deferred<Maybe<PushRegistration>> {
        //  POST /v1/{type}/{app_id}/registration
        let registerURL = endpointURL.appendingPathComponent("registration")!

        var mutableURLRequest = URLRequest(url: registerURL)
        mutableURLRequest.httpMethod = HTTPMethod.post.rawValue

        mutableURLRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let parameters = ["token": apnsToken]
        mutableURLRequest.httpBody = JSON(parameters).stringValue()?.utf8EncodedData

        return send(request: mutableURLRequest) >>== { json in
            guard let response = PushRegistration.from(json: json) else {
                return deferMaybe(PushClientError.Local(PushClientUnknownError))
            }

            return deferMaybe(response)
        }
    }

    public func updateUAID(_ apnsToken: String, withRegistration creds: PushRegistration) -> Deferred<Maybe<PushRegistration>> {
        //  PUT /v1/{type}/{app_id}/registration/{uaid}
        let registerURL = endpointURL.appendingPathComponent("registration/\(creds.uaid)")!
        var mutableURLRequest = URLRequest(url: registerURL)

        mutableURLRequest.httpMethod = HTTPMethod.put.rawValue
        mutableURLRequest.addValue("Bearer \(creds.secret)", forHTTPHeaderField: "Authorization")

        mutableURLRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let parameters = ["token": apnsToken]
        mutableURLRequest.httpBody = JSON(parameters).stringValue()?.utf8EncodedData

        return send(request: mutableURLRequest) >>== { json in
            return deferMaybe(creds)
        }
    }

    public func unregister(_ creds: PushRegistration) -> Success {
        //  DELETE /v1/{type}/{app_id}/registration/{uaid}
        let unregisterURL = endpointURL.appendingPathComponent("registration/\(creds.uaid)")

        var mutableURLRequest = URLRequest(url: unregisterURL!)
        mutableURLRequest.httpMethod = HTTPMethod.delete.rawValue
        mutableURLRequest.addValue("Bearer \(creds.secret)", forHTTPHeaderField: "Authorization")

        return send(request: mutableURLRequest) >>> succeed
    }
}

/// Utilities
extension PushClient {
    fileprivate func send(request: URLRequest) -> Deferred<Maybe<JSON>> {
        log.info("\(request.httpMethod!) \(request.url?.absoluteString ?? "nil")")
        let deferred = Deferred<Maybe<JSON>>()
        alamofire.request(request)
            .validate(contentType: ["application/json"])
            .responseJSON { response in
                // Don't cancel requests just because our client is deallocated.
                withExtendedLifetime(self.alamofire) {
                    let result = response.result
                    if let error = result.error {
                        return deferred.fill(Maybe(failure: PushClientError.Local(error)))
                    }

                    guard let data = response.data else {
                        return deferred.fill(Maybe(failure: PushClientError.Local(PushClientUnknownError)))
                    }

                    let json = JSON(data: data)
                    
                    if let remoteError = PushRemoteError.from(json: json) {
                        return deferred.fill(Maybe(failure: PushClientError.Remote(remoteError)))
                    }

                    deferred.fill(Maybe(success: json))
                }
        }

        return deferred
    }
}
