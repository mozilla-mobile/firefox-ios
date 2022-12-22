// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
import Shared

// mailto headers: subject, body, cc, bcc

protocol MailProvider {
    var urlFormat: String {get set}
    var supportedHeaders: [String] {get set}
    func newEmailURLFromMetadata(_ metadata: MailToMetadata) -> URL?
}

extension MailProvider {
    fileprivate func constructEmailURLString(_ urlFormat: String,
                                             metadata: MailToMetadata,
                                             supportedHeaders: [String],
                                             bodyHName: String = "body",
                                             toHName: String = "to",
                                             toParamFormat: String = "%@=%@") -> String {
        var lowercasedHeaders = prepareHeaders(metadata: metadata)

        // Evaluate "to" parameter
        var toParam: String
        if let toHValue = lowercasedHeaders["to"] {
            let value = metadata.to.isEmpty ? toHValue : [metadata.to, toHValue].joined(separator: "%2C%20")
            lowercasedHeaders.removeValue(forKey: "to")
            toParam = String(format: toParamFormat, toHName, value)
        } else {
            toParam = String(format: toParamFormat, toHName, metadata.to)
        }

        // Create string of additional parameters
        let stringParams = prepareParams(headers: lowercasedHeaders,
                                         supportedHeaders: supportedHeaders,
                                         bodyHName: bodyHName)

        // Create url based on scheme
        var finalURLString = String(format: urlFormat, toParam, (stringParams.isEmpty ? "" : stringParams))

        // Clean up url scheme. Remove ? or & if parameters are empty
        if stringParams.isEmpty, ["?", "&"].contains(finalURLString.last) {
            finalURLString = String(finalURLString.dropLast())
        }

        return finalURLString
    }

    private func prepareHeaders(metadata: MailToMetadata) -> [String: String] {
        var lowercasedHeaders = [String: String]()

        metadata.headers.forEach { (hname, hvalue) in
            lowercasedHeaders[hname.lowercased()] = hvalue
        }
        return lowercasedHeaders
    }

    private func prepareParams(headers: [String: String],
                               supportedHeaders: [String],
                               bodyHName: String = "body") -> String {
        var queryParams: [String] = []

        headers.forEach({ (hname, hvalue) in
            if supportedHeaders.contains(hname) {
                queryParams.append("\(hname)=\(hvalue)")
            } else if hname == "body" {
                queryParams.append("\(bodyHName)=\(hvalue)")
            }
        })

        return queryParams.joined(separator: "&")
    }
}

class ReaddleSparkIntegration: MailProvider {
    var urlFormat = "readdle-spark://compose?%@&%@"
    var supportedHeaders = [
        "subject",
        "recipient",
        "textbody",
        "html",
        "cc",
        "bcc"
    ]

    func newEmailURLFromMetadata(_ metadata: MailToMetadata) -> URL? {
        return constructEmailURLString(urlFormat,
                                       metadata: metadata,
                                       supportedHeaders: supportedHeaders,
                                       bodyHName: "textbody",
                                       toHName: "recipient").asURL
    }
}

class AirmailIntegration: MailProvider {
    var urlFormat = "airmail://compose?%@&%@"
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
        return constructEmailURLString(urlFormat,
                                       metadata: metadata,
                                       supportedHeaders: supportedHeaders,
                                       bodyHName: "htmlBody").asURL
    }
}

class MyMailIntegration: MailProvider {
    var urlFormat = "mymail-mailto://?%@&%@"
    var supportedHeaders = [
        "to",
        "subject",
        "body",
        "cc",
        "bcc"
    ]

    func newEmailURLFromMetadata(_ metadata: MailToMetadata) -> URL? {
        return constructEmailURLString(urlFormat,
                                       metadata: metadata,
                                       supportedHeaders: supportedHeaders).asURL
    }
}

class MailRuIntegration: MyMailIntegration {
    override init() {
        super.init()
        self.urlFormat = "mailru-mailto://?%@&%@"
    }
}

class MSOutlookIntegration: MailProvider {
    var urlFormat = "ms-outlook://emails/new?%@&%@"
    var supportedHeaders = [
        "to",
        "cc",
        "bcc",
        "subject",
        "body"
    ]

    func newEmailURLFromMetadata(_ metadata: MailToMetadata) -> URL? {
        return constructEmailURLString(urlFormat,
                                       metadata: metadata,
                                       supportedHeaders: supportedHeaders).asURL
    }
}

class YMailIntegration: MailProvider {
    var urlFormat = "ymail://mail/any/compose?%@&%@"
    var supportedHeaders = [
        "to",
        "cc",
        "subject",
        "body"
    ]

    func newEmailURLFromMetadata(_ metadata: MailToMetadata) -> URL? {
        return constructEmailURLString(urlFormat,
                                       metadata: metadata,
                                       supportedHeaders: supportedHeaders).asURL
    }
}

class GoogleGmailIntegration: MailProvider {
    var urlFormat = "googlegmail:///co?%@&%@"
    var supportedHeaders = [
        "to",
        "cc",
        "bcc",
        "subject",
        "body"
    ]

    func newEmailURLFromMetadata(_ metadata: MailToMetadata) -> URL? {
        return constructEmailURLString(urlFormat,
                                       metadata: metadata,
                                       supportedHeaders: supportedHeaders).asURL
    }
}

class FastmailIntegration: MailProvider {
    var urlFormat = "fastmail://mail/compose?%@&%@"
    var supportedHeaders = [
        "to",
        "cc",
        "bcc",
        "subject",
        "body"
    ]

    func newEmailURLFromMetadata(_ metadata: MailToMetadata) -> URL? {
        return constructEmailURLString(urlFormat,
                                       metadata: metadata,
                                       supportedHeaders: supportedHeaders).asURL
    }
}

class ProtonMailIntegration: MailProvider {
    var urlFormat = "protonmail://%@?%@"
    var supportedHeaders = [
        "to",
        "cc",
        "bcc",
        "subject",
        "body"
    ]

    func newEmailURLFromMetadata(_ metadata: MailToMetadata) -> URL? {
        return constructEmailURLString(urlFormat,
                                       metadata: metadata,
                                       supportedHeaders: supportedHeaders,
                                       toHName: "mailto",
                                       toParamFormat: "%@:%@").asURL
    }
}
