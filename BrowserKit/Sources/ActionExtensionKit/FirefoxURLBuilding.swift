// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public protocol FirefoxURLBuilding {
    func buildFirefoxURL(from shareItem: ExtractedShareItem) -> URL?
    func findURLInItems(_ items: [NSExtensionItem], completion: @escaping (Result<ActionShareItem, Error>) -> Void)
    func findTextInItems(_ items: [NSExtensionItem], completion: @escaping (Result<ExtractedShareItem, Error>) -> Void)
    func convertTextToURL(_ text: String) -> URL?
}

public enum ShareExtensionError: Error {
    case noURLFound
    case noTextFound
}

public struct FirefoxURLBuilder: FirefoxURLBuilding, Sendable {
    public let mozInternalScheme: String = {
        guard let string = Bundle.main.object(
            forInfoDictionaryKey: "MozInternalURLScheme"
        ) as? String, !string.isEmpty else {
            // Something went wrong/weird, fallback to the public one.
            return "firefox"
        }
        return string
    }()

    public init() {}

    public func buildFirefoxURL(from shareItem: ExtractedShareItem) -> URL? {
        let (content, isSearch) = switch shareItem {
        case .shareItem(let item):
            (item.url, false)
        case .rawText(let text):
            (text, true)
        }

        guard let encodedContent = content.addingPercentEncoding(withAllowedCharacters: .alphanumerics) else {
            return nil
        }

        let urlString = isSearch
        ? "\(mozInternalScheme)://open-text?text=\(encodedContent)&openWithFirefox=true"
        : "\(mozInternalScheme)://open-url?url=\(encodedContent)&openWithFirefox=true"

        return URL(string: urlString)
    }

    public func findURLInItems(_ items: [NSExtensionItem], completion: @escaping (Result<ActionShareItem, Error>) -> Void) {
        let group = DispatchGroup()
        // TODO: FXIOS-14296 These should be made actually threadsafe
        nonisolated(unsafe) var foundShareItem: ActionShareItem?
        nonisolated(unsafe) var lastError: Error?

        for item in items {
            guard let attachments = item.attachments else { continue }

            for attachment in attachments where attachment.isURL {
                group.enter()

                let title = item.attributedContentText?.string
                attachment.loadURL { result in
                    defer { group.leave() }

                    switch result {
                    case .success(let url):
                        if foundShareItem == nil {
                            foundShareItem = ActionShareItem(url: url.absoluteString, title: title)
                        }
                    case .failure(let error):
                        lastError = error
                    }
                }
            }
        }

        group.notify(queue: .main) {
            if let shareItem = foundShareItem {
                completion(.success(shareItem))
            } else {
                completion(.failure(lastError ?? ShareExtensionError.noURLFound))
            }
        }
    }

    public func findTextInItems(
        _ items: [NSExtensionItem],
        completion: @escaping (Result<ExtractedShareItem, Error>) -> Void
    ) {
        let group = DispatchGroup()
        // TODO: FXIOS-14296 These should be made actually threadsafe
        nonisolated(unsafe) var foundItem: ExtractedShareItem?
        nonisolated(unsafe) var lastError: Error?

        for item in items {
            guard let attachments = item.attachments else { continue }

            for attachment in attachments where attachment.isText {
                group.enter()

                attachment.loadText { result in
                    defer { group.leave() }

                    switch result {
                    case .success(let text):
                        if foundItem == nil {
                            if let url = convertTextToURL(text) {
                                foundItem = .shareItem(ActionShareItem(url: url.absoluteString, title: nil))
                            } else {
                                foundItem = .rawText(text)
                            }
                        }
                    case .failure(let error):
                        lastError = error
                    }
                }
            }
        }

        group.notify(queue: .main) {
            if let item = foundItem {
                completion(.success(item))
            } else {
                completion(.failure(lastError ?? ShareExtensionError.noTextFound))
            }
        }
    }

    public func convertTextToURL(_ text: String) -> URL? {
        guard text.contains(".") else {
            return nil
        }

        var urlString = text
        if !urlString.hasPrefix("http") {
            urlString = "http://\(urlString)"
        }

        guard let url = URL(string: urlString),
              let host = url.host,
              !host.isEmpty,
              host.contains(".") else {
            return nil
        }

        // Validate host format: no consecutive dots, no leading/trailing dots
        if host.contains("..") || host.hasPrefix(".") || host.hasSuffix(".") {
            return nil
        }

        return url
    }
}
