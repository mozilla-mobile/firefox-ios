/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Deferred
import Foundation
import MobileCoreServices
import Shared
import UIKit

extension UIPasteboard {
    func addImageWithData(_ data: Data, forURL url: URL) {
        let isGIF = UIImage.dataIsGIF(data)

        // Setting pasteboard.items allows us to set multiple representations for the same item.
        items = [[
            kUTTypeURL as String: url,
            imageTypeKey(isGIF): data
        ]]
    }

    fileprivate func imageTypeKey(_ isGIF: Bool) -> String {
        return (isGIF ? kUTTypeGIF : kUTTypePNG) as String
    }

    private var syncURL: URL? {
        if let string = UIPasteboard.general.string,
            let url = URL(string: string), url.isWebPage() {
            return url
        } else {
            return nil
        }
    }

    /// Preferred method to get strings out of the clipboard.
    /// When iCloud pasteboards are enabled, the usually fast, synchronous calls
    /// become slow and synchronous causing very slow start up times.
    func asyncString() -> Deferred<Maybe<String?>> {
        return fetchAsync() {
            return UIPasteboard.general.string
        }
    }

    /// Preferred method to get URLs out of the clipboard.
    /// We use Deferred<Maybe<T?>> to fit in to the rest of the Deferred<Maybe> tools
    /// we already use; but use optionals instead of errorTypes, because not having a URL
    /// on the clipboard isn't an error.
    func asyncURL() -> Deferred<Maybe<URL?>> {
        return fetchAsync() {
            return self.syncURL
        }
    }

    // Converts the potentially long running synchronous operation into an asynchronous one.
    private func fetchAsync<T>(getter: @escaping () -> T) -> Deferred<Maybe<T>> {
        let deferred = Deferred<Maybe<T>>()
        DispatchQueue.global().async {
            let value = getter()
            deferred.fill(Maybe(success: value))
        }
        return deferred
    }
}
