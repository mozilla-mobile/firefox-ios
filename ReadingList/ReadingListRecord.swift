/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

// TODO This is not used anymore. Decide if we need to turn this into a protocol that the ClientRecord and ServerRecord implement. Not sure if we actually need that though.
class ReadingListRecord {
    let serverMetadata: ReadingListServerMetadata?

    init(serverMetadata: ReadingListServerMetadata?) {
        self.serverMetadata = serverMetadata
    }

    var guid: String? {
        get {
            return serverMetadata?.guid
        }
    }

    var serverLastModified: Int64? {
        get {
            return serverMetadata?.lastModified
        }
    }

    var url: String {
        get {
            fatalError("Subclass Responsibility")
        }
    }

    var title: String {
        get {
            fatalError("Subclass Responsibility")
        }
    }

    var addedBy: String {
        get {
            fatalError("Subclass Responsibility")
        }
    }
}
