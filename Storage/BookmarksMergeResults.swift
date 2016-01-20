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

public class LocalOverrideCompletionOp: PerhapsNoOp {
    public var processedLocalChanges: Set<GUID> = Set()                // These can be deleted when we're run. Mark mirror as non-overridden, too.

    public var mirrorItemsToDelete: Set<GUID> = Set()                  // These were locally or remotely deleted.
    public var mirrorItemsToInsert: [GUID: BookmarkMirrorItem] = [:]   // These were locally or remotely added.
    public var mirrorItemsToUpdate: [GUID: BookmarkMirrorItem] = [:]   // These were already in the mirror, but changed.
    public var mirrorStructures: [GUID: [GUID]] = [:]                  // New or changed structure.

    public var mirrorValuesToCopyFromBuffer: Set<GUID> = Set()         // No need to synthesize BookmarkMirrorItem instances in memory.
    public var mirrorValuesToCopyFromLocal: Set<GUID> = Set()

    // TODO: PRAGMA defer_foreign_keys = ON; ? Or just delete structure before, add structure after?

    public var isNoOp: Bool {
        return processedLocalChanges.isEmpty &&
               mirrorValuesToCopyFromBuffer.isEmpty &&
               mirrorValuesToCopyFromLocal.isEmpty &&
               mirrorItemsToDelete.isEmpty &&
               mirrorItemsToInsert.isEmpty &&
               mirrorItemsToUpdate.isEmpty &&
               mirrorStructures.isEmpty
    }

    public init() {
    }
}

public class BufferCompletionOp: PerhapsNoOp {
    public var processedBufferChanges: Set<GUID> = Set()    // These can be deleted when we're run.

    public var isNoOp: Bool {
        return true
    }

    public init() {
    }
}