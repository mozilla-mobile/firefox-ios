// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import UniformTypeIdentifiers

@MainActor
final class ActionViewController: UIViewController {
    private let firefoxURLBuilder: FirefoxURLBuilding

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        self.firefoxURLBuilder = FirefoxURLBuilder()
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    init(firefoxURLBuilder: FirefoxURLBuilding) {
        self.firefoxURLBuilder = firefoxURLBuilder
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()

        // TODO: - Refactor with completions
        Task {
            await handleShareExtension()
        }
    }

    private func setupView() {
        view.backgroundColor = .clear
        view.alpha = 0
    }

    private func handleShareExtension() async {
        guard let extensionContext = extensionContext,
              let inputItems = extensionContext.inputItems as? [NSExtensionItem] else {
            finishExtension(with: nil)
            return
        }

        if let shareItem = await findURLInItems(inputItems) {
            openFirefox(with: .shareItem(shareItem))
            return
        }

        if let textShareItem = await findTextInItems(inputItems) {
            openFirefox(with: textShareItem)
        } else {
            finishExtension(with: nil)
        }
    }

    // TODO: - move it to FirefoxURLBuilding - so we can test it easily
    private func findURLInItems(_ items: [NSExtensionItem]) async -> ShareItem? {
        for item in items {
            guard let attachments = item.attachments else { continue }

            for attachment in attachments where attachment.isURL {
                let title = item.attributedContentText?.string

                do {
                    let url = try await attachment.loadURL()
                    return ShareItem(url: url.absoluteString, title: title)
                } catch {
                    continue
                }
            }
        }

        return nil
    }

    private func findTextInItems(_ items: [NSExtensionItem]) async -> ExtractedShareItem? {
        for item in items {
            guard let attachments = item.attachments else { continue }

            for attachment in attachments where attachment.isText {
                do {
                    let text = try await attachment.loadText()

                    if let url = convertTextToURL(text) {
                        return .shareItem(ShareItem(url: url.absoluteString, title: nil))
                    } else {
                        return .rawText(text)
                    }
                } catch {
                    continue
                }
            }
        }

        return nil
    }

    // TODO: - Move to FirefoxURLBuidling
    private func convertTextToURL(_ text: String) -> URL? {
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

        return url
    }

    private func openFirefox(with shareItem: ExtractedShareItem) {
        let (content, isSearch) = extractContentAndType(from: shareItem)

        guard let firefoxURL = firefoxURLBuilder.buildFirefoxURL(for: content, isSearch: isSearch) else {
            finishExtension(with: nil)
            return
        }

        openURL(firefoxURL)
        finishExtension(with: nil)
    }

    private func extractContentAndType(from shareItem: ExtractedShareItem) -> (content: String, isSearch: Bool) {
        switch shareItem {
        case .shareItem(let item):
            return (item.url, false)
        case .rawText(let text):
            return (text, true)
        }
    }

    private func openURL(_ url: URL) {
        var responder: UIResponder? = self

        while let current = responder {
            if let application = current as? UIApplication {
                application.open(url, options: [:], completionHandler: nil)
                return
            }
            responder = current.next
        }
    }

    private func finishExtension(with error: Error?) {
        if let error {
            extensionContext?.cancelRequest(withError: error)
        } else {
            extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
        }
    }
}
