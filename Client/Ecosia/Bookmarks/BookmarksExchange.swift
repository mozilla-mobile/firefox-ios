// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Core
import Shared
import Storage

protocol BookmarksExchangable {
    func export(bookmarks: [Core.BookmarkItem], in viewController: UIViewController, barButtonItem: UIBarButtonItem) async throws
    func `import`(from fileURL: URL, in viewController: UIViewController) async throws
}

final class BookmarksExchange: BookmarksExchangable {
    
    enum Error: Swift.Error {
        case couldNotReadData
    }
    
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
    func export(bookmarks: [Core.BookmarkItem], in viewController: UIViewController, barButtonItem: UIBarButtonItem) async throws {
        guard let view = viewController.view else { return }
        
        let activityIndicator = UIActivityIndicatorView(style: .medium)
        activityIndicator.color = UIColor.legacyTheme.ecosia.primaryBrand
        activityIndicator.startAnimating()
        
        let toast = SimpleToast()
        
        toast.showAlertWithText(
            .localized(.exportingBookmarks),
            image: .view(activityIndicator),
            bottomContainer: view,
            bottomInset: view.layoutMargins.bottom
        )
        
        let serializer = BookmarkSerializer()
        
        let htmlExport = try await serializer.serializeBookmarks(bookmarks)
        
        let exportedBooksmarksUrl = FileManager.default.temporaryDirectory.appendingPathComponent("Bookmarks.html")
        try htmlExport.data(using: .utf8)?.write(to: exportedBooksmarksUrl)

        let activityViewController = UIActivityViewController(activityItems: [exportedBooksmarksUrl], applicationActivities: nil)
        activityViewController.popoverPresentationController?.barButtonItem = barButtonItem
        activityViewController.completionWithItemsHandler = { _, completed, _, error in
            guard completed, error == nil else { return }
            SimpleToast().showAlertWithText(
                .localized(.bookmarksExported),
                image: .named("bookmarkSuccess"),
                bottomContainer: view,
                bottomInset: view.layoutMargins.bottom
            )
        }
        viewController.present(activityViewController, animated: true) {}
    }
    
    @MainActor
    func `import`(from fileURL: URL, in viewController: UIViewController) async throws {
        guard let view = viewController.view else { return }
        
        let activityIndicator = UIActivityIndicatorView(style: .medium)
        activityIndicator.color = .init(named: "splashLogoTint")
        activityIndicator.startAnimating()
        
        let toast = SimpleToast()

        toast.showAlertWithText(
            .localized(.importingBookmarks),
            image: .view(activityIndicator),
            bottomContainer: view,
            bottomInset: view.layoutMargins.bottom
        )

        do {
            let (data, _) = try await URLSession.shared.data(from: fileURL)
            guard let html = String(data: data, encoding: .utf8) else { throw Error.couldNotReadData }
            let parser = try BookmarkParser(html: html)
            let bookmarks = try await parser.parseBookmarks()
            try await importBookmarks(bookmarks, viewController: viewController, toast: toast)
            Analytics.shared.bookmarksImportEnded(.success)
        } catch {
            Analytics.shared.bookmarksImportEnded(.error)
            throw error
        }
    }
    
    private func importBookmarks(
        _ bookmarks: [Core.BookmarkItem],
        viewController: UIViewController,
        toast: SimpleToast
    ) async throws {
        /// create folder with date by import
        let importGuid: GUID
        
        if await hasBookmarks() {
            importGuid = try await createFolder(
                parentGUID: .mobileBookmarksGUID,
               title: .init(format: .localized(.importedBookmarkFolderName), dateFormatter.string(from: Date()))
           )
        } else {
            importGuid = .mobileBookmarksGUID
        }
                
        try await processBookmarks(bookmarks, parentGUID: importGuid)
        
        await showImportSuccess(using: toast, in: viewController.view)
    }
    
    @MainActor
    private func showImportSuccess(using toast: SimpleToast, in view: UIView) async {
        
        SimpleToast().showAlertWithText(
            .localized(.bookmarksImported),
            image: .named("bookmarkSuccess"),
            bottomContainer: view,
            bottomInset: view.layoutMargins.bottom
        )
    }
    
    private func hasBookmarks() async -> Bool {
        await withCheckedContinuation { continuation in
            profile.places.getBookmark(guid: .mobileBookmarksGUID).uponQueue(DispatchQueue.main) { result in
                guard let bookmarkNode = result.successValue,
                      let bookmarkFolder = bookmarkNode as? BookmarkFolderData
                else {
                    continuation.resume(with: .success(false))
                    return
                }
                continuation.resume(with: .success(bookmarkFolder.isNonEmptyFolder))
            }
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

extension GUID {
    static let mobileBookmarksGUID = "mobile______"
}
