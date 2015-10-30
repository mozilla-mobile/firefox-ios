/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import FxA
import Shared

public class HawkHelper {
    private let NonceLengthInBytes: UInt = 8

    let id: String
    let key: NSData

    public init(id: String, key: NSData) {
        self.id = id
        self.key = key
    }

    // Produce a HAWK value suitable for an "Authorization: value" header, timestamped now.
    public func getAuthorizationValueFor(request: NSURLRequest) -> String {
        let timestampInSeconds: Int64 = Int64(NSDate().timeIntervalSince1970)
        return getAuthorizationValueFor(request, at: timestampInSeconds)
    }

    // Produce a HAWK value suitable for an "Authorization: value" header.
    func getAuthorizationValueFor(request: NSURLRequest, at timestampInSeconds: Int64) -> String {
        let nonce = NSData.randomOfLength(NonceLengthInBytes)!.base64EncodedString
        let extra = ""
        return getAuthorizationValueFor(request, at: timestampInSeconds, nonce: nonce, extra: extra)
    }

    func getAuthorizationValueFor(request: NSURLRequest, at timestampInSeconds: Int64, nonce: String, extra: String) -> String {
        let timestampString = String(timestampInSeconds)
        let hashString = HawkHelper.getPayloadHashFor(request)
        let requestString = HawkHelper.getRequestStringFor(request, timestampString: timestampString, nonce: nonce, hash: hashString, extra: extra)
        let macString = HawkHelper.getSignatureFor(requestString.utf8EncodedData!, key: self.key)

        let s = NSMutableString(string: "Hawk ")
        func append(key: String, value: String) -> Void {
            s.appendString(key)
            s.appendString("=\"")
            s.appendString(value)
            s.appendString("\", ")
        }
        append("id", value: id)
        append("ts", value: timestampString)
        append("nonce", value: nonce)
        if !hashString.isEmpty {
            append("hash", value: hashString)
        }
        if !extra.isEmpty {
            append("ext", value: HawkHelper.escapeExtraHeaderAttribute(extra))
        }
        append("mac", value: macString)
        // Drop the trailing "\",".
        return s.substringToIndex(s.length - 2)
    }

    class func getSignatureFor(input: NSData, key: NSData) -> String {
        return input.hmacSha256WithKey(key).base64EncodedString
    }

    class func getRequestStringFor(request: NSURLRequest, timestampString: String, nonce: String, hash: String, extra: String) -> String {
        let s = NSMutableString(string: "hawk.1.header\n")
        func append(line: String) -> Void {
            s.appendString(line)
            s.appendString("\n")
        }
        append(timestampString)
        append(nonce)
        append(request.HTTPMethod?.uppercaseString ?? "GET")
        let url = request.URL!
        s.appendString(url.path!)
        if let query = url.query {
            s.appendString("?")
            s.appendString(query)
        }
        if let fragment = url.fragment {
            s.appendString("#")
            s.appendString(fragment)
        }
        s.appendString("\n")
        append(url.host!)
        if let port = url.port {
            append(port.stringValue)
        } else {
            if url.scheme.lowercaseString == "https" {
                append("443")
            } else {
                append("80")
            }
        }
        append(hash)
        if !extra.isEmpty {
            append(HawkHelper.escapeExtraString(extra))
        } else {
            append("")
        }
        return s as String
    }

    class func getPayloadHashFor(request: NSURLRequest) -> String {
        if let body = request.HTTPBody {
            let d = NSMutableData()
            func append(s: String) {
                let data = s.utf8EncodedData!
                d.appendBytes(data.bytes, length: data.length)
            }
            append("hawk.1.payload\n")
            append(getBaseContentTypeFor(request.valueForHTTPHeaderField("Content-Type")))
            append("\n") // Trailing newline is specified by Hawk.
            d.appendBytes(body.bytes, length: body.length)
            append("\n") // Trailing newline is specified by Hawk.
            return d.sha256.base64EncodedString
        } else {
            return ""
        }
    }

    class func getBaseContentTypeFor(contentType: String?) -> String {
        if let contentType = contentType {
            if let index = contentType.characters.indexOf(";") {
                return contentType.substringToIndex(index).stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
            } else {
                return contentType.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
            }
        } else {
            return "text/plain"
        }
    }

    class func escapeExtraHeaderAttribute(extra: String) -> String {
        return extra.stringByReplacingOccurrencesOfString("\\", withString: "\\\\").stringByReplacingOccurrencesOfString("\"", withString: "\\\"")
    }

    class func escapeExtraString(extra: String) -> String {
        return extra.stringByReplacingOccurrencesOfString("\\", withString: "\\\\").stringByReplacingOccurrencesOfString("\n", withString: "\\n")
    }
}
