/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Alamofire
import Deferred
import Shared

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

    public static func fromJSON(json: JSON) -> PushRemoteError? {
        guard let code = json["code"].asInt,
              let errno = json["errno"].asInt,
              let error = json["error"].asString else {
            return nil
        }

        let message = json["message"].asString
        return PushRemoteError(code: code, errno: errno, error: error, message: message)
    }
}

public enum PushClientError: MaybeErrorType {
    case Remote(PushRemoteError)
    case Local(NSError)

    public var description: String {
        switch self {
        case let .Remote(error):
            let errorString = error.error
            let messageString = error.message ?? ""
            return "<FxAClientError.Remote \(error.code)/\(error.errno): \(errorString) (\(messageString))>"
        case let .Local(error):
            return "<FxAClientError.Local Error Domain=\(error.domain) Code=\(error.code) \"\(error.localizedDescription)\">"
        }
    }
}

public class PushClient {
    let endpointURL: NSURL

    lazy private var alamofire: Alamofire.Manager = {
        // TODO: User Agent?
        let ua = UserAgent.fxaUserAgent
        let configuration = NSURLSessionConfiguration.ephemeralSessionConfiguration()
        return Alamofire.Manager.managerWithUserAgent(ua, configuration: configuration)
    }()

    public init(endpointURL: NSURL) {
        self.endpointURL = endpointURL
    }

}

public extension PushClient {
    public func register(apnsToken: String) -> Deferred<Maybe<PushRegistration>> {
        //  POST /v1/{type}/{app_id}/registration
        let registerURL = endpointURL.URLByAppendingPathComponent("registration")!

        let mutableURLRequest = NSMutableURLRequest(URL: registerURL)
        mutableURLRequest.HTTPMethod = Method.POST.rawValue

        mutableURLRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let parameters = ["token": apnsToken]
        mutableURLRequest.HTTPBody = JSON(parameters).toString().utf8EncodedData

        return sendRequest(mutableURLRequest) >>== { json in
            guard let response = PushRegistration.fromJSON(json) else {
                return deferMaybe(PushClientError.Local(PushClientUnknownError))
            }

            return deferMaybe(response)
        }
    }

    public func updateUAID(apnsToken: String, creds: PushRegistration) -> Deferred<Maybe<PushRegistration>> {
        //  PUT /v1/{type}/{app_id}/registration/{uaid}
        let registerURL = endpointURL.URLByAppendingPathComponent("registration/\(creds.uaid)")!
        let mutableURLRequest = NSMutableURLRequest(URL: registerURL)

        mutableURLRequest.HTTPMethod = Method.PUT.rawValue
        mutableURLRequest.addValue("Bearer \(creds.secret)", forHTTPHeaderField: "Authorization")

        mutableURLRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let parameters = ["token": apnsToken]
        mutableURLRequest.HTTPBody = JSON(parameters).toString().utf8EncodedData

        return sendRequest(mutableURLRequest) >>== { json in
            guard let response = PushRegistration.fromJSON(json) else {
                return deferMaybe(PushClientError.Local(PushClientUnknownError))
            }
            return deferMaybe(response)
        }
    }

    public func unregister(creds: PushRegistration) -> Success {
        //  DELETE /v1/{type}/{app_id}/registration/{uaid}
        let unregisterURL = endpointURL.URLByAppendingPathComponent("registration/\(creds.uaid)")

        let mutableURLRequest = NSMutableURLRequest(URL: unregisterURL!)
        mutableURLRequest.HTTPMethod = Method.DELETE.rawValue
        mutableURLRequest.addValue("Bearer \(creds.secret)", forHTTPHeaderField: "Authorization")

        return sendRequest(mutableURLRequest) >>> succeed
    }
}

/// Utilities
extension PushClient {
    private func sendRequest(request: NSURLRequest) -> Deferred<Maybe<JSON>> {
        log.info("\(request.HTTPMethod!) \(request.URLString)")
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
                    
                    if let remoteError = PushRemoteError.fromJSON(json) {
                        return deferred.fill(Maybe(failure: PushClientError.Remote(remoteError)))
                    }

                    deferred.fill(Maybe(success: json))
                }
        }

        return deferred
    }
}
