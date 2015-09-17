/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import Storage
import XCGLogger

private let log = Logger.syncLogger

public enum BookmarkType: String {
    case livemark
    case separator
    case folder
    case bookmark
    case query
    case microsummary     // Dead: now a bookmark.

    public static func payloadFromJSON(json: JSON) -> BookmarkBasePayload? {
        guard let typeString = json["type"].asString else {
            return nil
        }
        guard let type = BookmarkType.init(rawValue: typeString) else {
            return nil
        }

        let result: BookmarkBasePayload
        switch type {
        case microsummary:
            fallthrough
        case bookmark:
            result = BookmarkPayload(json)
        case folder:
            result = FolderPayload(json)
        case livemark:
            result = LivemarkPayload(json)
        case separator:
            result = SeparatorPayload(json)
        case query:
            result = BookmarkQueryPayload(json)
        }

        if result.isValid() {
            return result
        }
        let id = json["id"].asString ?? "<unknown>"
        log.warning("Record \(id) of type \(type) was invalid.")
        return nil
    }
}

public class LivemarkPayload: BookmarkBasePayload {
    override public func isValid() -> Bool {
        if !super.isValid() {
            return false
        }
        return self.hasRequiredStringFields(["feedUri", "siteUri"])
    }

    override public func equalPayloads(obj: CleartextPayloadJSON) -> Bool {
        guard let p = obj as? LivemarkPayload else {
            return false
        }

        if !super.equalPayloads(p) {
            return false
        }

        if self.deleted {
            return true
        }

        if self["feedUri"].asString != p["feedUri"].asString {
            return false
        }

        if self["siteUri"].asString != p["siteUri"].asString {
            return false
        }

        return true
    }
}

public class SeparatorPayload: BookmarkBasePayload {
    override public func isValid() -> Bool {
        if !super.isValid() {
            return false
        }
        if !self["pos"].isInt {
            log.warning("Separator \(self.id) missing pos.")
            return false
        }
        return true
    }

    override public func equalPayloads(obj: CleartextPayloadJSON) -> Bool {
        guard let p = obj as? SeparatorPayload else {
            return false
        }

        if !super.equalPayloads(p) {
            return false
        }

        if self.deleted {
            return true
        }

        if self["pos"].asInt != p["pos"].asInt {
            return false
        }

        return true
    }
}

public class FolderPayload: BookmarkBasePayload {
    private var childrenAreValid: Bool {
        guard let children = self["children"].asArray else {
            return false
        }
        return children.every({ $0.isString })
    }

    override public func isValid() -> Bool {
        if !super.isValid() {
            return false
        }

        if !self.hasRequiredStringFields(["title", "description"]) {
            log.warning("Folder \(self.id) missing title or description.")
            return false
        }

        if !self.childrenAreValid {
            log.warning("Folder \(self.id) has invalid children.")
            return false
        }

        return true
    }

    public var children: [String] {
        return self["children"].asArray!.map { $0.asString! }
    }

    override public func equalPayloads(obj: CleartextPayloadJSON) -> Bool {
        guard let p = obj as? FolderPayload else {
            return false
        }

        if !super.equalPayloads(p) {
            return false
        }

        if self.deleted {
            return true
        }

        if self["title"].asString != p["title"].asString {
            return false
        }

        if self["description"].asString != p["description"].asString {
            return false
        }

        if self.children != p.children {
            return false
        }

        return true
    }
}

public class BookmarkPayload: BookmarkBasePayload {
    private static let requiredBookmarkStringFields = ["title", "bmkUri", "description", "tags", "keyword"]
    private static let optionalBookmarkBooleanFields = ["loadInSidebar"]

    override public func isValid() -> Bool {
        if !super.isValid() {
            return false
        }

        if !self.hasRequiredStringFields(BookmarkPayload.requiredBookmarkStringFields) {
            log.warning("Bookmark \(self.id) missing required string field.")
            return false
        }

        return self.hasOptionalBooleanFields(BookmarkPayload.optionalBookmarkBooleanFields)
    }

    override public func equalPayloads(obj: CleartextPayloadJSON) -> Bool {
        guard let p = obj as? BookmarkPayload else {
            return false
        }

        if !super.equalPayloads(p) {
            return false
        }

        if self.deleted {
            return true
        }

        if !BookmarkPayload.requiredBookmarkStringFields.every({ p[$0].asString! == self[$0].asString! }) {
            return false
        }

        if self["loadInSidebar"].asBool != p["loadInSidebar"].asBool {
            return false
        }

        return true
    }
}

public class BookmarkQueryPayload: BookmarkPayload {
    override public func isValid() -> Bool {
        if !super.isValid() {
            return false
        }

        if !self.hasRequiredStringFields(["folderName", "queryId"]) {
            log.warning("Query \(self.id) missing required string field.")
            return false
        }

        return true
    }

    override public func equalPayloads(obj: CleartextPayloadJSON) -> Bool {
        guard let p = obj as? BookmarkQueryPayload else {
            return false
        }

        if !super.equalPayloads(p) {
            return false
        }

        if self.deleted {
            return true
        }

        if self["folderName"].asString != p["folderName"].asString {
            return false
        }

        if self["queryId"].asString != p["queryId"].asString {
            return false
        }

        return true
    }
}

public class BookmarkBasePayload: CleartextPayloadJSON {
    private static let requiredStringFields: [String] = ["parentid", "parentName", "type"]
    private static let optionalBooleanFields: [String] = ["hasDupe"]

    func hasRequiredStringFields(fields: [String]) -> Bool {
        return fields.every { self[$0].isString }
    }

    func hasOptionalStringFields(fields: [String]) -> Bool {
        return fields.every { field in
            let val = self[field]
            // Yup, 404 is not found, so this means "string or nothing".
            let valid = val.isString || val.isNull || val.asError?.code == 404
            if !valid {
                log.debug("Field \(field) is invalid: \(val).")
            }
            return valid
        }
    }

    func hasOptionalBooleanFields(fields: [String]) -> Bool {
        return fields.every { field in
            let val = self[field]
            // Yup, 404 is not found, so this means "boolean or nothing".
            let valid = val.isBool || val.isNull || val.asError?.code == 404
            if !valid {
                log.debug("Field \(field) is invalid: \(val).")
            }
            return valid
        }
    }

    override public func isValid() -> Bool {
        if !super.isValid() {
            return false
        }

        if self["deleted"].asBool ?? false {
            return true
        }

        if !self.hasRequiredStringFields(BookmarkBasePayload.requiredStringFields) {
            log.warning("Item missing required string field.")
            return false
        }

        return self.hasOptionalBooleanFields(BookmarkBasePayload.optionalBooleanFields)
    }

    /**
     * This only makes sense for valid payloads.
     */
    override public func equalPayloads(obj: CleartextPayloadJSON) -> Bool {
        guard let p = obj as? BookmarkBasePayload else {
            return false
        }

        if !super.equalPayloads(p) {
            return false;
        }

        if self.deleted {
            return true
        }

        if p.deleted {
            return self.deleted == p.deleted
        }

        // If either record is deleted, these other fields might be missing.
        // But we just checked, so we're good to roll on.

        let same: String -> Bool = { field in
            let left = self[field].asString
            let right = p[field].asString
            return left == right
        }

        if !BookmarkBasePayload.requiredStringFields.every(same) {
            return false
        }

        return (self["hasDupe"].asBool ?? false) == (p["hasDupe"].asBool ?? false)
    }
}
