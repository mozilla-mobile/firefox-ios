// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UniformTypeIdentifiers

public struct ActionShareItem: Sendable {
    public let url: String
    public let title: String?

    public init(url: String, title: String?) {
        self.url = url
        self.title = title
    }
}

public enum ExtractedShareItem: Sendable {
    case shareItem(ActionShareItem)
    case rawText(String)
}

public extension NSItemProvider {
    var isText: Bool {
        hasItemConformingToTypeIdentifier(UTType.text.identifier)
    }

    var isURL: Bool {
        hasItemConformingToTypeIdentifier(UTType.url.identifier)
    }

    func loadURL(completion: @Sendable @escaping (Result<URL, Error>) -> Void) {
        loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { item, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let url = item as? URL else {
                let error = NSError(
                    domain: "org.mozilla.fennec",
                    code: 999,
                    userInfo: ["Problem": "Non-URL result"]
                )
                completion(.failure(error))
                return
            }

            completion(.success(url))
        }
    }

    func loadText(completion: @Sendable @escaping (Result<String, Error>) -> Void) {
        loadItem(forTypeIdentifier: UTType.text.identifier, options: nil) { item, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let text = item as? String else {
                let error = NSError(
                    domain: "org.mozilla.fennec",
                    code: 999,
                    userInfo: ["Problem": "Non-String result"]
                )
                completion(.failure(error))
                return
            }

            completion(.success(text))
        }
    }
}
