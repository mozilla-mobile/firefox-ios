/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Deferred
import Shared

public protocol Metadata {
    func metadataForSites(sites: [Site]) -> Deferred<Maybe<[PageMetadata]>>
    func metadataForURLs(urls: [NSURL]) -> Deferred<Maybe<[PageMetadata]>>
    func storeMetadata(metadata: PageMetadata, forPageURL: NSURL) -> Success
}
