// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftSoup

extension Document {
    var isSafariFormat: Bool {
        if let leadingDL = try? select(.dl).first(), leadingDL.parents().size() > 2 {
            return true
        }
        return false
    }

    func normalizedDocumentIfRequired() throws -> Document {
        isSafariFormat ? try normalizedSafariExport() : self
    }
}

private extension Document {
    func normalizedSafariExport() throws -> Document {
        guard let body = try select("body").first() else {
            throw BookmarkParserError.noBody
        }

        let newDocument = Document("")
        let dlElement = try newDocument.appendElement("DL")
        let bodyChildren = body.getChildNodes()
        try dlElement.insertChildren(0, bodyChildren)

        return newDocument
    }
}
