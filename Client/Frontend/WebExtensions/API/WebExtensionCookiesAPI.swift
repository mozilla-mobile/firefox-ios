/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import WebKit

private func cookieToDictionary(_ cookie: HTTPCookie) -> [String : Any]? {
    guard let properties = cookie.properties else {
        return nil
    }

    var dictionary: [String : Any] = [:]
    for key in Array(properties.keys) {
        if let javaScriptKey = cookiePropertyKeyToJavaScriptKey(key) {
            dictionary[javaScriptKey] = properties[key]
        }
    }

    return dictionary
}

private func cookie(_ cookie: HTTPCookie, matches criteria: [HTTPCookiePropertyKey : Any]) -> Bool {
    guard let properties = cookie.properties else {
        return false
    }
    for (key, value) in criteria {
        // Special case for matching OriginURL
        if key == .originURL,
            let criteriaValueString = value as? String,
            let criteriaValueURL = URL(string: criteriaValueString),
            let criteriaDomainValue = criteriaValueURL.host,
            let cookieDomainValue = properties[.domain] as? String,
            criteriaDomainValue == cookieDomainValue {
            continue
        }

        if let criteriaValue = value as? String {
            guard let cookieValue = properties[key] as? String else {
                return false
            }
            if criteriaValue != cookieValue {
                return false
            }
        }
        if let criteriaValue = value as? Int {
            guard let cookieValue = properties[key] as? Int else {
                return false
            }
            if criteriaValue != cookieValue {
                return false
            }
        }
        if let criteriaValue = value as? Bool {
            guard let cookieValue = properties[key] as? Bool else {
                return false
            }
            if criteriaValue != cookieValue {
                return false
            }
        }
    }
    return true
}

private func javaScriptKeyToCookiePropertyKey(_ key: String) -> HTTPCookiePropertyKey? {
    switch key {
    case "name":
        return .name
    case "value":
        return .value
    case "url":
        return .originURL
    case "domain":
        return .domain
    case "path":
        return .path
    case "secure":
        return .secure
    case "session":
        return .discard
    default:
        return nil
    }
}

private func cookiePropertyKeyToJavaScriptKey(_ key: HTTPCookiePropertyKey) -> String? {
    switch key {
    case .name:
        return "name"
    case .value:
        return "value"
    case .originURL:
        return "url"
    case .domain:
        return "domain"
    case .path:
        return "path"
    case .secure:
        return "secure"
    case .discard:
        return "session"
    default:
        return nil
    }
}

class WebExtensionCookiesAPI: WebExtensionAPIEventDispatcher {
    override class var Name: String { return "cookies" }

    enum Method: String {
        case get
        case getAll
        case set
        case remove
        case getAllCookieStores
    }

    func get(_ connection: WebExtensionAPIConnection) {
        guard let payload = connection.payload,
            let _ = payload["name"],
            let _ = payload["url"] else {
            connection.error("Unable to get cookie; invalid criteria")
            return
        }

        var criteria: [HTTPCookiePropertyKey : Any] = [:]
        for key in Array(payload.keys) {
            if let propertyKey = javaScriptKeyToCookiePropertyKey(key), let value = payload[key] {
                criteria[propertyKey] = value
            }
        }

        WKWebsiteDataStore.default().httpCookieStore.getAllCookies { cookies in
            guard let cookie = cookies.find({ cookie($0, matches: criteria) }) else {
                connection.respond(NSNull())
                return
            }

            guard let dictionary = cookieToDictionary(cookie) else {
                connection.error("Unable to get cookie; properties not retrieved")
                return
            }

            connection.respond(dictionary)
        }
    }

    func getAll(_ connection: WebExtensionAPIConnection) {
        guard let payload = connection.payload else {
                connection.error("Unable to get cookies; invalid criteria")
                return
        }

        var criteria: [HTTPCookiePropertyKey : Any] = [:]
        for key in Array(payload.keys) {
            if let propertyKey = javaScriptKeyToCookiePropertyKey(key), let value = payload[key] {
                criteria[propertyKey] = value
            }
        }

        WKWebsiteDataStore.default().httpCookieStore.getAllCookies { cookies in
            let filteredCookies = cookies.filter({ cookie($0, matches: criteria) })
            connection.respond(filteredCookies.compactMap({ cookieToDictionary($0) }))
        }
    }

    func set(_ connection: WebExtensionAPIConnection) {
        guard let payload = connection.payload,
            let name = payload["name"] as? String,
            let value = payload["value"] as? String,
            let urlString = payload["url"] as? String,
            let url = URL(string: urlString),
            let host = url.host,
            let cookie = HTTPCookie(properties: [
                .domain: host,
                .path: url.path,
                .name: name,
                .value: value
            ]) else {
            connection.error("Unable to set cookie; required field(s) missing")
            return
        }

        WKWebsiteDataStore.default().httpCookieStore.setCookie(cookie) {
            guard let dictionary = cookieToDictionary(cookie) else {
                connection.error("Unable to set cookie; properties not saved")
                return
            }

            connection.respond(dictionary)
        }
    }

    func remove(_ connection: WebExtensionAPIConnection) {
        guard let payload = connection.payload,
            let _ = payload["name"],
            let _ = payload["url"] else {
                connection.error("Unable to remove cookie; invalid criteria")
                return
        }

        var criteria: [HTTPCookiePropertyKey : Any] = [:]
        for key in Array(payload.keys) {
            if let propertyKey = javaScriptKeyToCookiePropertyKey(key), let value = payload[key] {
                criteria[propertyKey] = value
            }
        }

        WKWebsiteDataStore.default().httpCookieStore.getAllCookies { cookies in
            guard let cookie = cookies.find({ cookie($0, matches: criteria) }) else {
                connection.respond(NSNull())
                return
            }

            guard let dictionary = cookieToDictionary(cookie) else {
                connection.error("Unable to remove cookie; properties not retrieved")
                return
            }

            WKWebsiteDataStore.default().httpCookieStore.delete(cookie) {
                connection.respond(dictionary)
            }
        }
    }
}

extension WebExtensionCookiesAPI: WebExtensionAPIConnectionHandler {
    func webExtension(_ webExtension: WebExtension, didReceiveConnection connection: WebExtensionAPIConnection) {
        guard let method = Method.init(rawValue: connection.method) else {
            connection.error("Unknown method: \(connection.method)")
            return
        }

        switch method {
        case .get:
            get(connection)
        case .getAll:
            getAll(connection)
        case .set:
            set(connection)
        case .remove:
            remove(connection)
        default:
            connection.error("Method not implemented: \(connection.method)")
        }
    }
}
