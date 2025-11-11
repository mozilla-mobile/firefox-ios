// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UniformTypeIdentifiers

struct ShareItem {
    let url: String
    let title: String?
}

enum ExtractedShareItem {
    case shareItem(ShareItem)
    case rawText(String)
}

// MARK: - NSItemProvider Extensions

extension NSItemProvider {
    var isText: Bool {
        hasItemConformingToTypeIdentifier(UTType.text.identifier)
    }

    var isURL: Bool {
        hasItemConformingToTypeIdentifier(UTType.url.identifier)
    }
}
