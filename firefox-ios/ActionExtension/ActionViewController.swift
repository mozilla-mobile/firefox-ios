// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import MobileCoreServices
import UIKit
import UniformTypeIdentifiers

class ActionViewController: UIViewController {

    private enum ShareType {
        case url, text
    }

    private var shareType: ShareType = .url
    private var shareContent: String = ""
    private var shareTitle: String?

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Get the item[s] for handling from the extension context
        for item in extensionContext?.inputItems as? [NSExtensionItem] ?? [] {
            for provider in item.attachments ?? [] {

                // Opening browser with site
                if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                    loadAttachmentFor(type: .url, using: provider)
                    break
                } else if provider.hasItemConformingToTypeIdentifier(UTType.text.identifier) ||
                          provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                    // Opening browser with search text
                    loadAttachmentFor(type: .text, using: provider)
                    break
                }
            }
        }
    }

    func done() {
        // Return any edited content to the host app, in this case empty
        extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }

    private func loadAttachmentFor(type: ShareType, using provider: NSItemProvider) {
        let typeIdentifier = type == .text ?
            UTType.plainText.identifier : UTType.url.identifier

        provider.loadItem(forTypeIdentifier: typeIdentifier) { [weak self] item, _ in
            guard let self = self else { return }

            DispatchQueue.main.async {
                self.shareType = type

                switch type {
                case .url:
                    if let url = item as? URL {
                        self.shareContent = url.absoluteString

                        // Try to get title from the item
                        if let itemProvider = provider as NSItemProvider?,
                           itemProvider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                            itemProvider.loadItem(forTypeIdentifier: UTType.plainText.identifier) { titleItem, _ in
                                if let title = titleItem as? String {
                                    self.shareTitle = title
                                }
                                self.promptUserForAction()
                            }
                        } else {
                            self.promptUserForAction()
                        }
                    } else {
                        self.done()
                    }
                case .text:
                    if let text = item as? String {
                        self.shareContent = text
                        self.promptUserForAction()
                    } else {
                        self.done()
                    }
                }
            }
        }
    }

    private func promptUserForAction() {
        // Create and present action sheet
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        // Add actions based on type
        if shareType == .url {
            // URL actions
            alertController.addAction(UIAlertAction(title: "Open in Firefox", style: .default) { _ in
                self.openInFirefox()
            })

            alertController.addAction(UIAlertAction(title: "Load in Background", style: .default) { _ in
                self.loadInBackground()
            })

            alertController.addAction(UIAlertAction(title: "Bookmark This Page", style: .default) { _ in
                self.bookmarkThisPage()
            })

            alertController.addAction(UIAlertAction(title: "Add to Reading List", style: .default) { _ in
                self.addToReadingList()
            })

            alertController.addAction(UIAlertAction(title: "Send to Device", style: .default) { _ in
                self.sendToDevice()
            })
        } else {
            // Text search action
            alertController.addAction(UIAlertAction(title: "Search in Firefox", style: .default) { _ in
                self.searchInFirefox()
            })
        }

        // Cancel action
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
            self.done()
        })

        // Present the action sheet
        present(alertController, animated: true)
    }

    // MARK: - Firefox Actions

    private func openInFirefox() {
        let url = buildFirefoxURL(for: "open-url", with: shareContent)
        openBrowser(with: url)
    }

    private func searchInFirefox() {
        let url = buildFirefoxURL(for: "open-text", with: shareContent)
        openBrowser(with: url)
    }

    private func loadInBackground() {
        // This would require access to Firefox's profile, similar to what's in the ShareViewController
        // Here we use a custom URL scheme to request loading in background
        let url = buildFirefoxURL(for: "load-background", with: shareContent, title: shareTitle)
        openBrowser(with: url)
        showCompletionAlert(with: "Tab loaded in background")
    }

    private func bookmarkThisPage() {
        let url = buildFirefoxURL(for: "bookmark", with: shareContent, title: shareTitle)
        openBrowser(with: url)
        showCompletionAlert(with: "Page bookmarked")
    }

    private func addToReadingList() {
        let url = buildFirefoxURL(for: "reading-list", with: shareContent, title: shareTitle)
        openBrowser(with: url)
        showCompletionAlert(with: "Added to reading list")
    }

    private func sendToDevice() {
        let url = buildFirefoxURL(for: "send-to-device", with: shareContent, title: shareTitle)
        openBrowser(with: url)
        // This would typically launch a UI in Firefox to select devices
        done()
    }

    // MARK: - Helper Methods

    private func buildFirefoxURL(for action: String, with content: String, title: String? = nil) -> URL? {
        var components = URLComponents()
        components.scheme = "firefox"
        components.host = action

        var queryItems = [URLQueryItem]()

        if action == "open-url" || action == "bookmark" || action == "reading-list" || action == "load-background" || action == "send-to-device" {
            queryItems.append(URLQueryItem(name: "url", value: content))

            if let title = title {
                queryItems.append(URLQueryItem(name: "title", value: title))
            }
        } else if action == "open-text" {
            queryItems.append(URLQueryItem(name: "text", value: content))
        }

        components.queryItems = queryItems
        return components.url
    }

    private func openBrowser(with url: URL?) {
        guard let url = url else {
            done()
            return
        }

        var responder: UIResponder? = self
        while let currentResponder = responder {
            if #available(iOS 18.0, *) {
                if let application = currentResponder as? UIApplication {
                    application.open(url, options: [:], completionHandler: nil)
                    break
                }
            } else {
                let selectorOpenURL = sel_registerName("openURL:")
                if currentResponder.responds(to: selectorOpenURL) {
                    currentResponder.perform(selectorOpenURL, with: url, afterDelay: 0)
                    break
                }
            }
            responder = currentResponder.next
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.done()
        }
    }

    private func showCompletionAlert(with message: String) {
        let alert = UIAlertController(title: "Success", message: message, preferredStyle: .alert)
        present(alert, animated: true)

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            alert.dismiss(animated: true) {
                self.done()
            }
        }
    }
}
