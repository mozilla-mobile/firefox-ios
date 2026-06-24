// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
@preconcurrency import GCDWebServers
import Shared

protocol WebServerProtocol {
    var server: GCDWebServer { get }
    @discardableResult
    func start() throws -> Bool
    /// Starts the server on the serial lifecycle queue if it isn't already running.
    func startIfNeeded()
    /// Stops the server on the serial lifecycle queue, off the main thread. `completion`,
    /// if provided, runs on the main queue once the server has stopped.
    func stop(completion: (@Sendable () -> Void)?)
}

/// FIXME: FXIOS-13989 Make truly thread safe
/// NOTE: FXIOS-14560 -- Be careful; `@MainActor` will cause crashes with GCDWebServer dependency.
final class WebServer: WebServerProtocol, @unchecked Sendable {
    static let sharedInstance = WebServer()

    private let logger: Logger

    let server = GCDWebServer()

    var base: String {
        return "http://localhost:\(server.port)"
    }

    /// The private credentials for accessing resources on this Web server.
    let credentials: URLCredential

    /// A random, transient token used for authenticating requests.
    /// Other apps are able to make requests to our local Web server,
    /// so this prevents them from accessing any resources.
    fileprivate let sessionToken = UUID().uuidString

    /// Serializes all GCDWebServer start/stop calls. GCDWebServer is not thread-safe,
    /// so funneling lifecycle operations through one serial queue (off the main thread)
    /// guarantees a start and a stop can never run concurrently, which would otherwise
    /// race during a background-to-foreground transition.
    private let lifecycleQueue = DispatchQueue(label: "org.mozilla.ios.WebServer.lifecycle")

    init(logger: Logger = DefaultLogger.shared) {
        credentials = URLCredential(user: sessionToken, password: "", persistence: .forSession)
        self.logger = logger
    }

    @discardableResult
    func start() throws -> Bool {
        if !server.isRunning {
            try server.start(options: [
                GCDWebServerOption_Port: AppInfo.webserverPort,
                GCDWebServerOption_BindToLocalhost: true,
                GCDWebServerOption_AutomaticallySuspendInBackground: false, // done by the app in AppDelegate
                GCDWebServerOption_AuthenticationMethod: GCDWebServerAuthenticationMethod_Basic,
                GCDWebServerOption_AuthenticationAccounts: [sessionToken: ""]
            ])
        }
        return server.isRunning
    }

    func startIfNeeded() {
        lifecycleQueue.async { [weak self] in
            guard let self, !self.server.isRunning else { return }
            do {
                try self.start()
            } catch {
                self.logger.log("Failed to start web server: \(error)",
                                level: .warning,
                                category: .webview)
            }
        }
    }

    func stop(completion: (@Sendable () -> Void)? = nil) {
        lifecycleQueue.async { [server] in
            server.stop()
            guard let completion else { return }
            DispatchQueue.main.async(execute: completion)
        }
    }

    /// Convenience method to register a dynamic handler. Will be mounted at $base/$module/$resource
    func registerHandlerForMethod(
        _ method: String,
        module: String,
        resource: String,
        handler: @escaping @MainActor (
            _ request: GCDWebServerRequest?,
            _ responseCompletion: @escaping @Sendable (GCDWebServerResponse?) -> Void
        ) -> Void
    ) {
        server.addHandler(
            forMethod: method,
            path: "/\(module)/\(resource)",
            request: GCDWebServerRequest.self,
            asyncProcessBlock: { request, completion in
                // Prevent serving content if the requested host isn't a safelisted local host.
                guard InternalURL.isValid(url: request.url) else {
                    completion(GCDWebServerResponse(statusCode: 403))
                    return
                }

                // Hop to the MainActor for the actual handler logic
                ensureMainThread {
                    handler(request) { response in
                        // Call GCDWebServer's completion when the handler is done
                        completion(response)
                    }
                }
            }
        )
    }

    /// Convenience method to register a resource in the main bundle. Will be mounted at $base/$module/$resource
    func registerMainBundleResource(_ resource: String, module: String) {
        if let path = Bundle.main.path(forResource: resource, ofType: nil) {
            server.addGETHandler(
                forPath: "/\(module)/\(resource)",
                filePath: path,
                isAttachment: false,
                cacheAge: UInt.max,
                allowRangeRequests: true
            )
        }
    }

    /// Convenience method to register all resources in the main bundle of a specific type.
    /// Will be mounted at $base/$module/$resource
    func registerMainBundleResourcesOfType(_ type: String, module: String) {
        for path: String in Bundle.paths(forResourcesOfType: type, inDirectory: Bundle.main.bundlePath) {
            if let resource = NSURL(string: path)?.lastPathComponent {
                server.addGETHandler(
                    forPath: "/\(module)/\(resource)",
                    filePath: path as String,
                    isAttachment: false,
                    cacheAge: UInt.max,
                    allowRangeRequests: true
                )
            } else {
                logger.log("Unable to locate resource at path: '\(path)'",
                           level: .warning,
                           category: .webview)
            }
        }
    }

    /// Return a full url, as a string, for a resource in a module. No check is done
    /// to find out if the resource actually exist.
    func URLForResource(_ resource: String, module: String) -> String {
        return "\(base)/\(module)/\(resource)"
    }

    func baseReaderModeURL() -> String {
        return WebServer.sharedInstance.URLForResource("page", module: "reader-mode")
    }
}
