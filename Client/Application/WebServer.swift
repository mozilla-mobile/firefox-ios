/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import GCDWebServers

class WebServer {
    static let WebServerSharedInstance = WebServer()

    class var sharedInstance: WebServer {
        return WebServerSharedInstance
    }

    let server: GCDWebServer = GCDWebServer()

    var base: String {
        return "http://localhost:\(server.port)"
    }

    func start() throws -> Bool{
        if !server.isRunning {
            try server.start(options: [GCDWebServerOption_Port: 6571, GCDWebServerOption_BindToLocalhost: true, GCDWebServerOption_AutomaticallySuspendInBackground: true])
        }
        return server.isRunning
    }

    /// Convenience method to register a dynamic handler. Will be mounted at $base/$module/$resource
    func registerHandler(forMethod method: String, module: String, resource: String, handler: (request: GCDWebServerRequest?) -> GCDWebServerResponse!) {
        // Prevent serving content if the requested host isn't a whitelisted local host.
        let wrappedHandler = {(request: GCDWebServerRequest!) -> GCDWebServerResponse! in
            guard request.URL.isLocal else {
                return GCDWebServerResponse(statusCode: 403)
            }

            return handler(request: request)
        }

        server.addHandler(forMethod: method, path: "/\(module)/\(resource)", request: GCDWebServerRequest.self, processBlock: wrappedHandler)
    }

    /// Convenience method to register a resource in the main bundle. Will be mounted at $base/$module/$resource
    func registerMainBundleResource(_ resource: String, module: String) {
        if let path = Bundle.main.pathForResource(resource, ofType: nil) {
            server.addGETHandler(forPath: "/\(module)/\(resource)", filePath: path, isAttachment: false, cacheAge: UInt.max, allowRangeRequests: true)
        }
    }

    /// Convenience method to register all resources in the main bundle of a specific type. Will be mounted at $base/$module/$resource
    func registerMainBundleResources(ofType type: String, module: String) {
        for path: NSString in Bundle.pathsForResources(ofType: type, inDirectory: Bundle.main.bundlePath) {
            let resource = path.lastPathComponent
            server.addGETHandler(forPath: "/\(module)/\(resource)", filePath: path as String, isAttachment: false, cacheAge: UInt.max, allowRangeRequests: true)
        }
    }

    /// Return a full url, as a string, for a resource in a module. No check is done to find out if the resource actually exist.
    func URL(forResource: _ resource: String, module: String) -> String {
        return "\(base)/\(module)/\(resource)"
    }

    /// Return a full url, as an NSURL, for a resource in a module. No check is done to find out if the resource actually exist.
    func URL(forResource resource: String, module: String) -> URL {
        return URL(string: "\(base)/\(module)/\(resource)")!
    }

    func updateLocalURL(_ url: URL) -> URL? {
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        if components?.host == "localhost" && components?.scheme == "http" {
            components?.port = WebServer.sharedInstance.server.port
        }
        return components?.url
    }
}
