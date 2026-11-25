// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Shared

struct NativeErrorPageURL {
    private enum Param: String {
        case code
        case type
        case badcert
    }

    let internalURL: InternalURL
    let type: NativeErrorPageType
    let originalURL: URL
    let errorCode: Int
    let certificateData: Data?

    var url: URL { internalURL.url }

    init?(internalURL: InternalURL) {
        guard internalURL.isErrorPage,
              let queryItems = URLComponents(url: internalURL.url, resolvingAgainstBaseURL: false)?.queryItems,
              let urlString = Self.value(for: InternalURL.Param.url.rawValue, in: queryItems),
              let originalURL = URL(string: urlString),
              let codeString = Self.value(for: Param.code.rawValue, in: queryItems),
              let errorCode = Int(codeString)
        else { return nil }

        self.internalURL = internalURL
        self.originalURL = originalURL
        self.errorCode = errorCode

        if let certString = Self.value(for: Param.badcert.rawValue, in: queryItems) {
            self.certificateData = Data(base64Encoded: certString)
        } else {
            self.certificateData = nil
        }

        if let typeString = Self.value(for: Param.type.rawValue, in: queryItems),
           let type = NativeErrorPageType(rawValue: typeString) {
            self.type = type
        } else {
            self.type = .generic
        }
    }

    static func make(
        type: NativeErrorPageType,
        originalURL: URL,
        errorCode: Int,
        certificateData: Data? = nil
    ) -> NativeErrorPageURL? {
        var components = URLComponents(string: "\(InternalURL.baseUrl)/\(ErrorPageHandler.path)")
        components?.queryItems = [
            URLQueryItem(name: InternalURL.Param.url.rawValue, value: originalURL.absoluteString),
            URLQueryItem(name: Param.code.rawValue, value: String(errorCode)),
            URLQueryItem(name: Param.type.rawValue, value: type.rawValue)
        ]
        if let certificateData {
            components?.queryItems?.append(URLQueryItem(name: Param.badcert.rawValue,
                                                        value: certificateData.base64EncodedString()))
        }

        guard let url = components?.url, let internalURL = InternalURL(url) else { return nil }
        return NativeErrorPageURL(internalURL: internalURL)
    }

    private static func value(for name: String, in queryItems: [URLQueryItem]) -> String? {
        return queryItems.first { $0.name == name }?.value
    }
}

extension NativeErrorPageURL: Equatable {
    static func == (lhs: NativeErrorPageURL, rhs: NativeErrorPageURL) -> Bool {
        return lhs.type == rhs.type
            && lhs.originalURL == rhs.originalURL
            && lhs.errorCode == rhs.errorCode
            && lhs.certificateData == rhs.certificateData
    }
}
