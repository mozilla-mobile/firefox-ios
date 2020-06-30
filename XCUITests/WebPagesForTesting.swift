import Foundation
import Shared
import GCDWebServers

// XCUITests that require custom localhost pages can add handlers here.
// This file is compiled as part of Client target, but it is in the XCUITest directory
// because it is for XCUITest purposes.

func registerHandlersForTestMethods(server: GCDWebServer) {
    // Add tracking protection check page
    server.addHandler(forMethod: "GET", path: "/test-fixture/find-in-page-test.html", request: GCDWebServerRequest.self) { (request: GCDWebServerRequest?) in

        let node = "<span>  And the beast shall come forth surrounded by a roiling cloud of vengeance. The house of the unbelievers shall be razed and they shall be scorched to the earth. Their tags shall blink until the end of days. from The Book of Mozilla, 12:10 And the beast shall be made legion. Its numbers shall be increased a thousand thousand fold. The din of a million keyboards like unto a great storm shall cover the earth, and the followers of Mammon shall tremble. from The Book of Mozilla, 3:31 (Red Letter Edition) </span>"

        let repeatCount = 1000
        let textNodes = [String](repeating: node, count: repeatCount).reduce("", +)
        return GCDWebServerDataResponse(html: "<html><body>\(textNodes)</body></html>")
    }

    ["test-indexeddb-private", "test-window-opener", "test-password", "test-password-submit", "test-password-2", "test-password-submit-2", "empty-login-form", "empty-login-form-submit", "test-example", "test-example-link", "test-mozilla-book", "test-mozilla-org", "test-popup-blocker",
        "manifesto-en", "manifesto-es", "manifesto-zh-CN", "manifesto-ar", "test-user-agent"].forEach {
        addHTMLFixture(name: $0, server: server)
    }
}

// Make sure to add files to '/test-fixtures' directory in the source tree
fileprivate func addHTMLFixture(name: String, server: GCDWebServer) {
    if let path = Bundle.main.path(forResource: "test-fixtures/\(name)", ofType: "html") {
        server.addGETHandler(forPath: "/test-fixture/\(name).html", filePath: path, isAttachment: false, cacheAge: UInt.max, allowRangeRequests: true)
    }
}

