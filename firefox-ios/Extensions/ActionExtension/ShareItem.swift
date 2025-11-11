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

extension NSItemProvider {
    var isText: Bool {
        hasItemConformingToTypeIdentifier(UTType.text.identifier)
    }

    var isURL: Bool {
        hasItemConformingToTypeIdentifier(UTType.url.identifier)
    }

    func loadURL() async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { item, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let url = item as? URL else {
                    continuation.resume(throwing: NSError(
                        domain: "org.mozilla.fennec",
                        code: 999,
                        userInfo: ["Problem": "Non-URL result"]
                    ))
                    return
                }

                continuation.resume(returning: url)
            }
        }
    }

    func loadText() async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            loadItem(forTypeIdentifier: UTType.text.identifier, options: nil) { item, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let text = item as? String else {
                    continuation.resume(throwing: NSError(
                        domain: "org.mozilla.fennec",
                        code: 999,
                        userInfo: ["Problem": "Non-String result"]
                    ))
                    return
                }

                continuation.resume(returning: text)
            }
        }
    }
}
