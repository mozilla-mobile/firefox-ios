/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import FxA
import Shared

open class HawkHelper {
    fileprivate let nonceLengthInBytes: UInt = 8

    let id: String
    let key: Data

    public init(id: String, key: Data) {
        self.id = id
        self.key = key
    }

    // Produce a HAWK value suitable for an "Authorization: value" header, timestamped now.
    open func getAuthorizationValueFor(_ request: URLRequest) -> String {
        let timestampInSeconds: Int64 = Int64(Date().timeIntervalSince1970)
        return getAuthorizationValueFor(request, at: timestampInSeconds)
    }

    // Produce a HAWK value suitable for an "Authorization: value" header.
    func getAuthorizationValueFor(_ request: URLRequest, at timestampInSeconds: Int64) -> String {
        let nonce = Data.randomOfLength(nonceLengthInBytes)!.base64EncodedString
        let extra = ""
        return getAuthorizationValueFor(request, at: timestampInSeconds, nonce: nonce, extra: extra)
    }

    func getAuthorizationValueFor(_ request: URLRequest, at timestampInSeconds: Int64, nonce: String, extra: String) -> String {
        let timestampString = String(timestampInSeconds)
        let hashString = HawkHelper.getPayloadHashFor(request)
        let requestString = HawkHelper.getRequestStringFor(request, timestampString: timestampString, nonce: nonce, hash: hashString, extra: extra)
        let macString = HawkHelper.getSignatureFor(requestString.utf8EncodedData, key: self.key)

        let s = NSMutableString(string: "Hawk ")
        func append(_ key: String, value: String) -> Void {
            s.append(key)
            s.append("=\"")
            s.append(value)
            s.append("\", ")
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
        return s.substring(to: s.length - 2)
    }

    class func getSignatureFor(_ input: Data, key: Data) -> String {
        return input.hmacSha256WithKey(key).base64EncodedString
    }

    class func getRequestStringFor(_ request: URLRequest, timestampString: String, nonce: String, hash: String, extra: String) -> String {
        let s = NSMutableString(string: "hawk.1.header\n")
        func append(_ line: String) -> Void {
            s.append(line)
            s.append("\n")
        }
        append(timestampString)
        append(nonce)
        append((request as NSURLRequest).httpMethod?.uppercased() ?? "GET")
        let url = request.url!
        s.append(url.path)
        if let query = url.query {
            s.append("?")
            s.append(query)
        }
        if let fragment = url.fragment {
            s.append("#")
            s.append(fragment)
        }
        s.append("\n")
        append(url.host!)
        if let port = (url as NSURL).port {
            append(port.stringValue)
        } else {
            if url.scheme?.lowercased() == "https" {
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

    class func getPayloadHashFor(_ request: URLRequest) -> String {
        if let body = request.httpBody {
            let d = NSMutableData()
            func append(_ s: String) {
                let data = s.utf8EncodedData
                d.appendBytes(data.bytes, length: data.length)
            }
            append("hawk.1.payload\n")
            append(getBaseContentTypeFor(request.value(forHTTPHeaderField: "Content-Type")))
            append("\n") // Trailing newline is specified by Hawk.
            d.append((body as NSData).bytes, length: body.count)
            append("\n") // Trailing newline is specified by Hawk.
            return d.sha256.base64EncodedString
        } else {
            return ""
        }
    }

    class func getBaseContentTypeFor(_ contentType: String?) -> String {
        if let contentType = contentType {
            if let index = contentType.characters.index(of: ";") {
                return contentType.substring(to: index).trimmingCharacters(in: CharacterSet.whitespaces)
            } else {
                return contentType.trimmingCharacters(in: CharacterSet.whitespaces)
            }
        } else {
            return "text/plain"
        }
    }

    class func escapeExtraHeaderAttribute(_ extra: String) -> String {
        return extra.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"")
    }

    class func escapeExtraString(_ extra: String) -> String {
        return extra.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\n", with: "\\n")
    }
}

extension NSMutableURLRequest {
    func addAuthorizationHeader(forHKDFSHA256Key bytes: Data) {
        let tokenId = bytes.subdata(in: NSMakeRange(0 * KeyLength, KeyLength))
        let reqHMACKey = bytes.subdata(in: NSMakeRange(1 * KeyLength, KeyLength))
        let hawkHelper = HawkHelper(id: tokenId.hexEncodedString, key: reqHMACKey)
        let hawkValue = hawkHelper.getAuthorizationValueFor(self)
        setValue(hawkValue, forHTTPHeaderField: "Authorization")
    }
}
