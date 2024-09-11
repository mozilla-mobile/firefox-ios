// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import WebKit
import Shared
import Common

protocol DownloadDelegate: AnyObject {
    func download(_ download: Download, didCompleteWithError error: Error?)
    func download(_ download: Download, didDownloadBytes bytesDownloaded: Int64)
    func download(_ download: Download, didFinishDownloadingTo location: URL)
}

class Download: NSObject {
    weak var delegate: DownloadDelegate?

    fileprivate(set) var filename: String
    fileprivate(set) var mimeType: String
    let originWindow: WindowUUID

    fileprivate(set) var isComplete = false

    fileprivate(set) var totalBytesExpected: Int64?
    fileprivate(set) var bytesDownloaded: Int64
    // Whether the server has indicated it will send encoded data (via response `Content-Encoding` header) (FXIOS-9039)
    fileprivate(set) var hasContentEncoding: Bool?

    init(originWindow: WindowUUID) {
        self.filename = "unknown"
        self.mimeType = "application/octet-stream"

        self.originWindow = originWindow
        self.bytesDownloaded = 0

        super.init()
    }

    func cancel() {}
    func pause() {}
    func resume() {}

    fileprivate func uniqueDownloadPathForFilename(_ filename: String) throws -> URL {
        let downloadsPath = try FileManager.default.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: false
        ).appendingPathComponent("Downloads")

        let basePath = downloadsPath.appendingPathComponent(filename)
        let fileExtension = basePath.pathExtension
        let filenameWithoutExtension = !fileExtension.isEmpty ? String(filename.dropLast(fileExtension.count + 1)) : filename

        var proposedPath = basePath
        var count = 0

        while FileManager.default.fileExists(atPath: proposedPath.path) {
            count += 1

            let proposedFilenameWithoutExtension = "\(filenameWithoutExtension) (\(count))"
            proposedPath = downloadsPath
                .appendingPathComponent(proposedFilenameWithoutExtension)
                .appendingPathExtension(fileExtension)
        }

        return proposedPath
    }
}

class HTTPDownload: Download {
    let preflightResponse: URLResponse
    let request: URLRequest

    var state: URLSessionTask.State {
        return task?.state ?? .suspended
    }

    fileprivate(set) var session: URLSession?
    fileprivate(set) var task: URLSessionDownloadTask?
    fileprivate(set) var cookieStore: WKHTTPCookieStore

    private var resumeData: Data?

    // Used to avoid name spoofing using Unicode RTL char to change file extension
    public static func stripUnicode(fromFilename string: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet.punctuationCharacters)
        return string.components(separatedBy: allowed.inverted).joined()
     }

    init?(originWindow: WindowUUID,
          cookieStore: WKHTTPCookieStore,
          preflightResponse: URLResponse,
          request: URLRequest) {
        self.cookieStore = cookieStore
        self.preflightResponse = preflightResponse

        // Remove blobl from url to pass the rest of the checks
        var tempRequest = request
         if let url = request.url, url.scheme == "blob" {
             let requestUrl = url.removeBlobFromUrl()
             tempRequest = URLRequest(url: requestUrl)
         }
         self.request = tempRequest

        // Verify scheme is a secure http or https scheme before moving forward with HTTPDownload initialization
        guard let scheme = self.request.url?.scheme else { return nil }
        guard scheme == "http" || scheme == "https" else { return nil }

        super.init(originWindow: originWindow)

        if let filename = preflightResponse.suggestedFilename {
            self.filename = HTTPDownload.stripUnicode(fromFilename: filename)
        }

        if let mimeType = preflightResponse.mimeType {
            self.mimeType = mimeType
        }

        self.totalBytesExpected = preflightResponse.expectedContentLength > 0 ? preflightResponse.expectedContentLength : nil
        if let contentEncodingHeader = (preflightResponse as? HTTPURLResponse)?
                                       .allHeaderFields["Content-Encoding"] as? String,
           !contentEncodingHeader.isEmpty {
            // If this header is present, some encoding has been applied to the payload (likely gzip compression), so the
            // above `preflightResponse.expectedContentLength` reflects the size of the encoded content, not the actual file
            // https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Encoding
            // FXIOS-9039
            self.hasContentEncoding = true
        } else {
            self.hasContentEncoding = false
        }

        self.session = URLSession(configuration: .ephemeral, delegate: self, delegateQueue: .main)
        self.task = session?.downloadTask(with: self.request)
    }

    override func cancel() {
        task?.cancel()
    }

    override func pause() {
        task?.cancel(byProducingResumeData: { resumeData in
            self.resumeData = resumeData
        })
    }

    override func resume() {
        cookieStore.getAllCookies { [self] cookies in
            cookies.forEach { cookie in
                session?.configuration.httpCookieStorage?.setCookie(cookie)
            }

            guard let resumeData = self.resumeData else {
                self.task?.resume()
                return
            }

            self.task = session?.downloadTask(withResumeData: resumeData)
            self.task?.resume()
        }
    }
}

extension HTTPDownload: URLSessionTaskDelegate, URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        // Don't bubble up cancellation as an error if the
        // error is `.cancelled` and we have resume data.
        if let urlError = error as? URLError,
            urlError.code == .cancelled,
            resumeData != nil {
            return
        }
        delegate?.download(self, didCompleteWithError: error)
    }

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        bytesDownloaded = totalBytesWritten
        totalBytesExpected = totalBytesExpectedToWrite

        delegate?.download(self, didDownloadBytes: bytesWritten)
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        do {
            let destination = try uniqueDownloadPathForFilename(filename)
            try FileManager.default.moveItem(at: location, to: destination)
            isComplete = true
            delegate?.download(self, didFinishDownloadingTo: destination)
        } catch let error {
            delegate?.download(self, didCompleteWithError: error)
        }
    }
}

class BlobDownload: Download {
    private let data: Data

    init(originWindow: WindowUUID, filename: String, mimeType: String, size: Int64, data: Data) {
        self.data = data

        super.init(originWindow: originWindow)

        self.filename = filename
        self.mimeType = mimeType

        self.totalBytesExpected = size
    }

    override func resume() {
        // Wait momentarily before continuing here and firing off the delegate
        // callbacks. Otherwise, these may end up getting called before the
        // delegate is set up and the UI may never be notified of completion.
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
            do {
                let destination = try self.uniqueDownloadPathForFilename(self.filename)
                try self.data.write(to: destination)
                self.isComplete = true
                self.delegate?.download(self, didFinishDownloadingTo: destination)
            } catch let error {
                self.delegate?.download(self, didCompleteWithError: error)
            }
        }
    }
}

protocol DownloadQueueDelegate: AnyObject {
    var windowUUID: WindowUUID { get }
    func downloadQueue(_ downloadQueue: DownloadQueue, didStartDownload download: Download)
    func downloadQueue(
        _ downloadQueue: DownloadQueue,
        didDownloadCombinedBytes combinedBytesDownloaded: Int64,
        combinedTotalBytesExpected: Int64?
    )
    func downloadQueue(_ downloadQueue: DownloadQueue, download: Download, didFinishDownloadingTo location: URL)
    func downloadQueue(_ downloadQueue: DownloadQueue, didCompleteWithError error: Error?)
}

class WeakDownloadQueueDelegate {
    private(set) weak var delegate: DownloadQueueDelegate?
    init(delegate: DownloadQueueDelegate? = nil) { self.delegate = delegate }
}

struct DownloadProgress {
    var bytesDownloaded: Int64
    var totalExpected: Int64
}

class DownloadQueue {
    var downloads: [Download]

    private var delegates = [WeakDownloadQueueDelegate]()

    var isEmpty: Bool {
        return downloads.isEmpty
    }

    fileprivate var downloadProgress: [WindowUUID: DownloadProgress] = [:]
    fileprivate var downloadErrors: [WindowUUID: Error] = [:]

    init() {
        self.downloads = []
    }

    func addDelegate(_ delegate: DownloadQueueDelegate) {
        self.cleanUpDelegates()
        delegates.append(WeakDownloadQueueDelegate(delegate: delegate))
    }

    func removeDelegate(_ delegate: DownloadQueueDelegate) {
        delegates.removeAll(where: { $0.delegate === delegate || $0.delegate == nil })
    }

    func enqueue(_ download: Download) {
        // Clear the download stats if the queue was empty at the start.
        let uuid = download.originWindow
        if downloads(for: uuid).isEmpty {
            downloadProgress[uuid] = nil
            downloadErrors[uuid] = nil
        }

        downloads.append(download)
        download.delegate = self

        if let totalBytesExpected = download.totalBytesExpected {
            var progress = downloadProgress[uuid] ?? DownloadProgress(bytesDownloaded: 0, totalExpected: 0)
            progress.totalExpected += totalBytesExpected
            downloadProgress[uuid] = progress
        } else {
            downloadProgress[uuid] = nil
        }

        download.resume()
        delegates.forEach { $0.delegate?.downloadQueue(self, didStartDownload: download) }
    }

    func cancelAll(for window: WindowUUID) {
        for download in downloads where !download.isComplete && download.originWindow == window {
            download.cancel()
        }
    }

    func pauseAll(for window: WindowUUID) {
        for download in downloads where !download.isComplete && download.originWindow == window {
            download.pause()
        }
    }

    func resumeAll(for window: WindowUUID) {
        for download in downloads where !download.isComplete && download.originWindow == window {
            download.resume()
        }
    }

    // MARK: - Utility

    private func cleanUpDelegates() {
        delegates.removeAll(where: { $0.delegate == nil })
    }

    private func downloads(for window: WindowUUID) -> [Download] {
        return downloads.filter({ $0.originWindow == window })
    }
}

extension DownloadQueue: DownloadDelegate {
    func download(_ download: Download, didCompleteWithError error: Error?) {
        guard let error = error, let index = downloads.firstIndex(of: download) else { return }

        let uuid = download.originWindow
        downloadErrors[uuid] = error
        downloads.remove(at: index)

        // If all downloads for the completed download's window are completed, we notify of error
        if downloads(for: uuid).isEmpty {
            delegates.forEach {
                guard $0.delegate?.windowUUID == uuid else { return }
                $0.delegate?.downloadQueue(self, didCompleteWithError: error)
            }
        }
    }

    func download(_ download: Download, didDownloadBytes bytesDownloaded: Int64) {
        let uuid = download.originWindow
        var progress = downloadProgress[uuid] ?? DownloadProgress(bytesDownloaded: 0, totalExpected: 0)
        progress.bytesDownloaded += bytesDownloaded
        downloadProgress[uuid] = progress

        delegates.forEach {
            guard $0.delegate?.windowUUID == uuid else { return }
            $0.delegate?.downloadQueue(self,
                                       didDownloadCombinedBytes: progress.bytesDownloaded,
                                       combinedTotalBytesExpected: progress.totalExpected)
        }
    }

    func download(_ download: Download, didFinishDownloadingTo location: URL) {
        guard let index = downloads.firstIndex(of: download) else { return }

        downloads.remove(at: index)
        delegates.forEach { $0.delegate?.downloadQueue(self, download: download, didFinishDownloadingTo: location) }

        NotificationCenter.default.post(name: .FileDidDownload, object: location)

        // If all downloads for the completed download's window are completed, we notify of completion
        let uuid = download.originWindow
        if downloads(for: uuid).isEmpty {
            let error = downloadErrors[uuid]
            delegates.forEach {
                guard $0.delegate?.windowUUID == uuid else { return }
                $0.delegate?.downloadQueue(self, didCompleteWithError: error)
            }
            downloadErrors[uuid] = nil
        }
    }
}
