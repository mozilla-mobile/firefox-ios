import Foundation
import Shared
import GCDWebServers

// XCUITests that require custom localhost pages can add handlers here.
// This file is compiled as part of Client target, but it is in the XCUITest directory
// because it is for XCUITest purposes.

func registerHandlersForTestMethods(server: GCDWebServer) {
    // Add tracking protection check page
    server.addHandler(forMethod: "GET", path: "/test-fixtures/find-in-page-test.html", request: GCDWebServerRequest.self) { (request: GCDWebServerRequest?) in

        let node = "<span>  And the beast shall come forth surrounded by a roiling cloud of vengeance. The house of the unbelievers shall be razed and they shall be scorched to the earth. Their tags shall blink until the end of days. from The Book of Mozilla, 12:10 And the beast shall be made legion. Its numbers shall be increased a thousand thousand fold. The din of a million keyboards like unto a great storm shall cover the earth, and the followers of Mammon shall tremble. from The Book of Mozilla, 3:31 (Red Letter Edition) </span>"

        let repeatCount = 1000
        let textNodes = [String](repeating: node, count: repeatCount).reduce("", +)
        return GCDWebServerDataResponse(html: "<html><body>\(textNodes)</body></html>")
    }

    server.addHandler(forMethod: "GET", path: "/test-fixture/test-password.html", request: GCDWebServerRequest.self) { (request: GCDWebServerRequest?) in
        return GCDWebServerDataResponse(html: "<html><head><meta name=\"viewport\" content=\"width=device-width\"></head><body aria-label=\"body\"><form method=\"GET\" action=\"test-password-submit.html\"><p>Username: <input id=\"username\" type=\"text\" value=\"test@example.com\"></p><p>Password: <input id=\"password\" type=\"password\" value=\"verysecret\"></p><p><input type=\"submit\" value=\"Login\" aria-label=\"submit\"/></p></form></body><script>document.getElementById(\"password\").value = Math.random().toString();</script></html>")
      }

    server.addHandler(forMethod: "GET", path: "/test-fixture/test-password-submit.html", request: GCDWebServerRequest.self) { (request: GCDWebServerRequest?) in
        return GCDWebServerDataResponse(html: "<html><head><meta name=\"viewport\" content=\"width=device-width\"></head><body><p>Password submitted. Nope just a test.</p></body></html>" )
      }

    server.addHandler(forMethod: "GET", path: "/test-fixture/test-password-2.html", request: GCDWebServerRequest.self) { (request: GCDWebServerRequest?) in
        return GCDWebServerDataResponse(html: "<html><head><meta name=\"viewport\" content=\"width=device-width\"></head><body aria-label=\"body\"><form method=\"GET\" action=\"test-password-submit.html\"><p>Username: <input id=\"username\" type=\"text\" value=\"test@example.com\"></p><p>Password: <input id=\"password\" type=\"password\" value=\"verysecret\"></p><p><input type=\"submit\" value=\"Login\" aria-label=\"submit\"/></p></form></body><script>document.getElementById(\"password\").value = Math.random().toString();</script></html>")
      }

    server.addHandler(forMethod: "GET", path: "/test-fixture/test-password-submit-2.html", request: GCDWebServerRequest.self) { (request: GCDWebServerRequest?) in
      return GCDWebServerDataResponse(html: "<html><head><meta name=\"viewport\" content=\"width=device-width\"></head><body><p>Password submitted. Nope just a test.</p></body></html>" )
    }

    server.addHandler(forMethod: "GET", path: "/test-fixture/empty-login-form.html", request: GCDWebServerRequest.self) { (request: GCDWebServerRequest?) in
        return GCDWebServerDataResponse(html: "<html<head<meta name=\"viewport\" content=\"width=device-width\"></head><body aria-label=\"body\"><form method=\"GET\" action=\"test-password-submit.html\"><p>Username: <input id=\"username\" type=\"text\"</p><p>Password: <input id=\"password\" type=\"password\"</p><p><input type=\"submit\" value=\"Login\" aria-label=\"submit\"/></p></form></body><script></script></html>")
      }

    server.addHandler(forMethod: "GET", path: "/test-fixture/test-example.html", request: GCDWebServerRequest.self) { (request: GCDWebServerRequest?) in
        return GCDWebServerDataResponse(html: "<html><head><title>Example Domain</title></head><body><div><h1>Example Domain</h1><p>This domain is established to be used for illustrative examples in documents. You may use this domain in examples without prior coordination or asking for permission.</p><p><a href=\"http://www.iana.org/domains/example\">More information...</a></p></div></body></html>")
      }

    ["test-indexeddb-private", "test-window-opener", "test-mozilla-book", "test-popup-blocker", "test-user-agent", "test-mozilla-org"].forEach {
        addHTMLFixture(name: $0, server: server)
    }
}

// Make sure to add files to '/test-fixtures' directory in the source tree
fileprivate func addHTMLFixture(name: String, server: GCDWebServer) {
    if let path = Bundle.main.path(forResource: "test-fixtures/\(name)", ofType: "html") {
        server.addGETHandler(forPath: "/test-fixtures/\(name).html", filePath: path, isAttachment: false, cacheAge: UInt.max, allowRangeRequests: true)
    }
}

