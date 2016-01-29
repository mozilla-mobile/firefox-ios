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

    var isUnknown: Bool {
        if case .Unknown = self {
            return true
        }
        return false
    }
}

func ==<T: Equatable>(lhs: MergeState<T>, rhs: MergeState<T>) -> Bool {
    switch (lhs, rhs) {
    case (.Unknown, .Unknown):
        return true
    case (.Unchanged, .Unchanged):
        return true
    case (.Remote, .Remote):
        return true
    case (.Local, .Local):
        return true
    case let (.New(lh), .New(rh)):
        return lh == rh
    default:
        return false
    }
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

    var hasDecidedChildren: Bool {
        return !self.structureState.isUnknown
    }

    var mergedChildren: [MergedTreeNode]? = nil

    // One-sided constructors.
    static func forRemote(remote: BookmarkTreeNode, mirror: BookmarkTreeNode?=nil) -> MergedTreeNode {
        let n = MergedTreeNode(guid: remote.recordGUID, mirror: mirror, structureState: MergeState.Remote)
        n.remote = remote
        n.valueState = MergeState.Remote
        return n
    }

    static func forLocal(local: BookmarkTreeNode, mirror: BookmarkTreeNode?=nil) -> MergedTreeNode {
        let n = MergedTreeNode(guid: local.recordGUID, mirror: mirror, structureState: MergeState.Local)
        n.local = local
        n.valueState = MergeState.Local
        return n
    }

    static func forUnchanged(mirror: BookmarkTreeNode) -> MergedTreeNode {
        let n = MergedTreeNode(guid: mirror.recordGUID, mirror: mirror, structureState: MergeState.Unchanged)
        n.valueState = MergeState.Unchanged
        return n
    }

    init(guid: GUID, mirror: BookmarkTreeNode?, structureState: MergeState<BookmarkTreeNode>) {
        self.guid = guid
        self.mirror = mirror
        self.structureState = structureState
    }

    init(guid: GUID, mirror: BookmarkTreeNode?) {
        self.guid = guid
        self.mirror = mirror
    }

    // N.B., you cannot recurse down `decidedStructure`: you'll depart from the
    // merged tree. You need to use `mergedChildren` instead.
    private var decidedStructure: BookmarkTreeNode? {
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

    func asUnmergedTreeNode() -> BookmarkTreeNode {
        return self.decidedStructure ?? BookmarkTreeNode.Unknown(guid: self.guid)
    }

    // Recursive. Starts returning Unknown when nodes haven't been processed.
    func asMergedTreeNode() -> BookmarkTreeNode {
        guard let decided = self.decidedStructure,
              let merged = self.mergedChildren else {
            return BookmarkTreeNode.Unknown(guid: self.guid)
        }

        if case .Folder = decided {
            let children = merged.map { $0.asMergedTreeNode() }
            return BookmarkTreeNode.Folder(guid: self.guid, children: children)
        }

        return decided
    }
}

class MergedTree {
    var root: MergedTreeNode
    var deleteLocally: Set<GUID> = Set()
    var deleteRemotely: Set<GUID> = Set()
    var deleteFromMirror: Set<GUID> = Set()

    init(mirrorRoot: BookmarkTreeNode) {
        self.root = MergedTreeNode(guid: mirrorRoot.recordGUID, mirror: mirrorRoot, structureState: MergeState.Unchanged)
        self.root.valueState = MergeState.Unchanged
    }
}