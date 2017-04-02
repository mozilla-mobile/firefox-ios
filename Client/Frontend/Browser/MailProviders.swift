/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

// mailto headers: subject, body, cc, bcc

protocol MailProvider {
    var beginningScheme: String {get set}
    var supportedHeaders: [String] {get set}
    func newEmailURLFromMetadata(_ metadata: MailToMetadata) -> URL?
}

private func constructEmailURLString(_ beginningURLString: String, metadata: MailToMetadata, supportedHeaders: [String], bodyHName: String = "body", toHName: String = "to") -> String {
    var lowercasedHeaders = [String: String]()
    metadata.headers.forEach { (hname, hvalue) in
        lowercasedHeaders[hname.lowercased()] = hvalue
    }

    var toParam: String
    if let toHValue = lowercasedHeaders["to"] {
        let value = metadata.to.isEmpty ? toHValue : [metadata.to, toHValue].joined(separator: "%2C%20")
        lowercasedHeaders.removeValue(forKey: "to")
        toParam = "\(toHName)=\(value)"
    } else {
        toParam = "\(toHName)=\(metadata.to)"
    }

    var queryParams: [String] = []
    lowercasedHeaders.forEach({ (hname, hvalue) in
        if supportedHeaders.contains(hname) {
            queryParams.append("\(hname)=\(hvalue)")
        } else if hname == "body" {
            queryParams.append("\(bodyHName)=\(hvalue)")
        }
    })
    let stringParams = queryParams.joined(separator: "&")
    let finalURLString = beginningURLString + (stringParams.isEmpty ? toParam : [toParam, stringParams].joined(separator: "&"))
    return finalURLString
}

class ReaddleSparkIntegration: MailProvider {
    var beginningScheme = "readdle-spark://compose?"
    var supportedHeaders = [
        "subject",
        "recipient",
        "textbody",
        "html",
        "cc",
        "bcc"
    ]

    func newEmailURLFromMetadata(_ metadata: MailToMetadata) -> URL? {
        return constructEmailURLString(beginningScheme, metadata: metadata, supportedHeaders: supportedHeaders, bodyHName: "textbody", toHName: "recipient").asURL
    }
}

class AirmailIntegration: MailProvider {
    var beginningScheme = "airmail://compose?"
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
        return constructEmailURLString(beginningScheme, metadata: metadata, supportedHeaders: supportedHeaders, bodyHName: "htmlBody").asURL
    }
}

class MyMailIntegration: MailProvider {
    var beginningScheme = "mymail-mailto://?"
    var supportedHeaders = [
        "to",
        "subject",
        "body",
        "cc",
        "bcc"
    ]

    func newEmailURLFromMetadata(_ metadata: MailToMetadata) -> URL? {
        return constructEmailURLString(beginningScheme, metadata: metadata, supportedHeaders: supportedHeaders).asURL
    }
}

class MailRuIntegration: MyMailIntegration {
    override init() {
        super.init()
        self.beginningScheme = "mailru-mailto://?"
    }
}

class MSOutlookIntegration: MailProvider {
    var beginningScheme = "ms-outlook://emails/new?"
    var supportedHeaders = [
        "to",
        "cc",
        "bcc",
        "subject",
        "body"
    ]

    func newEmailURLFromMetadata(_ metadata: MailToMetadata) -> URL? {
        return constructEmailURLString(beginningScheme, metadata: metadata, supportedHeaders: supportedHeaders).asURL
    }
}

class YMailIntegration: MailProvider {
    var beginningScheme = "ymail://mail/any/compose?"
    var supportedHeaders = [
        "to",
        "cc",
        "subject",
        "body"
    ]

    func newEmailURLFromMetadata(_ metadata: MailToMetadata) -> URL? {
        return constructEmailURLString(beginningScheme, metadata: metadata, supportedHeaders: supportedHeaders).asURL
    }
}
