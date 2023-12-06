// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

// The list of permanent URI schemes has been taken from http://www.iana.org/assignments/uri-schemes/uri-schemes.xhtml
private let permanentURISchemes = ["aaa",
                                   "aaas",
                                   "about",
                                   "acap",
                                   "acct",
                                   "cap",
                                   "cid",
                                   "coap",
                                   "coaps",
                                   "crid",
                                   "data",
                                   "dav",
                                   "dict",
                                   "dns",
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
                                   "shttp",
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
                                   "z39.50s"]

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

    public func getQuery() -> [String: String] {
        var results = [String: String]()

        guard let components = URLComponents(url: self, resolvingAgainstBaseURL: false),
              let queryItems = components.percentEncodedQueryItems
        else {
            return results
        }

        for item in queryItems {
            if let value = item.value {
                results[item.name] = value
            }
        }

        return results
    }

    public var hostPort: String? {
        if let host = self.host {
            if let port = (self as NSURL).port?.int32Value {
                return "\(host):\(port)"
            }
            return host
        }
        return nil
    }

    public var origin: String? {
        guard isWebPage(includeDataURIs: false),
              let hostPort = self.hostPort,
              let scheme = scheme
        else { return nil }

        return "\(scheme)://\(hostPort)"
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

    public func isWebPage(includeDataURIs: Bool = true) -> Bool {
        let schemes = includeDataURIs ? ["http", "https", "data"] : ["http", "https"]
        return scheme.map { schemes.contains($0) } ?? false
    }

    /**
     Returns whether the URL's scheme is one of those listed on the official list of URI schemes.
     This only accepts permanent schemes: historical and provisional schemes are not accepted.
     */
    public var schemeIsValid: Bool {
        guard let scheme = scheme else { return false }
        return permanentURISchemes.contains(scheme.lowercased()) && self.absoluteURL.absoluteString.lowercased() != scheme + ":"
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

// Extensions to deal with ReaderMode URLs

extension URL {
    public var isFile: Bool {
        return self.scheme == "file"
    }

    public var isReaderModeURL: Bool {
        let scheme = self.scheme, host = self.host, path = self.path
        return scheme == "http" && host == "localhost" && path == "/reader-mode/page"
    }

    public var isSyncedReaderModeURL: Bool {
        return self.absoluteString.hasPrefix("about:reader?url=")
    }

    public var decodeReaderModeURL: URL? {
        if self.isReaderModeURL || self.isSyncedReaderModeURL {
            if let components = URLComponents(url: self, resolvingAgainstBaseURL: false),
                let queryItems = components.queryItems {
                if let queryItem = queryItems.find({ $0.name == "url" }),
                    let value = queryItem.value {
                    return URL(string: value, invalidCharacters: false)?.safeEncodedUrl
                }
            }
        }
        return nil
    }

    public func encodeReaderModeURL(_ baseReaderModeURL: String) -> URL? {
        if let encodedURL = absoluteString.addingPercentEncoding(withAllowedCharacters: .alphanumerics) {
            if let aboutReaderURL = URL(string: "\(baseReaderModeURL)?url=\(encodedURL)", invalidCharacters: false) {
                return aboutReaderURL
            }
        }
        return nil
    }
}

// MARK: - Exported URL Schemes

extension URL {
    public static var mozPublicScheme: String = {
        guard let string = Bundle.main.object(forInfoDictionaryKey: "MozPublicURLScheme") as? String, !string.isEmpty else {
            // Something went wrong/weird, fall back to hard-coded.
            return "firefox"
        }
        return string
    }()

    public static var mozInternalScheme: String = {
        guard let string = Bundle.main.object(forInfoDictionaryKey: "MozInternalURLScheme") as? String, !string.isEmpty else {
            // Something went wrong/weird, fallback to the public one.
            return Self.mozPublicScheme
        }
        return string
    }()

    public var safeEncodedUrl: URL? {
        var components = URLComponents(url: self, resolvingAgainstBaseURL: false)

        // HTML-encode scheme, host, and path
        guard let host = components?.host?.htmlEntityEncodedString,
            let scheme = components?.scheme?.htmlEntityEncodedString,
            let path = components?.path.htmlEntityEncodedString else {
            return nil
        }

        components?.path = path
        components?.scheme = scheme
        components?.host = host

        // sanitize query items
        if let queryItems = components?.queryItems {
            var safeQueryItems: [URLQueryItem] = []

            for item in queryItems {
                // percent-encoded characters
                guard let decodedValue = item.value?.removingPercentEncoding else {
                    return nil
                }

                // HTML special characters
                let htmlEncodedValue = decodedValue.htmlEntityEncodedString

                // New query item with the HTML-encoded value
                let safeItem = URLQueryItem(name: item.name, value: htmlEncodedValue)
                safeQueryItems.append(safeItem)
            }

            // Replace the original query items with the "safe" ones
            components?.queryItems = safeQueryItems
        }

        return components?.url
    }
}
