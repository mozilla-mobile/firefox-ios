/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Alamofire
import Shared
import JSONSchema
import Deferred

// MARK: Ping Centre Client
public protocol PingCentreClient {
    func sendPing(data: [String: AnyObject], validate: Bool) -> Success
}

// Neat trick to have default parameters for protocol methods while still being able to lean on the compiler
// for adherence to the protocol.
extension PingCentreClient {
    func sendPing(data: [String: AnyObject], validate: Bool = true) -> Success {
        return sendPing(data, validate: validate)
    }
}

public struct PingCentre {
    public static func clientForTopic(topic: PingCentreTopic, clientID: String) -> PingCentreClient {
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
    public let error: ErrorType
    public var description: String {
        return "Failed to serialize JSON ping into NSData format -- \(error)"
    }
}

enum Endpoint {
    case Staging
    case Production

    var url: NSURL {
        switch self {
        case .Staging:
            return NSURL(string: "https://onyx_tiles.stage.mozaws.net/v3/links/ping-centre")!
        case .Production:
            return NSURL(string: "https://tiles.services.mozilla.com/v3/links/ping-centre")!
        }
    }
}

class DefaultPingCentreImpl: PingCentreClient {
    private let topic: PingCentreTopic
    private let clientID: String
    private let endpoint: Endpoint
    private let manager: Alamofire.Manager

    private let validationQueue: dispatch_queue_t
    private static let queueLabel = "org.mozilla.pingcentre.validationQueue"

    init(topic: PingCentreTopic, endpoint: Endpoint, clientID: String,
         validationQueue: dispatch_queue_t = dispatch_queue_create(queueLabel, nil),
         manager: Alamofire.Manager = Alamofire.Manager()) {
        self.topic = topic
        self.clientID = clientID
        self.endpoint = endpoint
        self.manager = manager
        self.validationQueue = validationQueue
    }

    func sendPing(data: [String: AnyObject], validate: Bool = true) -> Success {
        var payload = data
        payload["topic"] = topic.name
        payload["client_id"] = clientID

        return (validate ? validatePayload(payload, schema: topic.schema) : succeed())
            >>> { return self.sendPayload(payload) }
    }

    private func sendPayload(payload: [String: AnyObject]) -> Success {
        let deferred = Deferred<Maybe<()>>()
        let request = NSMutableURLRequest(URL: endpoint.url)
        request.HTTPMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.HTTPBody = try NSJSONSerialization.dataWithJSONObject(payload, options: [])
        } catch let e {
            deferred.fill(Maybe(failure: PingJSONError(error: e)))
            return deferred
        }
        
        self.manager.request(request)
                    .validate(statusCode: 200..<300)
                    .response(queue: dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) { _, _, _, error in
            if let e = error {
                NSLog("Failed to send ping to ping centre -- topic: \(self.topic.name), error: \(e)")
                deferred.fill(Maybe(failure: e))
                return 
            }
            deferred.fill(Maybe(success: ()))
        }
        return deferred
    }

    private func validatePayload(payload: [String: AnyObject], schema: Schema) -> Success {
        return deferDispatchAsync(validationQueue) {
            let errors = schema.validate(payload).errors ?? []
            guard errors.isEmpty else {
                return deferMaybe(PingValidationError(errors: errors))
            }
            return succeed()
        }
    }
}
