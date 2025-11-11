// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import UniformTypeIdentifiers

final class ActionViewController: UIViewController {
    private let firefoxURLBuilder: FirefoxURLBuilding
    private let telemetryService: TelemetryRecording

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        self.firefoxURLBuilder = FirefoxURLBuilder()
        self.telemetryService = TelemetryService()
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required init?(coder: NSCoder) {
        self.firefoxURLBuilder = FirefoxURLBuilder()
        self.telemetryService = TelemetryService()
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        handleShareExtension()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        view.alpha = 0
    }

    private func setupView() {
        view.backgroundColor = .clear
        view.alpha = 0
    }

    private func handleShareExtension() {
        guard let extensionContext = extensionContext,
              let inputItems = extensionContext.inputItems as? [NSExtensionItem] else {
            finishExtension(with: nil)
            return
        }

        findURLInItems(inputItems) { [weak self] shareItem in
            guard let self = self else { return }

            if let shareItem = shareItem {
                self.openFirefox(with: .shareItem(shareItem))
                return
            }

            self.findTextInItems(inputItems) { textShareItem in
                if let textShareItem = textShareItem {
                    self.openFirefox(with: textShareItem)
                } else {
                    self.finishExtension(with: nil)
                }
            }
        }
    }

    private func findURLInItems(_ items: [NSExtensionItem], completion: @escaping (ShareItem?) -> Void) {
        for item in items {
            guard let attachments = item.attachments else { continue }

            for attachment in attachments where attachment.isURL {
                let title = item.attributedContentText?.string

                attachment.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { obj, error in
                    guard error == nil, let url = obj as? URL else {
                        return
                    }

                    DispatchQueue.main.async {
                        completion(ShareItem(url: url.absoluteString, title: title))
                    }
                }
                return
            }
        }

        completion(nil)
    }

    private func findTextInItems(_ items: [NSExtensionItem], completion: @escaping (ExtractedShareItem?) -> Void) {
        for item in items {
            guard let attachments = item.attachments else { continue }

            for attachment in attachments where attachment.isText {
                attachment.loadItem(forTypeIdentifier: UTType.text.identifier, options: nil) { [weak self] obj, error in
                    guard error == nil, let text = obj as? String else {
                        return
                    }

                    DispatchQueue.main.async {
                        if let url = self?.convertTextToURL(text) {
                            completion(.shareItem(ShareItem(url: url.absoluteString, title: nil)))
                        } else {
                            completion(.rawText(text))
                        }
                    }
                }
                return
            }
        }

        completion(nil)
    }

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
        telemetryService.recordShareExtensionOpened()

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
        if #available(iOS 18.0, *) {
            openURLModern(url)
        } else {
            openURLLegacy(url)
        }
    }

    private func openURLModern(_ url: URL) {
        var responder: UIResponder? = self

        while let current = responder {
            if let application = current as? UIApplication {
                application.open(url, options: [:], completionHandler: nil)
                return
            }
            responder = current.next
        }
    }

    private func openURLLegacy(_ url: URL) {
        let selector = sel_registerName("openURL:")
        var responder: UIResponder? = self

        while let current = responder {
            if current.responds(to: selector) {
                current.perform(selector, with: url, afterDelay: 0)
                return
            }
            responder = current.next
        }
    }

    private func finishExtension(with error: Error?, afterDelay delay: TimeInterval = 0) {
        UIView.animate(withDuration: 0.2, delay: delay, animations: {
            self.view.alpha = 0
        }) { [weak self] _ in
            if let error = error {
                self?.extensionContext?.cancelRequest(withError: error)
            } else {
                self?.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
            }
        }
    }
}
