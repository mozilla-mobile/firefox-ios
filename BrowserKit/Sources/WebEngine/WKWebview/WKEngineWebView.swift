// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import WebKit

protocol WKEngineWebViewDelegate: AnyObject {
    func tabWebView(_ webView: WKEngineWebView, findInPageSelection: String)
    func tabWebView(_ webView: WKEngineWebView, searchSelection: String)
    func tabWebViewInputAccessoryView(_ webView: WKEngineWebView) -> EngineInputAccessoryView
}

/// Abstraction on top of the `WKWebView`
protocol WKEngineWebView: UIView {
    var navigationDelegate: WKNavigationDelegate? { get set }
    var uiDelegate: WKUIDelegate? { get set }
    var delegate: WKEngineWebViewDelegate? { get set }

    var allowsBackForwardNavigationGestures: Bool { get set }
    var allowsLinkPreview: Bool { get set }
    var backgroundColor: UIColor? { get set }
    var interactionState: Any? { get set }
    var url: URL? { get }
    var title: String? { get }
    var engineScrollView: WKScrollView! { get }
    var engineConfiguration: WKEngineConfiguration { get }
    var hasOnlySecureContent: Bool { get }

    var estimatedProgress: Double { get }
    var canGoBack: Bool { get }
    var canGoForward: Bool { get }

    @available(iOS 16.4, *)
    var isInspectable: Bool { get set }

    init?(frame: CGRect, configurationProvider: WKEngineConfigurationProvider)

    @discardableResult
    func load(_ request: URLRequest) -> WKNavigation?

    @discardableResult
    func loadFileURL(_ URL: URL,
                     allowingReadAccessTo readAccessURL: URL) -> WKNavigation?

    @discardableResult
    func reloadFromOrigin() -> WKNavigation?

    func stopLoading()

    func goBack() -> WKNavigation?

    func goForward() -> WKNavigation?

    func evaluateJavaScript(
        _ javaScript: String,
        in frame: WKFrameInfo?,
        in contentWorld: WKContentWorld,
        completionHandler: ((Result<Any, Error>) -> Void)?
    )

    func removeAllUserScripts()
    func removeFromSuperview()

    // MARK: Custom WKEngineView functions

    /// Use JS to redirect the page without adding a history entry
    /// - Parameter url: The URL to replace the location with
    func replaceLocation(with url: URL)

    func addObserver(
        _ observer: NSObject,
        forKeyPath keyPath: String,
        options: NSKeyValueObservingOptions,
        context: UnsafeMutableRawPointer?
    )

    func removeObserver(_ observer: NSObject, forKeyPath keyPath: String)
}

extension WKEngineWebView {
    func evaluateJavaScript(
        _ javaScript: String,
        in frame: WKFrameInfo? = nil,
        in contentWorld: WKContentWorld,
        completionHandler: ((Result<Any, Error>) -> Void)? = nil
    ) {
        evaluateJavaScript(javaScript,
                           in: frame,
                           in: contentWorld,
                           completionHandler: completionHandler)
    }

    /// Evaluates Javascript in a .defaultClient sandboxed content world
    /// - Parameter javascript: String representing javascript to be evaluated
    func evaluateJavascriptInDefaultContentWorld(_ javascript: String) {
        evaluateJavaScript(javascript,
                           in: nil,
                           in: .defaultClient,
                           completionHandler: { _ in })
    }

    /// Evaluates Javascript in a .defaultClient sandboxed content world
    /// - Parameters:
    ///   - javascript: String representing javascript to be evaluated.
    ///   - frame: An object that contains information about a frame on a webpage.
    ///   - completion: Tuple containing optional data and an optional error.
    func evaluateJavascriptInDefaultContentWorld(
        _ javascript: String,
        _ frame: WKFrameInfo? = nil, _ completion: @escaping (Any?, Error?) -> Void
    ) {
        evaluateJavaScript(javascript, in: frame, in: .defaultClient) { result in
            switch result {
            case .success(let value):
                completion(value, nil)
            case .failure(let error):
                completion(nil, error)
            }
        }
    }

    func replaceLocation(with url: URL) {
        let charactersToReplace = CharacterSet(charactersIn: "'")
        guard let safeUrl = url.absoluteString
            .addingPercentEncoding(withAllowedCharacters: charactersToReplace.inverted) else { return }

        evaluateJavascriptInDefaultContentWorld("location.replace('\(safeUrl)')")
    }
}

// TODO: FXIOS-7896 #17641 Handle WKEngineWebView ThemeApplicable
// TODO: FXIOS-7897 #17642 Handle WKEngineWebView AccessoryViewProvider
class DefaultWKEngineWebView: WKWebView, WKEngineWebView, MenuHelperWebViewInterface {
    var engineScrollView: WKScrollView!
    var engineConfiguration: WKEngineConfiguration
    weak var delegate: WKEngineWebViewDelegate?

    override var inputAccessoryView: UIView? {
        if let delegatePreference = delegate?.tabWebViewInputAccessoryView(self) {
            switch delegatePreference {
            case .default: break
            case .none: return nil
            }
        }
        return super.inputAccessoryView
    }

    required init?(frame: CGRect, configurationProvider: WKEngineConfigurationProvider) {
        let configuration = configurationProvider.createConfiguration()
        self.engineConfiguration = configuration
        guard let configuration = configuration as? DefaultEngineConfiguration else { return nil }

        super.init(frame: frame, configuration: configuration.webViewConfiguration)

        self.engineScrollView = scrollView
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func removeAllUserScripts() {
        configuration.userContentController.removeAllUserScripts()
        configuration.userContentController.removeAllScriptMessageHandlers()
    }

    func menuHelperFindInPage() {
        evaluateJavascriptInDefaultContentWorld("getSelection().toString()") { result, _ in
            let selection = result as? String ?? ""
            self.delegate?.tabWebView(self, findInPageSelection: selection)
        }
    }

    func menuHelperSearchWith() {
        evaluateJavascriptInDefaultContentWorld("getSelection().toString()") { result, _ in
            let selection = result as? String ?? ""
            self.delegate?.tabWebView(self, searchSelection: selection)
        }
    }

    override internal func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        // The find-in-page selection menu only appears if the webview is the first responder.
        // Do not becomeFirstResponder on a mouse event.
        if let event = event, event.allTouches?.contains(where: { $0.type != .indirectPointer }) ?? false {
            becomeFirstResponder()
        }
        return super.hitTest(point, with: event)
    }
}
