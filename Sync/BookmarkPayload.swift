/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import Storage
import XCGLogger
import SwiftyJSON

private let log = Logger.syncLogger

public protocol MirrorItemable {
    func toMirrorItem(_ modified: Timestamp) -> BookmarkMirrorItem
}

extension BookmarkMirrorItem {
    func asPayload() -> BookmarkBasePayload {
        return BookmarkType.somePayloadFromJSON(self.asJSON())
    }

    func asPayloadWithChildren(_ children: [GUID]?) -> BookmarkBasePayload {
        let remappedChildren: [GUID]?
        if let children = children {
            if BookmarkRoots.RootGUID == self.guid {
                // Only the root contains roots, and so only its children
                // need to be translated.
                remappedChildren = children.map(BookmarkRoots.translateOutgoingRootGUID)
            } else {
                remappedChildren = children
            }
        } else {
            remappedChildren = nil
        }

        let json = self.asJSONWithChildren(remappedChildren)
        return BookmarkType.somePayloadFromJSON(json)
    }
}

/**
 * Hierarchy:
 * - BookmarkBasePayload
 *   \_ FolderPayload
 *      \_ LivemarkPayload
 *   \_ SeparatorPayload
 *   \_ BookmarkPayload
 *      \_ BookmarkQueryPayload
 */

public enum BookmarkType: String {
    case livemark
    case separator
    case folder
    case bookmark
    case query
    case microsummary     // Dead: now a bookmark.

    // The result might be invalid, but it won't be nil.
    public static func somePayloadFromJSON(_ json: JSON) -> BookmarkBasePayload {
        return payloadFromJSON(json) ?? BookmarkBasePayload(json)
    }

    public static func payloadFromJSON(_ json: JSON) -> BookmarkBasePayload? {
        if json["deleted"].bool ?? false {
            // Deleted records won't have a type.
            return BookmarkBasePayload(json)
        }

        guard let typeString = json["type"].string else {
            return nil
        }

        guard let type = BookmarkType(rawValue: typeString) else {
            return nil
        }

        switch type {
        case microsummary:
            fallthrough
        case bookmark:
            return BookmarkPayload(json)
        case folder:
            return FolderPayload(json)
        case livemark:
            return LivemarkPayload(json)
        case separator:
            return SeparatorPayload(json)
        case query:
            return BookmarkQueryPayload(json)
        }
    }

    public static func isValid(_ type: String?) -> Bool {
        guard let type = type else {
            return false
        }

        return BookmarkType(rawValue: type) != nil
    }
}

open class LivemarkPayload: BookmarkBasePayload {
    open var feedURI: String? {
        return self["feedUri"].string
    }

    open var siteURI: String? {
        return self["siteUri"].string
    }

    override open func isValid() -> Bool {
        if !super.isValid() {
            return false
        }
        return self.hasRequiredStringFields(["feedUri", "siteUri"])
    }

    override open func equalPayloads(_ obj: CleartextPayloadJSON) -> Bool {
        guard let p = obj as? LivemarkPayload else {
            return false
        }

        if !super.equalPayloads(p) {
            return false
        }

        if self.deleted {
            return true
        }

        if self.feedURI != p.feedURI {
            return false
        }

        if self.siteURI != p.siteURI {
            return false
        }

        return true
    }

    override open func toMirrorItem(_ modified: Timestamp) -> BookmarkMirrorItem {
        if self.deleted {
            return BookmarkMirrorItem.deleted(.livemark, guid: self.id, modified: modified)
        }

        return BookmarkMirrorItem.livemark(
            self.id,
            modified: modified,
            hasDupe: self.hasDupe,
            // TODO: these might need to be weakened if real-world data is dirty.
            parentID: self["parentid"].stringValue,
            parentName: self["parentName"].string,
            title: self["title"].string,
            description: self["description"].string,
            feedURI: self.feedURI!,
            siteURI: self.siteURI!
        )
    }
}

open class SeparatorPayload: BookmarkBasePayload {
    override open func isValid() -> Bool {
        if !super.isValid() {
            return false
        }
        if !self["pos"].isInt() {
            log.warning("Separator \(self.id) missing pos.")
            return false
        }
        return true
    }

    override open func equalPayloads(_ obj: CleartextPayloadJSON) -> Bool {
        guard let p = obj as? SeparatorPayload else {
            return false
        }

        if !super.equalPayloads(p) {
            return false
        }

        if self.deleted {
            return true
        }

        if self["pos"].int != p["pos"].int {
            return false
        }

        return true
    }

    override open func toMirrorItem(_ modified: Timestamp) -> BookmarkMirrorItem {
        if self.deleted {
            return BookmarkMirrorItem.deleted(.separator, guid: self.id, modified: modified)
        }

        return BookmarkMirrorItem.separator(
            self.id,
            modified: modified,
            hasDupe: self.hasDupe,
            // TODO: these might need to be weakened if real-world data is dirty.
            parentID: self["parentid"].string!,
            parentName: self["parentName"].string,
            pos: self["pos"].int!
        )
    }
}

open class FolderPayload: BookmarkBasePayload {
    fileprivate var childrenAreValid: Bool {
        return self.hasStringArrayField("children")
    }

    override open func isValid() -> Bool {
        if !super.isValid() {
            return false
        }

        if !self.hasRequiredStringFields(["title"]) {
            log.warning("Folder \(self.id) missing title.")
            return false
        }

        if !self.hasOptionalStringFields(["description"]) {
            log.warning("Folder \(self.id) missing string description.")
            return false

        }
        if !self.childrenAreValid {
            log.warning("Folder \(self.id) has invalid children.")
            return false
        }

        return true
    }

    open var children: [String] {
        return self["children"].arrayValue.map { $0.string! }
    }

    override open func equalPayloads(_ obj: CleartextPayloadJSON) -> Bool {
        guard let p = obj as? FolderPayload else {
            return false
        }

        if !super.equalPayloads(p) {
            return false
        }

        if self.deleted {
            return true
        }

        if self["title"].string != p["title"].string {
            return false
        }

        if self["description"].string != p["description"].string {
            return false
        }

        if self.children != p.children {
            return false
        }

        return true
    }

    override open func toMirrorItem(_ modified: Timestamp) -> BookmarkMirrorItem {
        if self.deleted {
            return BookmarkMirrorItem.deleted(.folder, guid: self.id, modified: modified)
        }

        return BookmarkMirrorItem.folder(
            self.id,
            modified: modified,
            hasDupe: self.hasDupe,
            // TODO: these might need to be weakened if real-world data is dirty.
            parentID: self["parentid"].string!,
            parentName: self["parentName"].string,
            title: self["title"].string!,
            description: self["description"].string,
            children: self.children
        )
    }
}

open class BookmarkPayload: BookmarkBasePayload {
    fileprivate static let requiredBookmarkStringFields = ["bmkUri"]

    // Title *should* be required, but can be missing for queries. Great.
    fileprivate static let optionalBookmarkStringFields = ["title", "keyword", "description"]
    fileprivate static let optionalBookmarkBooleanFields = ["loadInSidebar"]

    override open func isValid() -> Bool {
        if !super.isValid() {
            return false
        }

        if !self.hasRequiredStringFields(BookmarkPayload.requiredBookmarkStringFields) {
            log.warning("Bookmark \(self.id) missing required string field.")
            return false
        }

        if !self.hasStringArrayField("tags") {
            log.warning("Bookmark \(self.id) missing tags array. We'll replace with an empty array.")
            // Ignore.
        }

        if !self.hasOptionalStringFields(BookmarkPayload.optionalBookmarkStringFields) {
            return false
        }

        return self.hasOptionalBooleanFields(BookmarkPayload.optionalBookmarkBooleanFields)
    }

    override open func equalPayloads(_ obj: CleartextPayloadJSON) -> Bool {
        guard let p = obj as? BookmarkPayload else {
            return false
        }

        if !super.equalPayloads(p) {
            return false
        }

        if self.deleted {
            return true
        }

        if !BookmarkPayload.requiredBookmarkStringFields.every({ p[$0].string! == self[$0].string! }) {
            return false
        }

        // TODO: compare optional fields.

        if Set(self.tags) != Set(p.tags) {
            return false
        }

        if self["loadInSidebar"].bool != p["loadInSidebar"].bool {
            return false
        }

        return true
    }

    lazy var tags: [String] = {
        return self["tags"].arrayValue.flatMap { $0.string } 
    }()

    lazy var tagsString: String = {
        if self["tags"].isArray() {
            return self["tags"].stringValue() ?? "[]"
        }
        return "[]"
    }()

    override open func toMirrorItem(_ modified: Timestamp) -> BookmarkMirrorItem {
        if self.deleted {
            return BookmarkMirrorItem.deleted(.bookmark, guid: self.id, modified: modified)
        }

        return BookmarkMirrorItem.bookmark(
            self.id,
            modified: modified,
            hasDupe: self.hasDupe,
            // TODO: these might need to be weakened if real-world data is dirty.
            parentID: self["parentid"].string!,
            parentName: self["parentName"].string,
            title: self["title"].string ?? "",
            description: self["description"].string,
            URI: self["bmkUri"].string!,
            tags: self.tagsString,           // Stringify it so we can put the array in the DB.
            keyword: self["keyword"].string
        )
    }
}

open class BookmarkQueryPayload: BookmarkPayload {
    override open func isValid() -> Bool {
        if !super.isValid() {
            return false
        }

        if !self.hasOptionalStringFields(["queryId", "folderName"]) {
            log.warning("Query \(self.id) missing queryId or folderName.")
            return false
        }

        return true
    }

    override open func equalPayloads(_ obj: CleartextPayloadJSON) -> Bool {
        guard let p = obj as? BookmarkQueryPayload else {
            return false
        }

        if !super.equalPayloads(p) {
            return false
        }

        if self.deleted {
            return true
        }

        if self["folderName"].string != p["folderName"].string {
            return false
        }

        if self["queryId"].string != p["queryId"].string {
            return false
        }

        return true
    }

    override open func toMirrorItem(_ modified: Timestamp) -> BookmarkMirrorItem {
        if self.deleted {
            return BookmarkMirrorItem.deleted(.query, guid: self.id, modified: modified)
        }

        return BookmarkMirrorItem.query(
            self.id,
            modified: modified,
            hasDupe: self.hasDupe,
            parentID: self["parentid"].string!,
            parentName: self["parentName"].string,
            title: self["title"].string ?? "",
            description: self["description"].string,
            URI: self["bmkUri"].string!,
            tags: self.tagsString,           // Stringify it so we can put the array in the DB.
            keyword: self["keyword"].string,
            folderName: self["folderName"].string,
            queryID: self["queryID"].string
        )
    }
}

open class BookmarkBasePayload: CleartextPayloadJSON, MirrorItemable {
    fileprivate static let requiredStringFields: [String] = ["parentid", "type"]
    fileprivate static let optionalBooleanFields: [String] = ["hasDupe"]

    static func deletedPayload(_ guid: GUID) -> BookmarkBasePayload {
        let remappedGUID = BookmarkRoots.translateOutgoingRootGUID(guid)
        return BookmarkBasePayload(JSON(["id": remappedGUID, "deleted": true]))
    }

    func hasStringArrayField(_ name: String) -> Bool {
        guard let arr = self[name].array else {
            return false
        }
        return arr.every { $0.isString() }
    }

    func hasRequiredStringFields(_ fields: [String]) -> Bool {
        return fields.every { self[$0].isString() }
    }

    func hasOptionalStringFields(_ fields: [String]) -> Bool {
        return fields.every { field in
            let val = self[field]
            // Yup, 404 is not found, so this means "string or nothing".
            let valid = val.isString() || val.isNull() || val.isError()
            if !valid {
                log.debug("Field \(field) is invalid: \(val).")
            }
            return valid
        }
    }

    func hasOptionalBooleanFields(_ fields: [String]) -> Bool {
        return fields.every { field in
            let val = self[field]
            // Yup, 404 is not found, so this means "boolean or nothing".
            let valid = val.isBool() || val.isNull() || val.error?.code == 404
            if !valid {
                log.debug("Field \(field) is invalid: \(val).")
            }
            return valid
        }
    }

    override open func isValid() -> Bool {
        if !super.isValid() {
            return false
        }

        if self["deleted"].bool ?? false {
            return true
        }

        // If not deleted, we must be a specific, known, type!
        if !BookmarkType.isValid(self["type"].string) {
            return false
        }

        if !(self["parentName"].isString() || self.id == "places") {
            if self["parentid"].string! == "places" {
                log.debug("Accepting root with missing parent name.")
            } else {
                // Bug 1318414.
                log.warning("Accepting bookmark with missing parent name.")
            }
        }

        if !self.hasRequiredStringFields(BookmarkBasePayload.requiredStringFields) {
            log.warning("Item missing required string field.")
            return false
        }

        return self.hasOptionalBooleanFields(BookmarkBasePayload.optionalBooleanFields)
    }

    open var hasDupe: Bool {
        return self["hasDupe"].bool ?? false
    }

    /**
     * This only makes sense for valid payloads.
     */
    override open func equalPayloads(_ obj: CleartextPayloadJSON) -> Bool {
        guard let p = obj as? BookmarkBasePayload else {
            return false
        }

        if !super.equalPayloads(p) {
            return false
        }

        if self.deleted {
            return true
        }

        if p.deleted {
            return self.deleted == p.deleted
        }

        // If either record is deleted, these other fields might be missing.
        // But we just checked, so we're good to roll on.

        let same: (String) -> Bool = { field in
            let left = self[field].string
            let right = p[field].string
            return left == right
        }

        if !BookmarkBasePayload.requiredStringFields.every(same) {
            return false
        }

        if p["parentName"].string != self["parentName"].string {
            return false
        }

        return self.hasDupe == p.hasDupe
    }

    // This goes here because extensions cannot override methods yet.
    open func toMirrorItem(_ modified: Timestamp) -> BookmarkMirrorItem {
        precondition(self.deleted, "Non-deleted items should have a specific type.")
        return BookmarkMirrorItem.deleted(.bookmark, guid: self.id, modified: modified)
    }
}
