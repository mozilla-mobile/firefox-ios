// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public class RustSyncTelemetryPing {
    public let version: Int
    public let uid: String
    public let events: [EventInfo]
    public let syncs: [SyncInfo]

    private static let EMPTY_UID = String(repeating: "0", count: 32)

    init(version: Int, uid: String, events: [EventInfo], syncs: [SyncInfo]) {
        self.version = version
        self.uid = uid
        self.events = events
        self.syncs = syncs
    }

    static func empty() -> RustSyncTelemetryPing {
        return RustSyncTelemetryPing(version: 1,
                                     uid: EMPTY_UID,
                                     events: [EventInfo](),
                                     syncs: [SyncInfo]())
    }

    static func fromJSON(jsonObject: [String: Any]) throws -> RustSyncTelemetryPing {
        guard let version = jsonObject["version"] as? Int else {
            throw TelemetryJSONError.intValueNotFound(
                message: "RustSyncTelemetryPing `version` property not found")
        }

        let events = unwrapFromJSON(jsonObject: jsonObject) { obj in
            try EventInfo.fromJSONArray(
                jsonArray: obj["events"] as? [[String: Any]] ?? [[String: Any]]())
        } ?? [EventInfo]()

        let syncs = unwrapFromJSON(jsonObject: jsonObject) { obj in
            try SyncInfo.fromJSONArray(
                jsonArray: obj["syncs"] as? [[String: Any]] ?? [[String: Any]]())
        } ?? [SyncInfo]()

        return try RustSyncTelemetryPing(version: version,
                                         uid: stringOrNull(jsonObject: jsonObject,
                                                           key: "uid") ?? EMPTY_UID,
                                         events: events, syncs: syncs)
    }

    public static func fromJSONString(jsonObjectText: String) throws -> RustSyncTelemetryPing {
        guard let data = jsonObjectText.data(using: .utf8) else {
            throw TelemetryJSONError.invalidJSONString
        }

        let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [String: Any]()
        return try fromJSON(jsonObject: jsonObject)
    }
}

public class SyncInfo {
    public let at: Int64
    public let took: Int64
    public let engines: [EngineInfo]
    public let failureReason: FailureReason?

    init(at: Int64, took: Int64, engines: [EngineInfo], failureReason: FailureReason?) {
        self.at = at
        self.took = took
        self.engines = engines
        self.failureReason = failureReason
    }

    static func fromJSON(jsonObject: [String: Any]) throws -> SyncInfo {
        guard let at = jsonObject["when"] as? Int64 else {
            throw TelemetryJSONError.intValueNotFound(
                message: "SyncInfo `when` property not found")
        }

        let engines = unwrapFromJSON(jsonObject: jsonObject) { obj in
            try EngineInfo.fromJSONArray(
                jsonArray: obj["engines"] as? [[String: Any]] ?? [[String: Any]]())
        } ?? [EngineInfo]()

        let failureReason = unwrapFromJSON(jsonObject: jsonObject) { obj in
            FailureReason.fromJSON(
                jsonObject: obj["failureReason"] as? [String: Any] ?? [String: Any]())
        } as? FailureReason

        return SyncInfo(at: at,
                        took: int64OrZero(jsonObject: jsonObject, key: "took"),
                        engines: engines,
                        failureReason: failureReason)
    }

    static func fromJSONArray(jsonArray: [[String: Any]]) throws -> [SyncInfo] {
        var result = [SyncInfo]()

        for item in jsonArray {
            try result.append(fromJSON(jsonObject: item))
        }

        return result
    }
}

public class EngineInfo {
    public let name: String
    public let at: Int64
    public let took: Int64
    public let incoming: IncomingInfo?
    public let outgoing: [OutgoingInfo]
    public let failureReason: FailureReason?
    public let validation: ValidationInfo?

    init(
        name: String,
        at: Int64,
        took: Int64,
        incoming: IncomingInfo?,
        outgoing: [OutgoingInfo],
        failureReason: FailureReason?,
        validation: ValidationInfo?
    ) {
        self.name = name
        self.at = at
        self.took = took
        self.incoming = incoming
        self.outgoing = outgoing
        self.failureReason = failureReason
        self.validation = validation
    }

    static func fromJSON(jsonObject: [String: Any]) throws -> EngineInfo {
        guard let name = jsonObject["name"] as? String else {
            throw TelemetryJSONError.stringValueNotFound
        }

        guard let at = jsonObject["when"] as? Int64 else {
            throw TelemetryJSONError.intValueNotFound(
                message: "EngineInfo `at` property not found")
        }

        guard let took = jsonObject["took"] as? Int64 else {
            throw TelemetryJSONError.intValueNotFound(
                message: "EngineInfo `took` property not found")
        }

        let incoming = unwrapFromJSON(jsonObject: jsonObject) { obj in
            IncomingInfo.fromJSON(
                jsonObject: obj["incoming"] as? [String: Any] ?? [String: Any]())
        }

        let outgoing = unwrapFromJSON(jsonObject: jsonObject) { obj in
            OutgoingInfo.fromJSONArray(
                jsonArray: obj["outgoing"] as? [[String: Any]] ?? [[String: Any]]())
        } ?? [OutgoingInfo]()

        let failureReason = unwrapFromJSON(jsonObject: jsonObject) { obj in
            FailureReason.fromJSON(
                jsonObject: obj["failureReason"] as? [String: Any] ?? [String: Any]())
        } as? FailureReason

        let validation = unwrapFromJSON(jsonObject: jsonObject) { obj in
            try ValidationInfo.fromJSON(
                jsonObject: obj["validation"] as? [String: Any] ?? [String: Any]())
        }

        return EngineInfo(name: name,
                          at: at,
                          took: took,
                          incoming: incoming,
                          outgoing: outgoing,
                          failureReason: failureReason,
                          validation: validation)
    }

    static func fromJSONArray(jsonArray: [[String: Any]]) throws -> [EngineInfo] {
        var result = [EngineInfo]()

        for item in jsonArray {
            try result.append(fromJSON(jsonObject: item))
        }

        return result
    }
}

public class IncomingInfo {
    public let applied: Int
    public let failed: Int
    public let newFailed: Int
    public let reconciled: Int

    init(applied: Int, failed: Int, newFailed: Int, reconciled: Int) {
        self.applied = applied
        self.failed = failed
        self.newFailed = newFailed
        self.reconciled = reconciled
    }

    static func fromJSON(jsonObject: [String: Any]) -> IncomingInfo {
        return IncomingInfo(applied: intOrZero(jsonObject: jsonObject, key: "applied"),
                            failed: intOrZero(jsonObject: jsonObject, key: "failed"),
                            newFailed: intOrZero(jsonObject: jsonObject, key: "newFailed"),
                            reconciled: intOrZero(jsonObject: jsonObject, key: "reconciled"))
    }
}

public class OutgoingInfo {
    public let sent: Int
    public let failed: Int

    init(sent: Int, failed: Int) {
        self.sent = sent
        self.failed = failed
    }

    static func fromJSON(jsonObject: [String: Any]) -> OutgoingInfo {
        return OutgoingInfo(sent: intOrZero(jsonObject: jsonObject, key: "sent"),
                            failed: intOrZero(jsonObject: jsonObject, key: "failed"))
    }

    static func fromJSONArray(jsonArray: [[String: Any]]) -> [OutgoingInfo] {
        var result = [OutgoingInfo]()

        for item in jsonArray {
            result.append(fromJSON(jsonObject: item))
        }

        return result
    }
}

public class ValidationInfo {
    public let version: Int
    public let problems: [ProblemInfo]
    public let failureReason: FailureReason?

    init(version: Int, problems: [ProblemInfo], failureReason: FailureReason?) {
        self.version = version
        self.problems = problems
        self.failureReason = failureReason
    }

    static func fromJSON(jsonObject: [String: Any]) throws -> ValidationInfo {
        guard let version = jsonObject["version"] as? Int else {
            throw TelemetryJSONError.intValueNotFound(
                message: "ValidationInfo `version` property not found")
        }

        let problems = unwrapFromJSON(jsonObject: jsonObject) { obj in
            guard let problemJSON = obj["outgoing"] as? [[String: Any]] else {
                return [ProblemInfo]()
            }

            return try ProblemInfo.fromJSONArray(jsonArray: problemJSON)
        } ?? [ProblemInfo]()

        let failureReason = unwrapFromJSON(jsonObject: jsonObject) { obj in
            FailureReason.fromJSON(
                jsonObject: obj["failureReason"] as? [String: Any] ?? [String: Any]())
        } as? FailureReason

        return ValidationInfo(version: version,
                              problems: problems,
                              failureReason: failureReason)
    }
}

public class ProblemInfo {
    public let name: String
    public let count: Int

    public init(name: String, count: Int) {
        self.name = name
        self.count = count
    }

    static func fromJSON(jsonObject: [String: Any]) throws -> ProblemInfo {
        guard let name = jsonObject["name"] as? String else {
            throw TelemetryJSONError.stringValueNotFound
        }
        return ProblemInfo(name: name,
                           count: intOrZero(jsonObject: jsonObject, key: "count"))
    }

    static func fromJSONArray(jsonArray: [[String: Any]]) throws -> [ProblemInfo] {
        var result = [ProblemInfo]()

        for item in jsonArray {
            try result.append(fromJSON(jsonObject: item))
        }

        return result
    }
}

public enum FailureName {
    case shutdown
    case other
    case unexpected
    case auth
    case http
    case unknown
}

public struct FailureReason {
    public let name: FailureName
    public let message: String?
    public let code: Int

    public init(name: FailureName, message: String? = nil, code: Int = -1) {
        self.name = name
        self.message = message
        self.code = code
    }

    static func fromJSON(jsonObject: [String: Any]) -> FailureReason? {
        guard let name = jsonObject["name"] as? String else {
            return nil
        }

        switch name {
        case "shutdownerror":
            return FailureReason(name: FailureName.shutdown)
        case "othererror":
            return FailureReason(name: FailureName.other,
                                 message: jsonObject["error"] as? String)
        case "unexpectederror":
            return FailureReason(name: FailureName.unexpected,
                                 message: jsonObject["error"] as? String)
        case "autherror":
            return FailureReason(name: FailureName.auth,
                                 message: jsonObject["from"] as? String)
        case "httperror":
            return FailureReason(name: FailureName.http,
                                 code: jsonObject["code"] as? Int ?? -1)
        default:
            return FailureReason(name: FailureName.unknown)
        }
    }
}

public class EventInfo {
    public let obj: String
    public let method: String
    public let value: String?
    public let extra: [String: String]

    public init(obj: String, method: String, value: String?, extra: [String: String]) {
        self.obj = obj
        self.method = method
        self.value = value
        self.extra = extra
    }

    static func fromJSON(jsonObject: [String: Any]) throws -> EventInfo {
        let extra = unwrapFromJSON(jsonObject: jsonObject) { (json: [String: Any]) -> [String: String] in
            if json["extra"] as? [String: Any] == nil {
                return [String: String]()
            } else {
                var extraValues = [String: String]()

                for key in json.keys {
                    extraValues[key] = extraValues[key]
                }

                return extraValues
            }
        }

        return try EventInfo(obj: jsonObject["object"] as? String ?? "",
                             method: jsonObject["method"] as? String ?? "",
                             value: stringOrNull(jsonObject: jsonObject, key: "value"),
                             extra: extra ?? [String: String]())
    }

    static func fromJSONArray(jsonArray: [[String: Any]]) throws -> [EventInfo] {
        var result = [EventInfo]()

        for item in jsonArray {
            try result.append(fromJSON(jsonObject: item))
        }

        return result
    }
}

func unwrapFromJSON<T>(
    jsonObject: [String: Any],
    f: @escaping ([String: Any]) throws -> T
) -> T? {
    do {
        return try f(jsonObject)
    } catch {
        return nil
    }
}

enum TelemetryJSONError: Error {
    case stringValueNotFound
    case intValueNotFound(message: String)
    case invalidJSONString
}

func stringOrNull(jsonObject: [String: Any], key: String) throws -> String? {
    return unwrapFromJSON(jsonObject: jsonObject) { data in
        guard let value = data[key] as? String else {
            throw TelemetryJSONError.stringValueNotFound
        }

        return value
    }
}

func int64OrZero(jsonObject: [String: Any], key: String) -> Int64 {
    return unwrapFromJSON(jsonObject: jsonObject) { data in
        guard let value = data[key] as? Int64 else {
            return 0
        }

        return value
    } ?? 0
}

func intOrZero(jsonObject: [String: Any], key: String) -> Int {
    return unwrapFromJSON(jsonObject: jsonObject) { data in
        guard let value = data[key] as? Int else {
            return 0
        }

        return value
    } ?? 0
}
