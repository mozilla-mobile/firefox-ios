// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UniformTypeIdentifiers

struct MIMEType {
    static let Bitmap = "image/bmp"
    static let CSS = "text/css"
    static let GIF = "image/gif"
    static let JavaScript = "text/javascript"
    static let JPEG = "image/jpeg"
    static let HTML = "text/html"
    static let OctetStream = "application/octet-stream"
    static let Passbook = "application/vnd.apple.pkpass"
    static let PDF = "application/pdf"
    static let PlainText = "text/plain"
    static let PNG = "image/png"
    static let WebP = "image/webp"
    static let Calendar = "text/calendar"
    static let USDZ = "model/vnd.usdz+zip"
    static let Reality = "model/vnd.reality"
    static let OpenDocument = "application/msword"
    static let MicrosoftWord = "application/vnd.openxmlformats-officedocument.wordprocessingml.document"

    private static let webViewViewableTypes: [String] = [
        MIMEType.Bitmap,
        MIMEType.GIF,
        MIMEType.JPEG,
        MIMEType.HTML,
        MIMEType.PDF,
        MIMEType.PlainText,
        MIMEType.PNG,
        MIMEType.WebP
    ]

    private static let downloadableTypes: [String] = [
        MIMEType.PDF,
        MIMEType.OpenDocument,
        MIMEType.MicrosoftWord,
        MIMEType.PNG,
        MIMEType.JPEG
    ]

    static func canShowInWebView(_ mimeType: String) -> Bool {
        return webViewViewableTypes.contains(mimeType.lowercased())
    }

    static func canBeDownloaded(_ mimeType: String?) -> Bool {
        guard let mimeType else { return false }
        return downloadableTypes.contains(mimeType.lowercased())
    }

    static func mimeTypeFromFileExtension(_ fileExtension: String) -> String {
        if let uti = UTType(filenameExtension: fileExtension),
           let mimeType = uti.preferredMIMEType {
            return mimeType as String
        }

        return MIMEType.OctetStream
    }

    static func fileExtensionFromMIMEType(_ mimeType: String) -> String? {
        if let uti = UTType(mimeType: mimeType),
           let fileExtension = uti.preferredFilenameExtension {
            return fileExtension as String
        }
        return nil
    }
}
