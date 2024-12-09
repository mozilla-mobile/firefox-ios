// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common
import WebEngine

// The list of permanent URI schemes has been taken from http://www.iana.org/assignments/uri-schemes/uri-schemes.xhtml
private let permanentURISchemes = [
    "aaa",
    "aaas",
    "about",
    "acap",
    "acct",
    "cap",
    "cid",
    "coap",
    "coap+tcp",
    "coap+ws",
    "coaps",
    "coaps+tcp",
    "coaps+ws",
    "crid",
    "data",
    "dav",
    "dict",
    "dns",
    "doi",
    "dtn",
    "example",
    "file",
    "ftp",
    "geo",
    "go",
    "gopher",
    "h323",
    "http",
    "https",
    "iax",
    "icap",
    "im",
    "imap",
    "info",
    "ipn",
    "ipp",
    "ipps",
    "iris",
    "iris.beep",
    "iris.lwz",
    "iris.xpc",
    "iris.xpcs",
    "jabber",
    "ldap",
    "leaptofrogans",
    "mailto",
    "mid",
    "msrp",
    "msrps",
    "mt",
    "mtqp",
    "mupdate",
    "news",
    "nfs",
    "ni",
    "nih",
    "nntp",
    "opaquelocktoken",
    "pkcs11",
    "pop",
    "pres",
    "reload",
    "rtsp",
    "rtsps",
    "rtspu",
    "service",
    "session",
    "sieve",
    "sip",
    "sips",
    "sms",
    "snmp",
    "soap.beep",
    "soap.beeps",
    "stun",
    "stuns",
    "tag",
    "tel",
    "telnet",
    "tftp",
    "thismessage",
    "tip",
    "tn3270",
    "turn",
    "turns",
    "tv",
    "urn",
    "vemmi",
    "vnc",
    "ws",
    "wss",
    "xcon",
    "xcon-userid",
    "xmlrpc.beep",
    "xmlrpc.beeps",
    "xmpp",
    "z39.50r",
    "z39.50s",
]

extension URL {
    public func withQueryParams(_ params: [URLQueryItem]) -> URL {
        var components = URLComponents(url: self, resolvingAgainstBaseURL: false)!
        var items = (components.queryItems ?? [])
        for param in params {
            items.append(param)
        }
        components.queryItems = items
        return components.url!
    }

    public func withQueryParam(_ name: String, value: String) -> URL {
        var components = URLComponents(url: self, resolvingAgainstBaseURL: false)!
        let item = URLQueryItem(name: name, value: value)
        components.queryItems = (components.queryItems ?? []) + [item]
        return components.url!
    }

    /// String suitable for displaying outside of the app, for example in notifications, were Data Detectors will
    /// linkify the text and make it into a openable-in-Safari link.
    public var absoluteDisplayExternalString: String {
        return self.absoluteDisplayString.replacingOccurrences(of: ".", with: "\u{2024}")
    }

    public var displayURL: URL? {
        if AppConstants.isRunningUITests || AppConstants.isRunningPerfTests, path.contains("test-fixture/") {
            return self
        }

        if self.absoluteString.starts(with: "blob:") {
            return URL(string: "blob:")
        }

        if self.isFileURL {
            return URL(string: "file://\(self.lastPathComponent)")
        }

        if self.isReaderModeURL {
            return self.decodeReaderModeURL?.havingRemovedAuthorisationComponents()
        }

        if let internalUrl = InternalURL(self), internalUrl.isErrorPage {
            return internalUrl.originalURLFromErrorPage?.displayURL
        }

        if !InternalURL.isValid(url: self) {
            return self.havingRemovedAuthorisationComponents()
        }

        return nil
    }

    /**
     Returns whether the URL's scheme is one of those listed on the official list of URI schemes.
     This only accepts permanent schemes: historical and provisional schemes are not accepted.
     */
    public var schemeIsValid: Bool {
        guard let scheme = scheme else { return false }
        return permanentURISchemes.contains(scheme.lowercased())
               && self.absoluteURL.absoluteString.lowercased() != scheme + ":"
    }

    public func havingRemovedAuthorisationComponents() -> URL {
        guard var urlComponents = URLComponents(url: self, resolvingAgainstBaseURL: false) else {
            return self
        }
        urlComponents.user = nil
        urlComponents.password = nil
        if let url = urlComponents.url {
            return url
        }
        return self
    }

    public func isEqual(_ url: URL) -> Bool {
        if self == url {
            return true
        }

        // Try an additional equality case by chopping off the trailing slash
        let urls: [String] = [url.absoluteString, absoluteString].map { item in
            if let lastCh = item.last, lastCh == "/" {
                return item.dropLast().lowercased()
            }
            return item.lowercased()
        }
        return urls[0] == urls[1]
    }

    public var isFxHomeUrl: Bool {
        return absoluteString.hasPrefix("internal://local/about/home")
    }
}

// MARK: - Exported URL Schemes

extension URL {
    public static var mozPublicScheme: String = {
        guard let string = Bundle.main.object(
            forInfoDictionaryKey: "MozPublicURLScheme"
        ) as? String, !string.isEmpty else {
            // Something went wrong/weird, fall back to hard-coded.
            return "firefox"
        }
        return string
    }()

    public static var mozInternalScheme: String = {
        guard let string = Bundle.main.object(
            forInfoDictionaryKey: "MozInternalURLScheme"
        ) as? String, !string.isEmpty else {
            // Something went wrong/weird, fallback to the public one.
            return Self.mozPublicScheme
        }
        return string
    }()
}
