// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

private let temporaryDocumentOperationQueue = OperationQueue()

protocol TemporaryDocument {
    func getURL(completionHandler: @escaping ((URL?) -> Void))
    func getDownloadedURL() async -> URL?
}

class DefaultTemporaryDocument: NSObject, TemporaryDocument {
    fileprivate let request: URLRequest
    fileprivate let filename: String

    fileprivate var session: URLSession?

    fileprivate var downloadTask: URLSessionDownloadTask?
    fileprivate var localFileURL: URL?

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
