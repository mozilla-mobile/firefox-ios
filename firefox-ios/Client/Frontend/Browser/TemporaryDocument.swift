// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import WebKit

private let temporaryDocumentOperationQueue = OperationQueue()

protocol TemporaryDocument {
    var filename: String { get set }
    var isDownloading: Bool { get }

    func canDownload(request: URLRequest) -> Bool

    func download() async -> URL?

    func download(_ completion: @escaping (URL?) -> Void)

    /// Invalidates the current download session if any and release all the resources.
    func invalidateSession()
}

class DefaultTemporaryDocument: NSObject,
                                TemporaryDocument,
                                FeatureFlaggable,
                                URLSessionDownloadDelegate {
    private lazy var session: URLSession = {
        return URLSession(
            configuration: .defaultMPTCP,
            delegate: self,
            delegateQueue: temporaryDocumentOperationQueue
        )
    }()
    private let request: URLRequest
    private var currentDownloadTask: URLSessionDownloadTask?

    private var onDownload: ((URL?) -> Void)?
    var onDownloadProgressUpdate: ((Double) -> Void)?
    var isDownloading: Bool {
        return currentDownloadTask != nil
    }
    private var localFileURL: URL?

    private let mimeType: String?
    var filename: String

    private var isPDFRefactorEnabled: Bool {
        return featureFlags.isFeatureEnabled(.pdfRefactor, checking: .buildOnly)
    }

    init(
        filename: String?,
        request: URLRequest,
        mimeType: String? = nil,
        cookies: [HTTPCookie] = [],
        session: URLSession? = nil
    ) {
        self.request = Self.applyCookiesToRequest(request, cookies: cookies)
        self.filename = filename ?? "unknown"
        self.mimeType = mimeType
        super.init()

        if let session {
            self.session = session
        }
    }

    init(
        preflightResponse: URLResponse,
        request: URLRequest,
        mimeType: String? = nil,
        session: URLSession? = nil
    ) {
        self.request = request
        self.filename = preflightResponse.suggestedFilename ?? "unknown"
        self.mimeType = mimeType

        super.init()

        if let session {
            self.session = session
        }
    }

    /// Returns a modified request with Cookies header field
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

    func canDownload(request: URLRequest) -> Bool {
        return request.url != localFileURL
    }

    func download() async -> URL? {
        if let tempFile = queryTempFile() {
            return tempFile
        }
        let response = try? await session.download(for: request)
        guard let location = response?.0, let tempFileURL = storeTempDownloadFile(at: location) else { return nil }

        return tempFileURL
    }

    func download(_ completion: @escaping (URL?) -> Void) {
        if let tempFile = queryTempFile() {
            ensureMainThread {
                completion(tempFile)
            }
            return
        }
        onDownload = completion
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

    func invalidateSession() {
        currentDownloadTask?.cancel()
        currentDownloadTask = nil
        session.invalidateAndCancel()
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

    private func shouldRetainTempFile() -> Bool {
        // Retain the PDF so when the tab gets restored it still has the PDFs from the previous session
        if isPDFRefactorEnabled {
            return mimeType == MIMEType.PDF
        }
        return false
    }

    deinit {
        guard !shouldRetainTempFile(), let localFileURL else { return }
        try? FileManager.default.removeItem(at: localFileURL)
    }

    // MARK: - URLSessionDownloadDelegate

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let url = storeTempDownloadFile(at: location) else {
            onDownload?(nil)
            return
        }
        invalidateSession()
        ensureMainThread { [weak self] in
            self?.onDownload?(url)
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: (any Error)?) {
        currentDownloadTask = nil
        ensureMainThread { [weak self] in
            self?.onDownload?(nil)
        }
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
