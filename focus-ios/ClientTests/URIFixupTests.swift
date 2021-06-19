/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

#if FOCUS
@testable import Firefox_Focus
#else
@testable import Firefox_Klar
#endif

class URIFixupTests: XCTestCase {
    
    private let customSchemeURLs = ["firefox://",
                                    "dns://192.168.1.1/ftp.example.org?type=A",
                                    "feed://example.com/rss.xml",
                                    "git://github.com/user/project-name.git",
                                    "mailto:jsmith@example.com",
                                    "smb://workgroup;user:password@server/share/folder/file.txt",
                                    "view-source:http://en.wikipedia.org/wiki/URI_scheme"]
    
    private let httpSchemeURLs = ["http://mozilla.org//fire_fire",
                                  "http://mozilla.org//fire_fire/",
                                  "http://mozilla.org//fire_fire_(firefox)",
                                  "http://mozilla.org//fire_fire_(firefox)_(browser)",
                                  "http://www.mozilla.org/wpstyle/?p=364",
                                  "http://www.mozilla.org/foo/?bar=baz&inga=42&quux",
                                  "http://✪gg.ff/123",
                                  "http://userid:password@mozilla.org:8080",
                                  "http://userid:password@mozilla.org:8080/",
                                  "http://userid@mozilla.org",
                                  "http://userid@mozilla.org/",
                                  "http://userid@mozilla.org:8080",
                                  "http://userid@mozilla.org:8080/",
                                  "http://userid:password@mozilla.org",
                                  "http://userid:password@mozilla.org/",
                                  "http://➡.mo/王",
                                  "http://⌘.mo",
                                  "http://⌘.mo/",
                                  "http://mozilla.org/blah_(wikipedia)#cite-1",
                                  "http://mozilla.org/blah_(wikipedia)_blah#cite-1",
                                  "http://mozilla.org/unicode_(✪)_in_parens",
                                  "http://mozilla.org/(firefox)?after=parens",
                                  "http://☺.mozilla.org/",
                                  "http://code.mozilla.org/users/#&firefox=browser",
                                  "http://f.co",
                                  "http://moz.fir/?q=Test%20URL-encoded%20fire",
                                  "http://مثال.إختبار",
                                  "http://王涵.王涵",
                                  "http://-.~_!$&'()*+,;=:%40:80%2f::::::@mozilla.org",
                                  "http://6662.net",
                                  "http://f.i-r.ef",
                                  "http://266.315.245.345",
                                  "http://266.315.245.345:100"]
    
    private let invalidURLs = ["http://mozilla",
                               "http:// shouldfail.com",
                               "http://0123456789",
                               "mo zilla.com",
                               "www.firefox .com",
                               "http://fire fox.com",
                               "mozilla",
                               "http://[2001:db8:85a3::8a2e:370:7334]",
                               ":/#?&@%+~"]
    
    func testValidURLsForHttpAndHttpsSchemes() {
        httpSchemeURLs.forEach {
            XCTAssertNotNil(URIFixup.getURL(entry: $0), "\($0) is not a valid URL")
            
            let httpsSchemeURL = $0.replacingOccurrences(of: "http", with: "https")
            XCTAssertNotNil(URIFixup.getURL(entry: httpsSchemeURL), "\(httpsSchemeURL) is not a valid URL")
        }
    }
    
    func testValidURLsForNoSchemes() {
        httpSchemeURLs.forEach {
            let noSchemeURL = $0.replacingOccurrences(of: "http", with: "")
            XCTAssertNotNil(URIFixup.getURL(entry: noSchemeURL), "\(noSchemeURL) is not a valid URL")
        }
    }
    
    func testCustomSchemes() {
        customSchemeURLs.forEach {
            XCTAssertNotNil(URIFixup.getURL(entry: $0), "\($0) is not a valid URL")
        }
    }
    
    func testInvalidURLs() {
        invalidURLs.forEach {
            XCTAssertNil(URIFixup.getURL(entry: $0), "\($0) is a valid URL")
        }
    }
    
}
