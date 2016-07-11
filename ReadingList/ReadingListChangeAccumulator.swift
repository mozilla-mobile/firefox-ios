/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

protocol ReadingListChangeAccumulator {
    func addDeletedClientRecord(_ deletedRecord: ReadingListClientRecord)
    func addDeletedServerRecord(_ deletedRecord: ReadingListServerRecord)
    func addChangedRecord(_ changedRecord: ReadingListClientRecord)
    func addUploadedRecord(_ uploadedRecord: ReadingListClientRecord, down: ReadingListServerRecord)
    func addDownloadedRecord(_ downloadedRecord: ReadingListServerRecord)
    func applyAccumulatedChanges()
}
