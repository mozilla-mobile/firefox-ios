// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import GCDWebServers

protocol WKEngineWebServerProtocol {
    var isRunning: Bool { get }

    @discardableResult
    func start() throws -> Bool
    func stop()

    func addTestHandler()
    func baseReaderModeURL() -> String

    func registerMainBundleResourcesOfType(_ type: String, module: String)
    func registerMainBundleResource(_ resource: String, module: String)
    func registerHandlerForMethod(
        _ method: String,
        module: String,
        resource: String,
        handler: @escaping (_ request: GCDWebServerRequest?) -> GCDWebServerResponse?
    )
}

class WKEngineWebServer: WKEngineWebServerProtocol {
    static let shared: WKEngineWebServerProtocol = WKEngineWebServer()

    private let logger: Logger
    private let server = GCDWebServer()
    private var base: String {
        return "http://localhost:\(server.port)"
    }

    /// The private credentials for accessing resources on this Web server.
    private let credentials: URLCredential

    /// A random, transient token used for authenticating requests.
    /// Other apps are able to make requests to our local Web server,
    /// so this prevents them from accessing any resources.
    private let sessionToken = UUID().uuidString

    var isRunning: Bool {
        server.isRunning
    }

    init(logger: Logger = DefaultLogger.shared) {
        credentials = URLCredential(user: sessionToken, password: "", persistence: .forSession)
        self.logger = logger
    }

    @discardableResult
    func start() throws -> Bool {
        if !server.isRunning {
            try server.start(options: [
                GCDWebServerOption_Port: WKEngineInfo.webserverPort,
                GCDWebServerOption_BindToLocalhost: true,
                GCDWebServerOption_AutomaticallySuspendInBackground: false, // done by the app in AppDelegate
                GCDWebServerOption_AuthenticationMethod: GCDWebServerAuthenticationMethod_Basic,
                GCDWebServerOption_AuthenticationAccounts: [sessionToken: ""]
            ])
        }
        return server.isRunning
    }

    func stop() {
        server.stop()
    }

    /// Convenience method to register a dynamic handler. Will be mounted at $base/$module/$resource
    func registerHandlerForMethod(
        _ method: String,
        module: String,
        resource: String,
        handler: @escaping (_ request: GCDWebServerRequest?) -> GCDWebServerResponse?
    ) {
        // Prevent serving content if the requested host isn't a safelisted local host.
        let wrappedHandler = {(request: GCDWebServerRequest?) -> GCDWebServerResponse? in
            guard let request = request,
                  WKInternalURL.isValid(url: request.url)
            else { return GCDWebServerResponse(statusCode: 403) }

            return handler(request)
        }
        server.addHandler(forMethod: method,
                          path: "/\(module)/\(resource)",
                          request: GCDWebServerRequest.self,
                          processBlock: wrappedHandler)
    }

    /// Convenience method to register a resource in the main bundle. Will be mounted at $base/$module/$resource
    func registerMainBundleResource(_ resource: String, module: String) {
        if let path = Bundle.main.path(forResource: resource, ofType: nil) {
            server.addGETHandler(forPath: "/\(module)/\(resource)",
                                 filePath: path,
                                 isAttachment: false,
                                 cacheAge: UInt.max,
                                 allowRangeRequests: true)
        }
    }

    /// Convenience method to register all resources in the main bundle of a specific type.
    /// Will be mounted at $base/$module/$resource
    func registerMainBundleResourcesOfType(_ type: String, module: String) {
        for path: String in Bundle.paths(forResourcesOfType: type, inDirectory: Bundle.main.bundlePath) {
            if let resource = NSURL(string: path)?.lastPathComponent {
                server.addGETHandler(forPath: "/\(module)/\(resource)",
                                     filePath: path as String,
                                     isAttachment: false,
                                     cacheAge: UInt.max,
                                     allowRangeRequests: true)
            } else {
                logger.log("Unable to locate resource at path: '\(path)'",
                           level: .warning,
                           category: .webview)
            }
        }
    }

    func baseReaderModeURL() -> String {
        return URLForResource("page", module: "reader-mode")
    }

    func addTestHandler() {
        // Add tracking protection check page
        server.addHandler(forMethod: "GET",
                          path: "/test-fixture/find-in-page-test.html",
                          request: GCDWebServerRequest.self) { (_: GCDWebServerRequest?) in
            let node = """
<span>  And the beast shall come forth surrounded by a roiling cloud of vengeance. \
The house of the unbelievers shall be razed and they shall be scorched to the earth. \
Their tags shall blink until the end of days. from The Book of Mozilla, 12:10 And the \
beast shall be made legion. Its numbers shall be increased a thousand thousand fold. The \
din of a million keyboards like unto a great storm shall cover the earth, and the followers \
of Mammon shall tremble. from The Book of Mozilla, 3:31 (Red Letter Edition) </span>
"""

            let repeatCount = 1000
            let textNodes = [String](repeating: node, count: repeatCount).reduce("", +)
            return GCDWebServerDataResponse(html: "<html><body>\(textNodes)</body></html>")
        }

        let htmlFixtures =  ["test-indexeddb-private",
                             "test-window-opener",
                             "test-password",
                             "test-password-submit",
                             "test-password-2",
                             "test-password-submit-2",
                             "empty-login-form",
                             "empty-login-form-submit",
                             "test-example",
                             "test-example-link",
                             "test-mozilla-book",
                             "test-mozilla-org",
                             "test-popup-blocker",
                             "test-user-agent"]
        htmlFixtures.forEach {
            addHTMLFixture(name: $0, server: server)
        }
    }

    // Make sure to add files to '/test-fixtures' directory in the source tree
    private func addHTMLFixture(name: String, server: GCDWebServer) {
        if let filePath = Bundle.main.path(forResource: "test-fixtures/\(name)", ofType: "html") {
            let fileHtml = try? String(contentsOfFile: filePath, encoding: .utf8)
            server.addHandler(forMethod: "GET",
                              path: "/test-fixture/\(name).html",
                              request: GCDWebServerRequest.self) { (request: GCDWebServerRequest?) in
                return GCDWebServerDataResponse(html: fileHtml!)
            }
        }
    }

    /// Return a full url, as a string, for a resource in a module.
    /// No check is done to find out if the resource actually exist.
    private func URLForResource(_ resource: String, module: String) -> String {
        return "\(base)/\(module)/\(resource)"
    }
}
