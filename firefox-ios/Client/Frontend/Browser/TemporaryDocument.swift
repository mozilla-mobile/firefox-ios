// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

private let temporaryDocumentOperationQueue = OperationQueue()

class TemporaryDocument: NSObject {
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
