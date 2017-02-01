/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Alamofire
import Shared
import JSONSchema
import Deferred

// MARK: Ping Centre Client
public protocol PingCentreClient {
    func sendPing(_ data: [String: AnyObject], validate: Bool) -> Success
}

// Neat trick to have default parameters for protocol methods while still being able to lean on the compiler
// for adherence to the protocol.
extension PingCentreClient {
    func sendPing(_ data: [String: AnyObject], validate: Bool = true) -> Success {
        return sendPing(data, validate: validate)
    }
}

public struct PingCentre {
    public static func clientForTopic(_ topic: PingCentreTopic, clientID: String) -> PingCentreClient {
        switch AppConstants.BuildChannel {
        case .Developer:
            fallthrough
        case .Nightly:
            fallthrough
        case .Aurora:
            fallthrough
        case .Beta:
            return DefaultPingCentreImpl(topic: topic, endpoint: .Staging, clientID: clientID)
        case .Release:
            return DefaultPingCentreImpl(topic: topic, endpoint: .Production, clientID: clientID)
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
    fileprivate let manager: Alamofire.Manager

    fileprivate let validationQueue: DispatchQueue
    fileprivate static let queueLabel = "org.mozilla.pingcentre.validationQueue"

    init(topic: PingCentreTopic, endpoint: Endpoint, clientID: String,
         validationQueue: DispatchQueue = dispatch_queue_create(queueLabel, nil),
         manager: Alamofire.Manager = Alamofire.Manager()) {
        self.topic = topic
        self.clientID = clientID
        self.endpoint = endpoint
        self.manager = manager
        self.validationQueue = validationQueue
    }

    func sendPing(_ data: [String: AnyObject], validate: Bool = true) -> Success {
        var payload = data
        payload["topic"] = topic.name as AnyObject?
        payload["client_id"] = clientID as AnyObject?

        return (validate ? validatePayload(payload, schema: topic.schema) : succeed())
            >>> { return self.sendPayload(payload) }
    }

    fileprivate func sendPayload(_ payload: [String: AnyObject]) -> Success {
        let deferred = Deferred<Maybe<()>>()
        let request = NSMutableURLRequest(url: endpoint.url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])
        } catch let e {
            deferred.fill(Maybe(failure: PingJSONError(error: e)))
            return deferred
        }
        
        self.manager.request(request)
                    .validate(statusCode: 200..<300)
                    .response(queue: dispatch_get_global_queue(DispatchQueue.GlobalQueuePriority.default, 0)) { _, _, _, error in
            if let e = error {
                NSLog("Failed to send ping to ping centre -- topic: \(self.topic.name), error: \(e)")
                deferred.fill(Maybe(failure: e))
                return 
            }
            deferred.fill(Maybe(success: ()))
        }
        return deferred
    }

    fileprivate func validatePayload(_ payload: [String: AnyObject], schema: Schema) -> Success {
        return deferDispatchAsync(validationQueue) {
            let errors = schema.validate(payload).errors ?? []
            guard errors.isEmpty else {
                return deferMaybe(PingValidationError(errors: errors))
            }
            return succeed()
        }
    }
}
