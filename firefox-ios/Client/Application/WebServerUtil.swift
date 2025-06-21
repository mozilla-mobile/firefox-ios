// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import GCDWebServers
import Shared

class WebServerUtil {
    private var readerModeHander: ReaderModeHandlersProtocol
    private var webServer: WebServerProtocol
    private var profile: Profile

    init(readerModeHander: ReaderModeHandlersProtocol = ReaderModeHandlers(),
         webServer: WebServer = WebServer.sharedInstance,
         profile: Profile) {
        self.readerModeHander = readerModeHander
        self.webServer = webServer
        self.profile = profile
    }

    func setUpWebServer() {
        guard !webServer.server.isRunning else { return }

        readerModeHander.register(webServer, profile: profile)

        let responders: [(String, InternalSchemeResponse)] =
             [(AboutHomeHandler.path, AboutHomeHandler()),
              (AboutLicenseHandler.path, AboutLicenseHandler()),
              (ErrorPageHandler.path, ErrorPageHandler())]
        responders.forEach { (path, responder) in
            InternalSchemeHandler.responders[path] = responder
        }

        if AppConstants.isRunningTest {
            registerHandlersForTestMethods(server: webServer.server)
        }

        // Bug 1223009 was an issue whereby CGDWebserver crashed when moving to a background task
        // catching and handling the error seemed to fix things, but we're not sure why.
        // Either way, not implicitly unwrapping a try is not a great way of doing things
        // so this is better anyway.
        do {
            try webServer.start()
        } catch {}
    }

    private func registerHandlersForTestMethods(server: GCDWebServer) {
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
                             "test-user-agent",
                             "test-cookie-store"]
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
}
