// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

// mailto headers: subject, body, cc, bcc

enum MailProviderEmailFormat {
    case standard
    case protonmail // used for Protonmail
}

protocol MailProvider {
    var components: URLComponents { get }
    var supportedHeaders: [String] { get set }
    func newEmailURLFromMetadata(_ metadata: MailToMetadata) -> URL?
}

extension MailProvider {
    fileprivate func constructEmailURLString(_ urlComponents: URLComponents,
                                             metadata: MailToMetadata,
                                             supportedHeaders: [String],
                                             bodyHName: String = "body",
                                             toHName: String = "to",
                                             emailFormat: MailProviderEmailFormat = .standard) -> URLComponents {
        var lowercasedHeaders = prepareHeaders(metadata: metadata)

        // Evaluate "to" parameter
        var toQueryItem: URLQueryItem
        if let toHeaderValue = lowercasedHeaders["to"] {
            let value = metadata.to.isEmpty ? toHeaderValue : [metadata.to, toHeaderValue].joined(separator: ",")
            lowercasedHeaders.removeValue(forKey: "to")
            toQueryItem = URLQueryItem(name: toHName, value: value)
        } else {
            toQueryItem = URLQueryItem(name: toHName, value: metadata.to)
        }

        // Create string of additional parameters
        let additionalQueryItems = prepareParams(headers: lowercasedHeaders,
                                                 supportedHeaders: supportedHeaders,
                                                 bodyName: bodyHName)

        // Create url based on scheme
        var urlComponents = urlComponents
        var queryItems: [URLQueryItem] = [toQueryItem]
        queryItems.append(contentsOf: additionalQueryItems)
        urlComponents.queryItems = queryItems.isEmpty ? nil : queryItems

        if emailFormat == .protonmail {
            urlComponents = addProtonmailComponents(urlComponents, toQueryItem: toQueryItem)
        }

        return urlComponents
    }

    // Used to build Protonmail URL correctly (format: "protonmail://mailto:email@test.com")
    // We use the user, password and host component parts for this URL format.
    private func addProtonmailComponents(_ components: URLComponents,
                                         toQueryItem: URLQueryItem) -> URLComponents {
        var urlComponents = components
        let queryItems: [URLQueryItem]? = components.queryItems

        // Split email in user name and domain
        guard let emailComponents = toQueryItem.value?.components(separatedBy: "@"),
              emailComponents.count >= 2
        else { return urlComponents }

        // Password receives the part before the last @ (e.g. "email" if there is only one email address or
        // "email@test.com,email2" in case there is two email addresses
        // Host will be assigned the domain of the last email address (e.g. "test.com")
        urlComponents.password = emailComponents[0...emailComponents.count - 2].joined(separator: "@")
        urlComponents.host = emailComponents.last

        // Remove the "to" data from query items
        // Set query items to nil if there is no data left in it to avoid having a URL with a question mark at the end
        if var items = queryItems, let index = items.firstIndex(of: toQueryItem) {
            items.remove(at: index)
            urlComponents.queryItems = items.isEmpty ? nil : items
        }

        return urlComponents
    }

    private func prepareHeaders(metadata: MailToMetadata) -> [String: String] {
        var lowercasedHeaders = [String: String]()

        metadata.headers.forEach { (name, value) in
            lowercasedHeaders[name.lowercased()] = value
        }
        return lowercasedHeaders
    }

    private func prepareParams(headers: [String: String],
                               supportedHeaders: [String],
                               bodyName: String = "body") -> [URLQueryItem] {
        var queryItems = [URLQueryItem]()

        headers.forEach({ (name, value) in
            if supportedHeaders.contains(name) {
                queryItems.append(URLQueryItem(name: name, value: value))
            } else if name == "body" {
                queryItems.append(URLQueryItem(name: bodyName, value: value))
            }
        })

        return queryItems
    }
}

class ReaddleSparkIntegration: MailProvider {
    var components: URLComponents {
        var components = URLComponents()
        components.scheme = "readdle-spark"
        components.host = "compose"
        return components
    }
    var supportedHeaders = [
        "subject",
        "recipient",
        "textbody",
        "html",
        "cc",
        "bcc"
    ]

    func newEmailURLFromMetadata(_ metadata: MailToMetadata) -> URL? {
        return constructEmailURLString(components,
                                       metadata: metadata,
                                       supportedHeaders: supportedHeaders,
                                       bodyHName: "textbody",
                                       toHName: "recipient").url
    }
}

class AirmailIntegration: MailProvider {
    var components: URLComponents {
        var components = URLComponents()
        components.scheme = "airmail"
        components.host = "compose"
        return components
    }
    var supportedHeaders = [
        "subject",
        "from",
        "to",
        "cc",
        "bcc",
        "plainBody",
        "htmlBody"
    ]

    func newEmailURLFromMetadata(_ metadata: MailToMetadata) -> URL? {
        return constructEmailURLString(components,
                                       metadata: metadata,
                                       supportedHeaders: supportedHeaders,
                                       bodyHName: "htmlBody").url
    }
}

class MyMailIntegration: MailProvider {
    var components: URLComponents {
        var components = URLComponents()
        components.scheme = "mymail-mailto"
        components.host = ""
        return components
    }
    var supportedHeaders = [
        "to",
        "subject",
        "body",
        "cc",
        "bcc"
    ]

    func newEmailURLFromMetadata(_ metadata: MailToMetadata) -> URL? {
        return constructEmailURLString(components,
                                       metadata: metadata,
                                       supportedHeaders: supportedHeaders).url
    }
}

class MailRuIntegration: MyMailIntegration {
    override var components: URLComponents {
        var components = super.components
        components.scheme = "mailru-mailto"
        return components
    }
}

class MSOutlookIntegration: MailProvider {
    var components: URLComponents {
        var components = URLComponents()
        components.scheme = "ms-outlook"
        components.path = "emails/new"
        return components
    }
    var supportedHeaders = [
        "to",
        "cc",
        "bcc",
        "subject",
        "body"
    ]

    func newEmailURLFromMetadata(_ metadata: MailToMetadata) -> URL? {
        return constructEmailURLString(components,
                                       metadata: metadata,
                                       supportedHeaders: supportedHeaders).url
    }
}

class YMailIntegration: MailProvider {
    var components: URLComponents {
        var components = URLComponents()
        components.scheme = "ymail"
        components.path = "mail/any/compose"
        return components
    }
    var supportedHeaders = [
        "to",
        "cc",
        "subject",
        "body"
    ]

    func newEmailURLFromMetadata(_ metadata: MailToMetadata) -> URL? {
        return constructEmailURLString(components,
                                       metadata: metadata,
                                       supportedHeaders: supportedHeaders).url
    }
}

class GoogleGmailIntegration: MailProvider {
    var components: URLComponents {
        var components = URLComponents()
        components.scheme = "googlegmail"
        components.host = "co"
        return components
    }
    var supportedHeaders = [
        "to",
        "cc",
        "bcc",
        "subject",
        "body"
    ]

    func newEmailURLFromMetadata(_ metadata: MailToMetadata) -> URL? {
        return constructEmailURLString(components,
                                       metadata: metadata,
                                       supportedHeaders: supportedHeaders).url
    }
}

class FastmailIntegration: MailProvider {
    var components: URLComponents {
        var components = URLComponents()
        components.scheme = "fastmail"
        components.path = "mail/compose"
        return components
    }
    var supportedHeaders = [
        "to",
        "cc",
        "bcc",
        "subject",
        "body"
    ]

    func newEmailURLFromMetadata(_ metadata: MailToMetadata) -> URL? {
        return constructEmailURLString(components,
                                       metadata: metadata,
                                       supportedHeaders: supportedHeaders).url
    }
}

class ProtonMailIntegration: MailProvider {
    var components: URLComponents {
        var components = URLComponents()
        components.scheme = "protonmail"
        components.user = "mailto"
        return components
    }
    var supportedHeaders = [
        "to",
        "cc",
        "bcc",
        "subject",
        "body"
    ]

    func newEmailURLFromMetadata(_ metadata: MailToMetadata) -> URL? {
        return constructEmailURLString(components,
                                       metadata: metadata,
                                       supportedHeaders: supportedHeaders,
                                       toHName: "mailto",
                                       emailFormat: .protonmail).url
    }
}
