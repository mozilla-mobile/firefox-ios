/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

protocol ReadingListChangeAccumulator {
    func addDeletedClientRecord(deletedRecord: ReadingListClientRecord)
    func addDeletedServerRecord(deletedRecord: ReadingListServerRecord)
    func addChangedRecord(changedRecord: ReadingListClientRecord)
    func addUploadedRecord(uploadedRecord: ReadingListClientRecord, down: ReadingListServerRecord)
    func addDownloadedRecord(downloadedRecord: ReadingListServerRecord)
    func applyAccumulatedChanges()
}
