/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import Storage
import XCGLogger

private let log = Logger.syncLogger

// Because generic protocols in Swift are a pain in the ass.
public protocol BookmarkStorer {
    // TODO: this should probably return a timestamp.
    func applyUpstreamCompletionOp(op: UpstreamCompletionOp) -> Deferred<Maybe<POSTResult>>
}

public class UpstreamCompletionOp: PerhapsNoOp {
    // Upload these records from the buffer, but with these child lists.
    public var amendChildrenFromBuffer: [GUID: [GUID]] = [:]

    // Upload these records as-is.
    public var records: [Record<BookmarkBasePayload>] = []

    public let ifUnmodifiedSince: Timestamp?

    public var isNoOp: Bool {
        return records.isEmpty
    }

    public init(ifUnmodifiedSince: Timestamp?=nil) {
        self.ifUnmodifiedSince = ifUnmodifiedSince
    }
}

public struct BookmarksMergeResult: PerhapsNoOp {
    let uploadCompletion: UpstreamCompletionOp
    let overrideCompletion: LocalOverrideCompletionOp
    let bufferCompletion: BufferCompletionOp

    public var isNoOp: Bool {
        return self.uploadCompletion.isNoOp &&
               self.overrideCompletion.isNoOp &&
               self.bufferCompletion.isNoOp
    }

    func applyToClient(client: BookmarkStorer, storage: SyncableBookmarks, buffer: BookmarkBufferStorage) -> Success {
        return client.applyUpstreamCompletionOp(self.uploadCompletion)
          >>== { storage.applyLocalOverrideCompletionOp(self.overrideCompletion, withModifiedTimestamp: $0.modified) }
           >>> { buffer.applyBufferCompletionOp(self.bufferCompletion) }
    }

    static let NoOp = BookmarksMergeResult(uploadCompletion: UpstreamCompletionOp(), overrideCompletion: LocalOverrideCompletionOp(), bufferCompletion: BufferCompletionOp())
}

func guidOnceOnlyStack() -> OnceOnlyStack<GUID, GUID> {
    return OnceOnlyStack<GUID, GUID>(key: { $0 })
}

func nodeOnceOnlyStack() -> OnceOnlyStack<BookmarkTreeNode, GUID> {
    return OnceOnlyStack<BookmarkTreeNode, GUID>(key: { $0.recordGUID })
}

// MARK: - Errors.

public class BookmarksMergeError: MaybeErrorType, ErrorType {
    public var description: String {
        return "Merge error"
    }
}

public class BookmarksMergeConsistencyError: BookmarksMergeError {
    override public var description: String {
        return "Merge consistency error"
    }
}

public class BookmarksMergeErrorTreeIsUnrooted: BookmarksMergeConsistencyError {
    public let roots: Set<GUID>

    public init(roots: Set<GUID>) {
        self.roots = roots
    }

    override public var description: String {
        return "Tree is unrooted: roots are \(self.roots)"
    }
}

protocol MirrorItemSource {
    func getBufferItemWithGUID(guid: GUID) -> Deferred<Maybe<BookmarkMirrorItem>>
    func getBufferItemsWithGUIDs(guids: [GUID]) -> Deferred<Maybe<[GUID: BookmarkMirrorItem]>>
}

enum MergeState<T> {
    case Unknown
    case Unchanged
    case Remote
    case Local
    case New(value: T)
}

/**
 * Using this:
 *
 * You get one for the root. Then you give it children for the roots
 * from the mirror.
 *
 * Then you walk those, populating the remote and local nodes by looking
 * at the left/right trees.
 *
 * By comparing left and right, and doing value-based comparisons if necessary,
 * a merge state is decided and assigned for both value and structure.
 *
 * One then walks both left and right child structures (both to ensure that
 * all nodes on both left and right will be visited!) recursively.
 */
class MergedTreeNode {
    let guid: GUID
    let mirror: BookmarkTreeNode?
    var remote: BookmarkTreeNode?
    var local: BookmarkTreeNode?

    var valueState: MergeState<BookmarkMirrorItem> = MergeState.Unknown
    var structureState: MergeState<BookmarkTreeNode> = MergeState.Unknown
    var mergedChildren: [MergedTreeNode] = []

    init(guid: GUID, mirror: BookmarkTreeNode?) {
        self.guid = guid
        self.mirror = mirror
    }

    var decidedStructure: BookmarkTreeNode? {
        switch self.structureState {
        case .Unknown:
            return nil
        case .Unchanged:
            return self.mirror
        case .Remote:
            return self.remote
        case .Local:
            return self.local
        case let .New(node):
            return node
        }
    }

    var children: [BookmarkTreeNode]? {
        return self.decidedStructure?.children
    }
}

class MergedTree {
    var root: MergedTreeNode
    var deleted: Set<GUID> = Set()

    init(mirrorRoot: BookmarkTreeNode) {
        self.root = MergedTreeNode(guid: mirrorRoot.recordGUID, mirror: mirrorRoot)
        self.root.valueState = MergeState.Unchanged
        self.root.structureState = MergeState.Unchanged
    }
}