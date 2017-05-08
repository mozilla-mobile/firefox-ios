/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Deferred
import Foundation
import Shared
import Storage
import XCGLogger

private let log = Logger.syncLogger

// Because generic protocols in Swift are a pain in the ass.
public protocol BookmarkStorer: class {
    // TODO: this should probably return a timestamp.
    func applyUpstreamCompletionOp(_ op: UpstreamCompletionOp, itemSources: ItemSources, trackingTimesInto local: LocalOverrideCompletionOp) -> Deferred<Maybe<POSTResult>>
}

open class UpstreamCompletionOp: PerhapsNoOp {
    // Upload these records from the buffer, but with these child lists.
    open var amendChildrenFromBuffer: [GUID: [GUID]] = [:]

    // Upload these records from the mirror, but with these child lists.
    open var amendChildrenFromMirror: [GUID: [GUID]] = [:]

    // Upload these records from local, but with these child lists.
    open var amendChildrenFromLocal: [GUID: [GUID]] = [:]

    // Upload these records as-is.
    open var records: [Record<BookmarkBasePayload>] = []

    open let ifUnmodifiedSince: Timestamp?

    open var isNoOp: Bool {
        return records.isEmpty
    }

    public init(ifUnmodifiedSince: Timestamp?=nil) {
        self.ifUnmodifiedSince = ifUnmodifiedSince
    }
}

open class BookmarksMergeResult: PerhapsNoOp {
    let uploadCompletion: UpstreamCompletionOp
    let overrideCompletion: LocalOverrideCompletionOp
    let bufferCompletion: BufferCompletionOp
    let itemSources: ItemSources

    open var isNoOp: Bool {
        return self.uploadCompletion.isNoOp &&
               self.overrideCompletion.isNoOp &&
               self.bufferCompletion.isNoOp
    }

    func applyToClient(_ client: BookmarkStorer, storage: SyncableBookmarks, buffer: BookmarkBufferStorage) -> Success {
        return client.applyUpstreamCompletionOp(self.uploadCompletion, itemSources: self.itemSources, trackingTimesInto: self.overrideCompletion)
         >>> { storage.applyLocalOverrideCompletionOp(self.overrideCompletion, itemSources: self.itemSources) }
         >>> { buffer.applyBufferCompletionOp(self.bufferCompletion, itemSources: self.itemSources) }
    }

    init(uploadCompletion: UpstreamCompletionOp, overrideCompletion: LocalOverrideCompletionOp, bufferCompletion: BufferCompletionOp, itemSources: ItemSources) {
        self.uploadCompletion = uploadCompletion
        self.overrideCompletion = overrideCompletion
        self.bufferCompletion = bufferCompletion
        self.itemSources = itemSources
    }

    static func NoOp(_ itemSources: ItemSources) -> BookmarksMergeResult {
        return BookmarksMergeResult(uploadCompletion: UpstreamCompletionOp(), overrideCompletion: LocalOverrideCompletionOp(), bufferCompletion: BufferCompletionOp(), itemSources: itemSources)
    }
}

// MARK: - Errors.

open class BookmarksMergeError: MaybeErrorType {
    fileprivate let error: Error?

    init(error: Error?=nil) {
        self.error = error
    }

    open var description: String {
        return "Merge error: \(self.error ??? "nil")"
    }
}

open class BookmarksMergeConsistencyError: BookmarksMergeError {
    override open var description: String {
        return "Merge consistency error"
    }
}

open class BookmarksMergeErrorTreeIsUnrooted: BookmarksMergeConsistencyError {
    open let roots: Set<GUID>

    public init(roots: Set<GUID>) {
        self.roots = roots
    }

    override open var description: String {
        return "Tree is unrooted: roots are \(self.roots)"
    }
}

enum MergeState<T> {
    case unknown              // Default state.
    case unchanged            // Nothing changed: no work needed.
    case remote               // Take the associated remote value.
    case local                // Take the associated local value.
    case new(value: T)        // Take this synthesized value.

    var isUnchanged: Bool {
        if case .unchanged = self {
            return true
        }
        return false
    }

    var isUnknown: Bool {
        if case .unknown = self {
            return true
        }
        return false
    }

    var label: String {
        switch self {
        case .unknown:
            return "Unknown"
        case .unchanged:
            return "Unchanged"
        case .remote:
            return "Remote"
        case .local:
            return "Local"
        case .new:
            return "New"
        }
    }
}

func ==<T: Equatable>(lhs: MergeState<T>, rhs: MergeState<T>) -> Bool {
    switch (lhs, rhs) {
    case (.unknown, .unknown):
        return true
    case (.unchanged, .unchanged):
        return true
    case (.remote, .remote):
        return true
    case (.local, .local):
        return true
    case let (.new(lh), .new(rh)):
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

    var hasLocal: Bool { return self.local != nil }
    var hasMirror: Bool { return self.mirror != nil }
    var hasRemote: Bool { return self.remote != nil }

    var valueState: MergeState<BookmarkMirrorItem> = MergeState.unknown
    var structureState: MergeState<BookmarkTreeNode> = MergeState.unknown

    var hasDecidedChildren: Bool {
        return !self.structureState.isUnknown
    }

    var mergedChildren: [MergedTreeNode]?

    // One-sided constructors.
    static func forRemote(_ remote: BookmarkTreeNode, mirror: BookmarkTreeNode?=nil) -> MergedTreeNode {
        let n = MergedTreeNode(guid: remote.recordGUID, mirror: mirror, structureState: MergeState.remote)
        n.remote = remote
        n.valueState = MergeState.remote
        return n
    }

    static func forLocal(_ local: BookmarkTreeNode, mirror: BookmarkTreeNode?=nil) -> MergedTreeNode {
        let n = MergedTreeNode(guid: local.recordGUID, mirror: mirror, structureState: MergeState.local)
        n.local = local
        n.valueState = MergeState.local
        return n
    }

    static func forUnchanged(_ mirror: BookmarkTreeNode) -> MergedTreeNode {
        let n = MergedTreeNode(guid: mirror.recordGUID, mirror: mirror, structureState: MergeState.unchanged)
        n.valueState = MergeState.unchanged
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
    fileprivate var decidedStructure: BookmarkTreeNode? {
        switch self.structureState {
        case .unknown:
            return nil
        case .unchanged:
            return self.mirror
        case .remote:
            return self.remote
        case .local:
            return self.local
        case let .new(node):
            return node
        }
    }

    func asUnmergedTreeNode() -> BookmarkTreeNode {
        return self.decidedStructure ?? BookmarkTreeNode.unknown(guid: self.guid)
    }

    // Recursive. Starts returning Unknown when nodes haven't been processed.
    func asMergedTreeNode() -> BookmarkTreeNode {
        guard let decided = self.decidedStructure,
              let merged = self.mergedChildren else {
            return BookmarkTreeNode.unknown(guid: self.guid)
        }

        if case .folder = decided {
            let children = merged.map { $0.asMergedTreeNode() }
            return BookmarkTreeNode.folder(guid: self.guid, children: children)
        }

        return decided
    }

    var isFolder: Bool {
        return self.mergedChildren != nil
    }

    func dump(_ indent: Int) {
        precondition(indent < 200)
        let r: Character = "R"
        let l: Character = "L"
        let m: Character = "M"
        let ind = indenting(indent)
        print(ind, "[V: ", box(self.remote, r), box(self.mirror, m), box(self.local, l), self.guid, self.valueState.label, "]")
        guard self.isFolder else {
            return
        }

        print(ind, "[S: ", self.structureState.label, "]")
        if let children = self.mergedChildren {
            print(ind, "  ..")
            for child in children {
                child.dump(indent + 2)
            }
        }
    }
}

private func box<T>(_ x: T?, _ c: Character) -> Character {
    if x == nil {
        return "□"
    }
    return c
}

private func indenting(_ by: Int) -> String {
    return String(repeating: " ", count: by)
}

class MergedTree {
    var root: MergedTreeNode
    var deleteLocally: Set<GUID> = Set()
    var deleteRemotely: Set<GUID> = Set()
    var deleteFromMirror: Set<GUID> = Set()
    var acceptLocalDeletion: Set<GUID> = Set()
    var acceptRemoteDeletion: Set<GUID> = Set()

    var allGUIDs: Set<GUID> {
        var out = Set<GUID>([self.root.guid])
        func acc(_ node: MergedTreeNode) {
            guard let children = node.mergedChildren else {
                return
            }
            out.formUnion(Set(children.map { $0.guid }))
            children.forEach(acc)
        }
        acc(self.root)
        return out
    }

    init(mirrorRoot: BookmarkTreeNode) {
        self.root = MergedTreeNode(guid: mirrorRoot.recordGUID, mirror: mirrorRoot, structureState: MergeState.unchanged)
        self.root.valueState = MergeState.unchanged
    }

    func dump() {
        print("Deleted locally: \(self.deleteLocally.joined(separator: ", "))")
        print("Deleted remotely: \(self.deleteRemotely.joined(separator: ", "))")
        print("Deleted from mirror: \(self.deleteFromMirror.joined(separator: ", "))")
        print("Accepted local deletions: \(self.acceptLocalDeletion.joined(separator: ", "))")
        print("Accepted remote deletions: \(self.acceptRemoteDeletion.joined(separator: ", "))")
        print("Root: ")
        self.root.dump(0)
    }
}
