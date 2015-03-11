/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Alamofire
import Foundation
import FxA

class HawkHelper {
    private let NonceLengthInBytes: UInt = 8

    let id: String
    let key: NSData

    init(id: String, key: NSData) {
        self.id = id
        self.key = key
    }

    // Produce a HAWK value suitable for an "Authorization: value" header.
    func getAuthorizationValueFor(request: Alamofire.Request, at timestampInSeconds: Int) -> String {
        let nonce = NSData.randomOfLength(NonceLengthInBytes)!.base64EncodedString
        let extra = ""
        return getAuthorizationValueFor(request, at: timestampInSeconds, nonce: nonce, extra: extra)
    }

    func getAuthorizationValueFor(request: Alamofire.Request, at timestampInSeconds: Int, nonce: String, extra: String) -> String {
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
        append("id", id)
        append("ts", timestampString)
        append("nonce", nonce)
        if !hashString.isEmpty {
            append("hash", hashString)
        }
        if !extra.isEmpty {
            append("ext", HawkHelper.escapeExtraHeaderAttribute(extra))
        }
        append("mac", macString)
        // Drop the trailing "\",".
        return s.substringToIndex(s.length - 2)
    }

    class func getSignatureFor(input: NSData, key: NSData) -> String {
        return input.hmacSha256WithKey(key).base64EncodedString
    }

    class func getRequestStringFor(request: Alamofire.Request, timestampString: String, nonce: String, hash: String, extra: String) -> String {
        let s = NSMutableString(string: "hawk.1.header\n")
        func append(line: String) -> Void {
            s.appendString(line)
            s.appendString("\n")
        }
        append(timestampString)
        append(nonce)
        append(request.request.HTTPMethod?.uppercaseString ?? "GET")
        let url = request.request.URL
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
        append(url.port!.stringValue)
        append(hash)
        if !extra.isEmpty {
            append(HawkHelper.escapeExtraString(extra))
        } else {
            append("")
        }
        return s
    }

    class func getPayloadHashFor(request: Alamofire.Request) -> String {
        if let body = request.request.HTTPBody {
            let d = NSMutableData()
            func append(s: String) {
                let data = s.utf8EncodedData!
                d.appendBytes(data.bytes, length: data.length)
            }
            append("hawk.1.payload\n")
            append(getBaseContentTypeFor(request.request.valueForHTTPHeaderField("Content-Type")))
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
            if let index = find(contentType, ";") {
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
