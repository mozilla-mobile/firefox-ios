// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Sentry

public protocol SentryWrapper {
    var crashedInLastRun: Bool { get }
    var dsn: String? { get }

    func startWithConfigureOptions(configure options: @escaping (Options) -> Void)
    func captureMessage(message: String, with scopeBlock: @escaping (Scope) -> Void)
    func captureError(error: Error)
    func addBreadcrumb(crumb: Breadcrumb)
    func configureScope(scope: @escaping (Scope) -> Void)
}

public class DefaultSentry: SentryWrapper {
    private let dsnKey = "SentryCloudDSN"
    public init() {}

    public var crashedInLastRun: Bool {
        return SentrySDK.crashedLastRun
    }

    public var dsn: String? {
        let bundle = AppInfo.applicationBundle
        guard let dsn = bundle.object(forInfoDictionaryKey: dsnKey) as? String,
              !dsn.isEmpty else {
            return nil
        }
        return dsn
    }

    public func startWithConfigureOptions(configure options: @escaping (Options) -> Void) {
        SentrySDK.start(configureOptions: options)
    }

    public func captureMessage(message: String, with scopeBlock: @escaping (Scope) -> Void) {
        SentrySDK.capture(message: message, block: scopeBlock)
    }

    public func captureError(error: Error) {
        SentrySDK.capture(error: error)
    }

    public func addBreadcrumb(crumb: Breadcrumb) {
        SentrySDK.addBreadcrumb(crumb)
    }

    public func configureScope(scope: @escaping (Scope) -> Void) {
        SentrySDK.configureScope(scope)
    }
}
