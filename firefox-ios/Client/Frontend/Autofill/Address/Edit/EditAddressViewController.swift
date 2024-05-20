// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import WebKit
import Storage
import SwiftUI
import Common

class EditAddressViewController: UIViewController, WKNavigationDelegate, WKScriptMessageHandler {
    private lazy var webView: WKWebView = {
        let webConfiguration = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.navigationDelegate = self
        return webView
    }()

    var model: AddressListViewModel
    private let logger: Logger

    init(model: AddressListViewModel, logger: Logger = DefaultLogger.shared) {
        self.model = model
        self.logger = logger
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = webView
        setupWebView()
    }

    private func setupWebView() {
        if let url = Bundle.main.url(forResource: "AddressFormManager", withExtension: "html") {
            let request = URLRequest(url: url)
            webView.loadFileURL(url, allowingReadAccessTo: url)
            webView.load(request)
        }
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {}

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        guard let address = model.selectedAddress else { return }
        injectJSONDataInit(address: address, editAddressL10n: .editAddressLocalizationIDs)
    }

    private func jsonString<T: Encodable>(from object: T) throws -> String {
        let encoder = JSONEncoder()
        encoder.userInfo[.formatStyleKey] = FormatStyle.kebabCase
        let data = try encoder.encode(object)
        guard let jsonString = String(data: data, encoding: .utf8) else {
            throw EncodingError.invalidValue(
                object,
                EncodingError.Context(codingPath: [], debugDescription: "Unable to convert data to String")
            )
        }
        return jsonString.replacingOccurrences(of: "\\", with: "\\\\")
    }

    private func injectJSONDataInit(address: Address, editAddressL10n: EditAddressLocalization) {
        do {
            let addressString = try jsonString(from: address)
            let l10sString = try jsonString(from: editAddressL10n)

            let javascript = "init(\(addressString), \(l10sString));"
            webView.evaluateJavaScript(javascript) { (result, error) in
                if let error = error {
                    self.logger.log("Error evaluating JavaScript",
                                    level: .warning,
                                    category: .autofill,
                                    description: "Error evaluating JavaScript: \(error.localizedDescription)")
                } else {
                    self.logger.log("JavaScript evaluated successfully",
                                    level: .info,
                                    category: .autofill,
                                    description: "JavaScript evaluated successfully")
                }
            }
        } catch {
            self.logger.log("Failed to encode data",
                            level: .warning,
                            category: .autofill,
                            description: "Failed to encode data with error: \(error.localizedDescription)")
        }
    }

    private func evaluateJavaScript(_ jsCode: String) {
        webView.evaluateJavaScript(jsCode) { result, error in
            if let error = error {
                self.logger.log("JavaScript execution error",
                                level: .warning,
                                category: .autofill,
                                description: "JavaScript execution error: \(error.localizedDescription)")
            }
        }
    }
}

struct EditAddressViewControllerRepresentable: UIViewControllerRepresentable {
    typealias UIViewControllerType = EditAddressViewController

    var model: AddressListViewModel

    func makeUIViewController(context: Context) -> EditAddressViewController {
        let webViewController = EditAddressViewController(model: model)
        return webViewController
    }

    func updateUIViewController(_ uiViewController: EditAddressViewController, context: Context) {
        // Here you can update the view controller when your SwiftUI state changes.
        // Since the WebModel is passed at creation, there might not be much to do here.
    }
}
