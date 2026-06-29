// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import CoreGraphics

/// Everything needed to build a Google Lens upload request: the encoded image, its
/// dimensions, and the viewport Lens should render its result UI for.
struct GoogleLensUploadInput: Equatable {
    let jpegData: Data
    let imageDimensions: CGSize
    let viewportSize: CGSize
}

protocol GoogleLensRequestBuilding {
    func makeUploadRequest(for input: GoogleLensUploadInput) -> URLRequest
}

/// Builds the multipart `POST https://lens.google.com/upload` request that uploads an
/// image to Google Lens. The response to this request is the rendered Lens results page.
struct GoogleLensRequestBuilder: GoogleLensRequestBuilding {
    private enum Constants {
        static let uploadURL = "https://lens.google.com/upload"
        /// Entry-point value for the upload-by-bytes (`/upload`) integration, provided by Google.
        static let entryPoint = "fntpubb"
        static let imageFieldName = "encoded_image"
        static let imageFileName = "image.jpg"
        static let imageMimeType = "image/jpeg"
        static let dimensionsFieldName = "processed_image_dimensions"
    }

    private let dateProvider: () -> Date
    private let locale: Locale
    private let boundaryProvider: () -> String

    init(dateProvider: @escaping () -> Date = Date.init,
         locale: Locale = .current,
         boundaryProvider: @escaping () -> String = { UUID().uuidString }) {
        self.dateProvider = dateProvider
        self.locale = locale
        self.boundaryProvider = boundaryProvider
    }

    func makeUploadRequest(for input: GoogleLensUploadInput) -> URLRequest {
        let boundary = boundaryProvider()
        var request = URLRequest(url: uploadURL(for: input))
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)",
                         forHTTPHeaderField: "Content-Type")
        request.httpBody = multipartBody(for: input, boundary: boundary)
        return request
    }

    private func uploadURL(for input: GoogleLensUploadInput) -> URL {
        var queryItems = [
            URLQueryItem(name: "ep", value: Constants.entryPoint),
            URLQueryItem(name: "st", value: String(startTimeMilliseconds())),
            URLQueryItem(name: "vpw", value: String(Int(input.viewportSize.width))),
            URLQueryItem(name: "vph", value: String(Int(input.viewportSize.height)))
        ]
        if let languageCode = languageCode() {
            queryItems.append(URLQueryItem(name: "hl", value: languageCode))
        }

        var components = URLComponents(string: Constants.uploadURL)
        components?.queryItems = queryItems
        return components?.url ?? URL(string: Constants.uploadURL)!
    }

    private func startTimeMilliseconds() -> Int {
        return Int(dateProvider().timeIntervalSince1970 * 1000)
    }

    private func languageCode() -> String? {
        if #available(iOS 16.0, *) {
            return locale.language.languageCode?.identifier
        } else {
            return locale.languageCode
        }
    }

    private func multipartBody(for input: GoogleLensUploadInput, boundary: String) -> Data {
        let dimensions = "\(Int(input.imageDimensions.width)),\(Int(input.imageDimensions.height))"
        var body = Data()

        body.appendString("--\(boundary)\r\n")
        body.appendString("Content-Disposition: form-data; name=\"\(Constants.imageFieldName)\";"
                          + " filename=\"\(Constants.imageFileName)\"\r\n")
        body.appendString("Content-Type: \(Constants.imageMimeType)\r\n\r\n")
        body.append(input.jpegData)
        body.appendString("\r\n")

        body.appendString("--\(boundary)\r\n")
        body.appendString("Content-Disposition: form-data; name=\"\(Constants.dimensionsFieldName)\"\r\n\r\n")
        body.appendString("\(dimensions)\r\n")

        body.appendString("--\(boundary)--\r\n")
        return body
    }
}

private extension Data {
    mutating func appendString(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
