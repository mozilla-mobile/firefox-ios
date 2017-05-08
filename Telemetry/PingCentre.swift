/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Alamofire
import Shared
import JSONSchema
import Deferred

// MARK: Ping Centre Client
public protocol PingCentreClient {
    @discardableResult func sendPing(_ data: [String: Any], validate: Bool) -> Success
}

/*
 * A Ping Centre Topic has a name and an associated JSON schema describing the ping data.
 */
public struct PingCentreTopic {
    public let name: String
    public let schema: Schema
    public init(name: String, schema: Schema) {
        self.name = name
        self.schema = schema
    }
}

public struct PingCentre {
    public static func clientForTopic(_ topic: PingCentreTopic, clientID: String) -> PingCentreClient {
        guard !AppConstants.IsRunningTest else {
            return DefaultPingCentreImpl(topic: topic, endpoint: .staging, clientID: clientID)
        }

        switch AppConstants.BuildChannel {
        case .developer:
            return DefaultPingCentreImpl(topic: topic, endpoint: .staging, clientID: clientID)
        case .beta:
            fallthrough
        case .release:
            return DefaultPingCentreImpl(topic: topic, endpoint: .production, clientID: clientID)
        }
    }
}

public struct PingValidationError: MaybeErrorType {
    public let errors: [String]
    public var description: String {
        return "Ping JSON validation failed with the following errors: \(errors)"
    }
}

public struct PingJSONError: MaybeErrorType {
    public let error: Error
    public var description: String {
        return "Failed to serialize JSON ping into NSData format -- \(error)"
    }
}

enum Endpoint {
    case staging
    case production

    var url: URL {
        switch self {
        case .staging:
            return URL(string: "https://onyx_tiles.stage.mozaws.net/v3/links/ping-centre")!
        case .production:
            return URL(string: "https://tiles.services.mozilla.com/v3/links/ping-centre")!
        }
    }
}

class DefaultPingCentreImpl: PingCentreClient {
    fileprivate let topic: PingCentreTopic
    fileprivate let clientID: String
    fileprivate let endpoint: Endpoint
    fileprivate let manager: SessionManager

    fileprivate let validationQueue: DispatchQueue
    fileprivate static let queueLabel = "org.mozilla.pingcentre.validationQueue"

    init(topic: PingCentreTopic, endpoint: Endpoint, clientID: String,
         validationQueue: DispatchQueue = DispatchQueue(label: queueLabel),
         manager: SessionManager = SessionManager()) {
        self.topic = topic
        self.clientID = clientID
        self.endpoint = endpoint
        self.manager = manager
        self.validationQueue = validationQueue
    }

    public func sendPing(_ data: [String: Any], validate: Bool) -> Success {
        var payload = data
        payload["topic"] = topic.name
        payload["client_id"] = clientID

        return (validate ? validatePayload(payload, schema: topic.schema) : succeed())
            >>> { return self.sendPayload(payload) }
    }

    fileprivate func sendPayload(_ payload: [String: Any]) -> Success {
        let deferred = Deferred<Maybe<()>>()
        var request = URLRequest(url: endpoint.url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])
        } catch let e {
            deferred.fill(Maybe(failure: PingJSONError(error: e)))
            return deferred
        }

        self.manager.request(request as URLRequestConvertible)
            .validate(statusCode: 200..<300)
            .response(queue: DispatchQueue.global()) { (response) in
                if let e = response.error {
                    NSLog("Failed to send ping to ping centre -- topic: \(self.topic.name), error: \(e)")
                    deferred.fill(Maybe(failure: e as MaybeErrorType))
                    return
                }
                deferred.fill(Maybe(success: ()))
        }
        return deferred
    }

    fileprivate func validatePayload(_ payload: [String: Any], schema: Schema) -> Success {
        return deferDispatchAsync(validationQueue) {
            let errors = schema.validate(payload).errors ?? []
            guard errors.isEmpty else {
                return deferMaybe(PingValidationError(errors: errors))
            }
            return succeed()
        }
    }
}
