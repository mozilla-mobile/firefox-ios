// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Core
import Shared

protocol BookmarksExchangable {
    func export(bookmarks: [BookmarkItem], in viewController: UIViewController) async throws
    func `import`(from url: URL, in viewController: UIViewController) async throws
}

class BookmarksExchange: BookmarksExchangable {
    private let profile: Profile
    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    init(profile: Profile) {
        self.profile = profile
    }
    
    @MainActor
    func export(bookmarks: [BookmarkItem], in viewController: UIViewController) async throws {
        guard let view = viewController.view else { return }
        
        let activityIndicator = UIActivityIndicatorView(style: .medium)
        activityIndicator.color = UIColor.theme.ecosia.primaryBrand
        activityIndicator.startAnimating()
        
        let toast = SimpleToast()
        
        toast.onShown = { [weak viewController] in
            Task { [weak viewController] in
                let serializer = BookmarkSerializer()
                
                let htmlExport = try await serializer.serializeBookmarks(bookmarks)
                
                let exportedBooksmarksUrl = FileManager.default.temporaryDirectory.appendingPathComponent("Bookmarks.html")
                try htmlExport.data(using: .utf8)?.write(to: exportedBooksmarksUrl)

                let activityViewController = UIActivityViewController(activityItems: [exportedBooksmarksUrl], applicationActivities: nil)
                viewController?.present(activityViewController, animated: true) {
                    toast.dismiss()
                }
            }
        }
        
        toast.showAlertWithText(
            "Exporting Bookmarks…",
            image: .view(activityIndicator),
            bottomContainer: view,
            dismissAfter: nil,
            bottomInset: view.layoutMargins.bottom
        )
    }
    
    @MainActor
    func `import`(from url: URL, in viewController: UIViewController) async throws {
        guard let view = viewController.view else { return }
        
        let activityIndicator = UIActivityIndicatorView(style: .medium)
        activityIndicator.color = UIColor.theme.ecosia.primaryBrand
        activityIndicator.startAnimating()
        
        let toast = SimpleToast()

//        toast.onShown = { [weak viewController] in
//
//        }
                
        toast.showAlertWithText(
            "Importing Bookmarks…",
            image: .view(activityIndicator),
            bottomContainer: view,
            dismissAfter: nil,
            bottomInset: view.layoutMargins.bottom
        )

        let html = try String(contentsOf: url)
        let parser = try BookmarkParser(html: html)
        let bookmarks = try await parser.parseBookmarks()
        
        try await self.importBookmarks(bookmarks, viewController: viewController, toast: toast)
    }
    
    private func importBookmarks(
        _ bookmarks: [Core.BookmarkItem],
        viewController: UIViewController,
        toast: SimpleToast
    ) async throws {        
        /// create folder with date by import
        let importGuid = try await createFolder(parentGUID: "mobile______", title: "Imported at \(dateFormatter.string(from: Date()))")
        
        try await processBookmarks(bookmarks, parentGUID: importGuid)
        
        DispatchQueue.main.async {
            toast.dismiss()
        }
    }
    
    private func processBookmarks(_ bookmarks: [Core.BookmarkItem], parentGUID: GUID) async throws {
        for bookmark in bookmarks {
            switch bookmark {
            case let .folder(title, children, _):
                let subParentGuid = try await createFolder(parentGUID: parentGUID, title: title)
                try await processBookmarks(children, parentGUID: subParentGuid)
            case let .bookmark(title, url, _):
                try await createBookmark(parentGUID: parentGUID, url: url, title: title)
            }
        }
    }
}

private extension BookmarksExchange {
    @discardableResult
    func createFolder(parentGUID: GUID, title: String, position: UInt32? = nil) async throws -> GUID {
        try await withCheckedThrowingContinuation { continuation in
            profile.places.createFolder(parentGUID: parentGUID, title: title, position: position)
                .uponQueue(.main) { result in
                    switch result {
                    case let .success(guid):
                        continuation.resume(returning: guid)
                    case let .failure(error):
                        continuation.resume(throwing: error)
                    }
                }
        }
    }
    
    @discardableResult
    func createBookmark(parentGUID: GUID, url: String, title: String?, position: UInt32? = nil) async throws -> GUID {
        try await withCheckedThrowingContinuation { continuation in
            profile.places.createBookmark(parentGUID: parentGUID, url: url, title: title, position: position)
                .uponQueue(.main) { result in
                    switch result {
                    case let .success(guid):
                        continuation.resume(returning: guid)
                    case let .failure(error):
                        continuation.resume(throwing: error)
                    }
                }
        }
    }
}
