// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation

/// Helper to get the metadata fetched out of a `WKEngineSession`
protocol MetadataFetcherHelper {
    var delegate: MetadataFetcherDelegate? { get set }
    func fetch(fromSession session: WKEngineSession, url: URL)
}

protocol MetadataFetcherDelegate: AnyObject {
    func didLoad(pageMetadata: EnginePageMetadata)
}

struct DefaultMetadataFetcherHelper: MetadataFetcherHelper {
    weak var delegate: MetadataFetcherDelegate?

    func fetch(fromSession session: WKEngineSession, url: URL) {
        // Get the metadata out of the page-metadata-parser, and into a type safe struct
        guard url.isWebPage(includeDataURIs: false),
              !WKInternalURL.isValid(url: url) else {
            session.sessionData.pageMetadata = nil
            return
        }

        session.webView.evaluateJavascriptInDefaultContentWorld(
            "__firefox__.metadata && __firefox__.metadata.getMetadata()"
        ) { result, error in
            guard error == nil else {
                session.sessionData.pageMetadata = nil
                return
            }

            guard let dict = result as? [String: Any],
                  let pageMetadata = EnginePageMetadata.fromDictionary(dict) else {
                session.sessionData.pageMetadata = nil
                return
            }

            session.sessionData.pageMetadata = pageMetadata
            self.delegate?.didLoad(pageMetadata: pageMetadata)
        }
    }
}
