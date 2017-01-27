/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import XCGLogger

private let log = Logger.syncLogger

public protocol PerhapsNoOp {
    var isNoOp: Bool { get }
}

open class LocalOverrideCompletionOp: PerhapsNoOp {
    open var processedLocalChanges: Set<GUID> = Set()                // These can be deleted when we're run. Mark mirror as non-overridden, too.

    open var mirrorItemsToDelete: Set<GUID> = Set()                  // These were locally or remotely deleted.
    open var mirrorItemsToInsert: [GUID: BookmarkMirrorItem] = [:]   // These were locally or remotely added.
    open var mirrorItemsToUpdate: [GUID: BookmarkMirrorItem] = [:]   // These were already in the mirror, but changed.
    open var mirrorStructures: [GUID: [GUID]] = [:]                  // New or changed structure.

    open var mirrorValuesToCopyFromBuffer: Set<GUID> = Set()         // No need to synthesize BookmarkMirrorItem instances in memory.
    open var mirrorValuesToCopyFromLocal: Set<GUID> = Set()
    open var modifiedTimes: [Timestamp: [GUID]] = [:]                // Only for copy.

    open var isNoOp: Bool {
        return processedLocalChanges.isEmpty &&
               mirrorValuesToCopyFromBuffer.isEmpty &&
               mirrorValuesToCopyFromLocal.isEmpty &&
               mirrorItemsToDelete.isEmpty &&
               mirrorItemsToInsert.isEmpty &&
               mirrorItemsToUpdate.isEmpty &&
               mirrorStructures.isEmpty
    }

    open func setModifiedTime(_ time: Timestamp, guids: [GUID]) {
        var forCopy: [GUID] = self.modifiedTimes[time] ?? []
        for guid in guids {
            // This saves us doing an UPDATE on these items.
            if var item = self.mirrorItemsToInsert[guid] {
                item.serverModified = time
            } else if var item = self.mirrorItemsToUpdate[guid] {
                item.serverModified = time
            } else {
                forCopy.append(guid)
            }
        }

        if !forCopy.isEmpty {
            modifiedTimes[time] = forCopy
        }
    }

    public init() {
    }
}

open class BufferCompletionOp: PerhapsNoOp {
    open var processedBufferChanges: Set<GUID> = Set()    // These can be deleted when we're run.

    open var isNoOp: Bool {
        return self.processedBufferChanges.isEmpty
    }

    public init() {
    }
}
