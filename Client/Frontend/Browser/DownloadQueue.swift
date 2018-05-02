/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

private let downloadOperationQueue = OperationQueue()

protocol DownloadDelegate {
    func download(_ download: Download, didCompleteWithError error: Error?)
    func download(_ download: Download, didDownloadBytes bytesDownloaded: Int64)
    func download(_ download: Download, didFinishDownloadingTo location: URL)
}

class Download: NSObject {
    let preflightResponse: URLResponse
    let request: URLRequest

    let mimeType: String
    let filename: String

    var delegate: DownloadDelegate?

    var state: URLSessionTask.State {
        return task?.state ?? .suspended
    }

    private(set) var totalBytesExpected: Int64?
    private(set) var bytesDownloaded: Int64

    private(set) var session: URLSession?
    private(set) var task: URLSessionDownloadTask?

    private(set) var isComplete = false

    init(preflightResponse: URLResponse, request: URLRequest) {
        self.preflightResponse = preflightResponse
        self.request = request

        self.mimeType = preflightResponse.mimeType ?? "application/octet-stream"
        self.filename = preflightResponse.suggestedFilename ?? "unknown"

        self.totalBytesExpected = preflightResponse.expectedContentLength > 0 ? preflightResponse.expectedContentLength : nil
        self.bytesDownloaded = 0

        super.init()

        self.session = URLSession(configuration: .default, delegate: self, delegateQueue: downloadOperationQueue)
        self.task = session?.downloadTask(with: request)
    }

    func cancel() {
        task?.cancel()
    }

    func resume() {
        task?.resume()
    }
}

extension Download: URLSessionTaskDelegate, URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        delegate?.download(self, didCompleteWithError: error)
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
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

    private func uniqueDownloadPathForFilename(_ filename: String) throws -> URL {
        let downloadsPath = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("Downloads")

        let basePath = downloadsPath.appendingPathComponent(filename)
        let fileExtension = basePath.pathExtension
        let filenameWithoutExtension = fileExtension.count > 0 ? String(filename.dropLast(fileExtension.count + 1)) : filename

        var proposedPath = basePath
        var count = 0

        while FileManager.default.fileExists(atPath: proposedPath.path) {
            count += 1

            let proposedFilenameWithoutExtension = "\(filenameWithoutExtension) (\(count))"
            proposedPath = downloadsPath.appendingPathComponent(proposedFilenameWithoutExtension).appendingPathExtension(fileExtension)
        }

        return proposedPath
    }
}

protocol DownloadQueueDelegate {
    func downloadQueue(_ downloadQueue: DownloadQueue, didStartDownload download: Download)
    func downloadQueue(_ downloadQueue: DownloadQueue, didDownloadCombinedBytes combinedBytesDownloaded: Int64, combinedTotalBytesExpected: Int64?)
    func downloadQueue(_ downloadQueue: DownloadQueue, download: Download, didFinishDownloadingTo location: URL)
    func downloadQueue(_ downloadQueue: DownloadQueue, didCompleteWithError error: Error?)
}

class DownloadQueue {
    var downloads: [Download]

    var delegate: DownloadQueueDelegate?

    var isEmpty: Bool {
        return downloads.isEmpty
    }

    fileprivate var combinedBytesDownloaded: Int64 = 0
    fileprivate var combinedTotalBytesExpected: Int64?
    fileprivate var lastDownloadError: Error?

    init() {
        self.downloads = []
    }

    func enqueueDownload(_ download: Download) {
        // Clear the download stats if the queue was empty at the start.
        if downloads.isEmpty {
            combinedBytesDownloaded = 0
            combinedTotalBytesExpected = 0
            lastDownloadError = nil
        }

        downloads.append(download)
        download.delegate = self

        if let totalBytesExpected = download.totalBytesExpected, combinedTotalBytesExpected != nil {
            combinedTotalBytesExpected! += totalBytesExpected
        } else {
            combinedTotalBytesExpected = nil
        }

        download.resume()
        delegate?.downloadQueue(self, didStartDownload: download)
    }

    func cancelAllDownloads() {
        for download in downloads where !download.isComplete {
            download.cancel()
        }
    }
}

extension DownloadQueue: DownloadDelegate {
    func download(_ download: Download, didCompleteWithError error: Error?) {
        guard let error = error, let index = downloads.index(of: download) else {
            return
        }

        lastDownloadError = error
        downloads.remove(at: index)

        if downloads.isEmpty {
            delegate?.downloadQueue(self, didCompleteWithError: lastDownloadError)
        }
    }

    func download(_ download: Download, didDownloadBytes bytesDownloaded: Int64) {
        combinedBytesDownloaded += bytesDownloaded
        delegate?.downloadQueue(self, didDownloadCombinedBytes: combinedBytesDownloaded, combinedTotalBytesExpected: combinedTotalBytesExpected)
    }

    func download(_ download: Download, didFinishDownloadingTo location: URL) {
        guard let index = downloads.index(of: download) else {
            return
        }

        downloads.remove(at: index)
        delegate?.downloadQueue(self, download: download, didFinishDownloadingTo: location)

        NotificationCenter.default.post(name: .FileDidDownload, object: location)

        if downloads.isEmpty {
            delegate?.downloadQueue(self, didCompleteWithError: lastDownloadError)
        }
    }
}
