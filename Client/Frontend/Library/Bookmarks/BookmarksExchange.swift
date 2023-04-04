// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Core

protocol BookmarksExchangable {
    func export(bookmarks: [BookmarkItem], in viewController: UIViewController) async throws
    func `import`(from url: URL, in viewController: UIViewController) async throws
}

class BookmarksExchange: BookmarksExchangable {
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
        
        toast.onShown = { [weak viewController] in
            Task { [weak viewController] in
                
                let html = try String(contentsOf: url)
                let parser = try BookmarkParser(html: html)
                
                let bookmarks = try await parser.parseBookmarks()
                
                // todo: import into database
                
                debugPrint("Importing bookmarks:", bookmarks)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    toast.dismiss()
                }
            }
        }
        
        toast.showAlertWithText(
            "Importing Bookmarks…",
            image: .view(activityIndicator),
            bottomContainer: view,
            dismissAfter: nil,
            bottomInset: view.layoutMargins.bottom
        )
    }
}
