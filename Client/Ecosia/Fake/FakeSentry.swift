/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

class Client {
    static var shared: Client?
    init(dsn: String) throws {}
    func crashedLastLaunch() -> Bool { return false }
    func startCrashHandler() throws {}
    func crash() {}
    func send(event: Event, completion: SentryRequestFinished?) {}

    var beforeSerializeEvent: ((Event)->())?
    func snapshotStacktrace(_ finished: () -> ()) {}
    func appendStacktrace(to: Event) {}
    var breadcrumbs: Breadcrumb = Breadcrumb(level: .debug, category: "")
}

public enum SentryLevel: Int {
    case fatal = 0
    case error = 1
    case warning = 2
    case info = 3
    case debug = 4
}

public class Event {
    var context: Context?
    var extra: [String: Any]?
    var message: SentryMessage?
    var tags: [String: String]?
    var debugMeta: String?

    init(level: SentryLevel) {}
}

public class Context {
    var appContext: [String: Any]?
}

public class Breadcrumb {
    var message: String?
    init(level: SentryLevel, category: String) {}

    func add(_ b: Breadcrumb) {}
    func clear() {}
}

public typealias SentryRequestFinished = ((Error?) -> Void)

struct SentryMessage {
    let formatted: String
}
