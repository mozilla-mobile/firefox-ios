// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/**
 *  Data structure containing metadata associated with a mailto: link. For additional details,
 *  see RFC 2368 https://tools.ietf.org/html/rfc2368
 */
public struct MailToMetadata {
    public let to: String
    public let headers: [String: String]
}

public extension URL {
    /**
     Extracts the metadata associated with a mailto: URL according to RFC 2368
     https://tools.ietf.org/html/rfc2368
     */
    func mailToMetadata() -> MailToMetadata? {
        guard scheme == "mailto",
              let components = URLComponents(url: self,
                                             resolvingAgainstBaseURL: false)
        else { return nil }

        let toEmail = components.path
        let queryItems = components.queryItems

        var headers = [String: String]()

        guard let queryItems = queryItems else {
            if toEmail.isEmpty {
                return nil
            }
            return MailToMetadata(to: toEmail, headers: headers)
        }

        queryItems.forEach { queryItem in
            guard let value = queryItem.value else { return }

            headers[queryItem.name] = value
        }

        return MailToMetadata(to: toEmail, headers: headers)
    }
}
