// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import WebKit

private let temporaryDocumentOperationQueue = OperationQueue()

protocol TemporaryDocument {
    var filename: String { get set }
    func getURL(completionHandler: @escaping ((URL?) -> Void))
    func getDownloadedURL() async -> URL?
}

class DefaultTemporaryDocument: NSObject, TemporaryDocument {
    var filename: String

    private let request: URLRequest
    private var session: URLSession?
    private var downloadTask: URLSessionDownloadTask?
    private var localFileURL: URL?

    init(preflightResponse: URLResponse, request: URLRequest) {
        self.request = request
        self.filename = preflightResponse.suggestedFilename ?? "unknown"

        super.init()

        self.session = URLSession(
            configuration: .defaultMPTCP,
            delegate: nil,
            delegateQueue: temporaryDocumentOperationQueue
        )
    }

    deinit {
        // Delete the temp file.
        if let url = localFileURL {
            try? FileManager.default.removeItem(at: url)
        }
    }

    /// Uses modern concurrency to download the file and save to temporary storage.
    /// FXIOS-10830 - for iOS 18 we need to avoid calling the old URLSession APIs with continuations.
    /// - Returns: The URL of the file within the temporary directory. Returns nil if the file could not be downloaded.
    func getDownloadedURL() async -> URL? {
        if let url = localFileURL {
            return url
        }

        do {
            let (downloadURL, _) = try await URLSession.shared.download(for: request)

            let tempDirectory = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("TempDocs")
            let tempFileURL = tempDirectory.appendingPathComponent(filename)

            // Rename and move the downloaded file into the TempDocs directory
            try? FileManager.default.createDirectory(
                at: tempDirectory,
                withIntermediateDirectories: true,
                attributes: nil
            )
            try? FileManager.default.removeItem(at: tempFileURL)
            try FileManager.default.moveItem(at: downloadURL, to: tempFileURL)

            localFileURL = tempFileURL
            return tempFileURL
        } catch {
            return nil
        }
    }

    /// Downloads this file to temporary storage.
    ///
    /// CAUTION: Do not call this method from within a continuation. In iOS18, if we call this inside a continuation, is it
    /// possible we may have a crash similar to the one fixed in https://github.com/mozilla-mobile/firefox-ios/pull/23596
    /// (related ticket is FXIOS-10811, which tracked an incident elsewhere in the app).
    func getURL(completionHandler: @escaping ((URL?) -> Void)) {
        if let url = localFileURL {
            completionHandler(url)
            return
        }

        let request = self.request
        let filename = self.filename
        downloadTask = session?.downloadTask(with: request,
                                             completionHandler: { [weak self] location, _, error in
            guard let location = location,
                  error == nil else {
                // If we encounter an error downloading the temp file, just return with the
                // original remote URL so it can still be shared as a web URL.
                completionHandler(request.url)
                return
            }

            let tempDirectory = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("TempDocs")
            let url = tempDirectory.appendingPathComponent(filename)

            try? FileManager.default.createDirectory(
                at: tempDirectory,
                withIntermediateDirectories: true,
                attributes: nil
            )
            try? FileManager.default.removeItem(at: url)

            do {
                try FileManager.default.moveItem(at: location, to: url)
                self?.localFileURL = url
                completionHandler(url)
            } catch {
                // If we encounter an error downloading the temp file, just return with the
                // original remote URL so it can still be shared as a web URL.
                completionHandler(request.url)
            }
        })
        downloadTask?.resume()
    }
}

typealias VoidReturnParameterCallback<T> = (T) -> Void

import Common

class PDFLoadingView: UIView {
    private var document: PDFTemporaryDocument?
    private var observedTokens = [NSKeyValueObservation]()
    private let pdfIcon = UIImageView(image: UIImage(named: "pdf"))
    private let loadingView = UIActivityIndicatorView(style: .large)
    private let backgroundView = UIVisualEffectView(effect: UIBlurEffect(style: .systemThinMaterial))
    private let filenameLabel = UILabel()
    private var isAnimating = false
    private let theme: Theme

    init(frame: CGRect, theme: Theme) {
        self.theme = theme
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private struct UX {
        static let pdfIconSize: CGFloat = 100
    }

    // MARK: - Layout

    private func setup() {
        backgroundColor = .clear
        backgroundView.alpha = 0.0
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(backgroundView)
        NSLayoutConstraint.activate([
            backgroundView.leadingAnchor.constraint(equalTo: leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: trailingAnchor),
            backgroundView.topAnchor.constraint(equalTo: topAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        pdfIcon.contentMode = .scaleAspectFit
        pdfIcon.translatesAutoresizingMaskIntoConstraints = false

        addSubview(pdfIcon)
        NSLayoutConstraint.activate([
            pdfIcon.centerXAnchor.constraint(equalTo: centerXAnchor),
            pdfIcon.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -30.0),
            pdfIcon.widthAnchor.constraint(equalToConstant: UX.pdfIconSize),
            pdfIcon.heightAnchor.constraint(equalToConstant: UX.pdfIconSize)
        ])

        filenameLabel.alpha = 0.0
        filenameLabel.translatesAutoresizingMaskIntoConstraints = false
        filenameLabel.text = "Loading... \(document?.filename ?? "")"
        filenameLabel.textColor = theme.colors.textPrimary

        addSubview(filenameLabel)
        NSLayoutConstraint.activate([
            filenameLabel.topAnchor.constraint(equalTo: pdfIcon.bottomAnchor, constant: 12.0),
            filenameLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
        ])

        loadingView.alpha = 0.0
        loadingView.color = theme.colors.iconPrimary
        loadingView.startAnimating()
        loadingView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(loadingView)
        NSLayoutConstraint.activate([
            loadingView.centerXAnchor.constraint(equalTo: centerXAnchor),
            loadingView.topAnchor.constraint(equalTo: filenameLabel.bottomAnchor, constant: 12.0)
        ])
    }

    func addToSuperview(_ view: UIView) {
        translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(self)
        NSLayoutConstraint.activate([
            leadingAnchor.constraint(equalTo: view.leadingAnchor),
            trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topAnchor.constraint(equalTo: view.topAnchor),
            bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        if let touchPoint = (view as? TabWebView)?.lastTouchedPoint {
            let pdfIconPosition = CGPoint(x: touchPoint.x - frame.width / 2,
                                          y: touchPoint.y - frame.height / 2 - (UX.pdfIconSize * 0.2 / 2.0))
            pdfIcon.transform = CGAffineTransform(translationX: pdfIconPosition.x, y: pdfIconPosition.y).scaledBy(x: 0.2, y: 0.2)
        }
        UIView.animate(withDuration: 0.6, delay: 0.0) {
            self.isAnimating = true
            self.pdfIcon.transform = .identity
        } completion: { _ in
            UIView.animate(withDuration: 0.3) {
                self.backgroundView.alpha = 1
                self.filenameLabel.alpha = 1
                self.loadingView.alpha = 1
            } completion: { _ in
                self.isAnimating = false
                if self.document?.localFileURL != nil {
                    self.removeLoadingView()
                }
            }
        }
    }

    private func removeLoadingView() {
        guard !self.isAnimating else { return }
        guard let url = document?.localFileURL else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            guard let data = try? Data(contentsOf: url) else { return }
            ensureMainThread {
                let webView = self.superview as? WKWebView
                webView?.load(data, mimeType: "application/pdf", characterEncodingName: "", baseURL: url)
            }
        }
    }

    // MARK: - Actions

    func setDocument(_ document: PDFTemporaryDocument) {
        self.document = document
        filenameLabel.text = document.filename
        setupObservers()
        self.document?.download()
    }

    private func setupObservers() {
        let documentLoadLocalURL = document?.observe(\.localFileURL) { [weak self] _, _ in
            self?.removeLoadingView()
            self?.document?.invalidateSession()
        }
        if let documentLoadLocalURL {
            observedTokens.append(documentLoadLocalURL)
        }
        guard let webView = superview as? WKWebView else { return }
        let goBackToken = webView.observe(\.canGoBack) { [weak self] _, _ in
            self?.removeLoadingView()
            self?.document?.invalidateSession()
        }
        let goForwardToken = webView.observe(\.canGoForward) { [weak self] _, _ in
            self?.removeLoadingView()
            self?.document?.invalidateSession()
        }
        observedTokens.append(contentsOf: [goBackToken, goForwardToken])
    }

    deinit {
        observedTokens.forEach {
            $0.invalidate()
        }
    }
}

class PDFTemporaryDocument: NSObject, TemporaryDocument, URLSessionDownloadDelegate {
    private lazy var session: URLSession = {
        return URLSession(
            configuration: .defaultMPTCP,
            delegate: self,
            delegateQueue: temporaryDocumentOperationQueue
        )
    }()
    private var currentDownloadTask: URLSessionDownloadTask?

    let request: URLRequest
    var filename: String
    @objc dynamic var localFileURL: URL?
    var onDownloadToURL: VoidReturnParameterCallback<URL>?
    var onDownloadProgressUpdate: VoidReturnParameterCallback<Double>?

    init(
        filename: String?,
        request: URLRequest,
        cookies: [HTTPCookie],
        session: URLSession? = nil
    ) {
        self.request = Self.applyCookiesToRequest(request, cookies: cookies)
        self.filename = filename ?? "unknown"
        super.init()

        if let session {
            self.session = session
        }
    }

    /// Returns:
    /// Modified request with Cookies header field
    private static func applyCookiesToRequest(_ request: URLRequest, cookies: [HTTPCookie]) -> URLRequest {
        var rawHeaderCookies = cookies.reduce("") { partialResult, cookie in
            if let domain = request.url?.baseDomain, cookie.domain.contains(domain) {
                return partialResult.appending("\(cookie.name)=\(cookie.value); ")
            }
            return partialResult
        }
        if rawHeaderCookies.count >= 2 {
            // Removes the last ; and space char since not needed for the request
            rawHeaderCookies.removeLast(2)
        }
        var headers = request.allHTTPHeaderFields ?? [:]
        headers["Cookie"] = rawHeaderCookies
        var request = request
        request.allHTTPHeaderFields = headers

        return request
    }

    func getURL(completionHandler: @escaping ((URL?) -> Void)) {
        if let tempFile = queryTempFile() {
            completionHandler(tempFile)
            return
        }
        let task = session.downloadTask(with: request) { [weak self] location, response, error in
            guard let location else { return }
            if let tempFileURL = self?.storeTempDownloadFile(at: location) {
                self?.localFileURL = tempFileURL
                completionHandler(tempFileURL)
            } else {
                completionHandler(nil)
            }
        }
        task.resume()
    }

    func getDownloadedURL() async -> URL? {
        if let tempFile = queryTempFile() {
            return tempFile
        }
        let response = try? await session.download(for: request)
        guard let location = response?.0, let tempFileURL = storeTempDownloadFile(at: location) else { return nil }

        return tempFileURL
    }

    func download() {
        if let tempFile = queryTempFile() {
            ensureMainThread { [weak self] in
                self?.onDownloadToURL?(tempFile)
            }
            return
        }
        currentDownloadTask = session.downloadTask(with: request)
        currentDownloadTask?.resume()
    }

    private func queryTempFile() -> URL? {
        if let localFileURL {
            return localFileURL
        }
        let tempFileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(filename)
        if FileManager.default.fileExists(atPath: tempFileURL.path) {
            localFileURL = tempFileURL
            return tempFileURL
        }
        return nil
    }

    private func storeTempDownloadFile(at url: URL) -> URL? {
        // By default the downloaded file is stored in the temp directory
        let tempDirectory = url.deletingPathExtension().deletingLastPathComponent()
        let tempFileURL = tempDirectory.appendingPathComponent(filename)

        try? FileManager.default.createDirectory(
            at: tempDirectory,
            withIntermediateDirectories: true,
            attributes: nil
        )
        try? FileManager.default.removeItem(at: tempFileURL)

        do {
            try FileManager.default.moveItem(at: url, to: tempFileURL)
            localFileURL = tempFileURL
            return tempFileURL
        } catch {
            return nil
        }
    }

    func invalidateSession() {
        currentDownloadTask?.cancel()
        session.invalidateAndCancel()
    }

    deinit {
        if let tempFileURL = queryTempFile() {
            try? FileManager.default.removeItem(at: tempFileURL)
        }
    }

    // MARK: - URLSessionDownloadDelegate

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let url = storeTempDownloadFile(at: location) else { return }
        ensureMainThread { [weak self] in
            self?.onDownloadToURL?(url)
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: (any Error)?) {

    }

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        ensureMainThread { [weak self] in
            self?.onDownloadProgressUpdate?(progress)
        }
    }
}
