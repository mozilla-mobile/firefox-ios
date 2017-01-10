/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Alamofire
import Shared

private let OnyxStagingConfiguration = OnyxClientConfiguration(serverURL: "https://onyx_tiles.stage.mozaws.net".asURL!, version: 3)
private let OnyxProductionConfiguration = OnyxClientConfiguration(serverURL: "https://tiles.services.mozilla.com".asURL!, version: 3)

struct OnyxTelemetry {
    static private let configuration: OnyxClientConfiguration = {
        switch AppConstants.BuildChannel {
            case .Nightly:  return OnyxProductionConfiguration
            case .Beta:     return OnyxProductionConfiguration
            case .Release:  return OnyxProductionConfiguration
            default:        return OnyxProductionConfiguration
        }
    }()

    static var sharedClient = OnyxClient(configuration: configuration)
}

public enum OnyxEndpoint: String {
    case activityStream = "links/activity-stream-mobile"
}

/// Properties and settings for setting up a Onyx client.
public struct OnyxClientConfiguration {
    public let serverURL: NSURL
    public let version: Int

    public init(serverURL: NSURL, version: Int) {
        self.serverURL = serverURL
        self.version = version
    }

    private func urlForEndpoint(endpoint: OnyxEndpoint) -> NSURL? {
        let components = NSURLComponents(URL: serverURL, resolvingAgainstBaseURL: false)!
        components.path = "/v\(version)/\(endpoint.rawValue)"
        return components.URL!
    }
}

/// A simple client that sends pings to the configured Onyx Server
public class OnyxClient {
    private let configuration: OnyxClientConfiguration

    public init(configuration: OnyxClientConfiguration) {
        self.configuration = configuration
    }

    /// Sends the given event ping to the Onyx server.
    ///
    /// - parameter ping: Event ping to send to the server.
    public func sendEventPing(ping: EventPing, toEndpoint endpoint: OnyxEndpoint) {
        sendPing(ping, toEndpoint: endpoint)
    }

    /// Returns and begins a handle to an Onyx session which tracks duration.
    ///
    /// - returns: An OnyxSession object that has begun.
    public func beginSession() -> OnyxSession {
        let session = OnyxSession()
        session.start()
        return session
    }

    /// Finishes the given session and sends the associated session ping to the Onyx server.
    ///
    /// - parameter session:        OnyxSession object.
    /// - parameter sendToEndpoint: Endpoint to send Session ping to.
    public func endSession(session: OnyxSession, sendToEndpoint endpoint: OnyxEndpoint) {
        session.end()
        guard let ping = session.ping else {
            return
        }
        self.sendPing(ping, toEndpoint: endpoint)
    }

    private func sendPing(ping: OnyxPing, toEndpoint endpoint: OnyxEndpoint) {
        guard let pingURL = configuration.urlForEndpoint(endpoint) else {
            return
        }

        let payload: NSData
        do {
            payload = try ping.asPayload()
        } catch let e as NSError {
            return
        }

        self.sendRequest(payload, url: pingURL)
    }

    private func sendRequest(payload: NSData, url: NSURL) {
        let request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = "POST"
        request.HTTPBody = payload
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        Alamofire.request(request).responseJSON { response in
        }
    }
}
