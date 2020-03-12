/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

/// The level of a log message
public enum LogLevel: Int32 {
    /// The log message in question is verbose information which
    /// may contain user PII.
    case trace = 2
    /// The log message in question is verbose information,
    /// but should contain no PII.
    case debug
    /// The log message is informational
    case info
    /// The log message is a warning
    case warn
    /// The log message indicates an error.
    case error

    init(safeRawValue value: Int32) {
        if let result = LogLevel(rawValue: value) {
            self = result
            return
        }

        if value < LogLevel.trace.rawValue {
            self = .trace
        } else {
            self = .error
        }
    }
}

/// An enum representing a maximum log level. It is used with
/// `RustLog.shared.setLevelFilter`.
///
/// This is roughly equivalent to LogLevel, however contains
/// `Off`, for filtering all logging.
public enum LogLevelFilter: Int32 {
    /// Disable all logging
    case off
    /// Only allow `error` logs.
    case error
    /// Allow `warn` and `error` logs.
    case warn
    /// Allow `warn`, `error`, and `info` logs.
    case info
    /// Allow `warn`, `error`, `info`, and `debug` logs. The default.
    case debug
    /// Allow all logs, including those that may contain PII.
    case trace
}

/// The type of the log callback. You can provide a value of this type to
/// `RustLog.shared.enable` or `RustLog.shared.tryEnable`, and it will be called for
/// all log messages emitted by Rust code.
///
/// The first argument is the level of the log. The maximum value of this can
/// be provided using the `RustLog.shared.setLevelFilter` method.
///
/// The second argument is the tag, which is typically a rust module path
/// string. It might be nil in some cases that aren't documented by the
/// underlying rust log crate.
///
/// The last argument is the log message. It will not be nil.
///
/// This callback should return `true` to indicate everything is fine, and
/// false if we should disable the logger. You cannot call `disable()`
/// from inside the callback (it's protected by a dispatch queue you're
/// already running on).
public typealias LogCallback = (_ level: LogLevel, _ tag: String?, _ message: String) -> Bool

/// The public interface to Rust's logger.
///
/// This is a singleton, and should be used via the
/// `shared` static member.
public class RustLog {
    fileprivate let state = RustLogState()
    fileprivate let queue = DispatchQueue(label: "com.mozilla.appservices.rust-log")
    /// The singleton instance of RustLog
    public static let shared = RustLog()

    private init() {}

    /// True if the logger currently has a bound callback.
    public var isEnabled: Bool {
        return queue.sync { state.isEnabled }
    }

    /// Set the current log callback.
    ///
    /// Note that by default, after enabling the level filter
    /// will be at the `debug` level. If you want to increase or decrease it,
    /// you may use `setLevelFilter`
    ///
    ///
    /// See alse `tryEnable`.
    ///
    /// Throws:
    ///
    /// - `RustLogError.alreadyEnabled`: If we're already enabled. Explicitly disable first.
    ///
    /// - `RustLogError.unexpectedError`: If the rust code panics. This shouldn't happen,
    ///   but if it does, we would appreciate reports from telemetry or similar
    public func enable(_ callback: @escaping LogCallback) throws {
        try queue.sync {
            try state.enable(callback)
        }
    }

    /// Set the level filter (the maximum log level) of the logger.
    ///
    /// Throws:
    /// - `RustLogError.unexpectedError`: If the rust code panics. This shouldn't happen,
    ///   but if it does, we would appreciate reports from telemetry or similar
    public func setLevelFilter(filter: LogLevelFilter) throws {
        // Note: Doesn't need to synchronize.
        try rustCall { error in
            rc_log_adapter_set_max_level(filter.rawValue, error)
        }
    }

    /// Disable the previously set logger. This also sets the level filter to `.off`.
    ///
    /// Does nothing if the logger is disabled
    public func disable() {
        queue.sync {
            state.disable()
        }
    }

    /// Enable the logger if possible.
    ///
    /// Returns false in the cases where `enable` would throw, true otherwise.
    ///
    /// If it would throw due to a panic, it also writes some information about
    /// the panic to the provided callback
    public func tryEnable(_ callback: @escaping LogCallback) -> Bool {
        return queue.sync {
            state.tryEnable(callback)
        }
    }

    /// Log a test message at `.info` severity.
    public func logTestMessage(message: String) {
        rc_log_adapter_test__log_msg(message)
    }
}

/// The type of errors reported by RustLog. These either indicate bugs
/// in our logging code (as in `UnexpectedError`), or usage errors
/// (as in `AlreadyEnabled`)
public enum RustLogError: Error {
    /// This generally means a panic occurred, or something went very wrong.
    /// We would appreciate bug reports about when these appear in the wild, if they do.
    case unexpectedError(message: String)

    /// Error indicating that the log adapter cannot be enabled
    /// because it is already enabled.
    ///
    /// This is a usage error, either `disable` it first, or
    /// use `RustLog.shared.tryEnable`
    case alreadyEnabled
}

@discardableResult
private func rustCall<T>(_ callback: (UnsafeMutablePointer<RcLogError>) throws -> T) throws -> T {
    var err = RcLogError(code: 0, message: nil)
    let result = try callback(&err)
    if err.code != 0 {
        let message: String
        if let messageP = err.message {
            defer { rc_log_adapter_destroy_string(messageP) }
            message = String(cString: messageP)
        } else {
            message = "Bug: No message provided with code \(err.code)!"
        }
        throw RustLogError.unexpectedError(message: message)
    }
    return result
}

// This is the function actually passed to Rust.
private func logCallbackFunc(level: Int32, optTagP: UnsafePointer<CChar>?, msgP: UnsafePointer<CChar>) {
    guard let callback = RustLog.shared.state.callback else {
        return
    }
    let msg = String(cString: msgP)
    // Probably a better way to do this...
    let tag: String?
    if let optTagP = optTagP {
        tag = String(cString: optTagP)
    } else {
        tag = nil
    }
    RustLog.shared.queue.async {
        if !callback(LogLevel(safeRawValue: level), tag, msg) {
            RustLog.shared.state.disable()
        }
    }
}

// This implements everything, but without synchronization. It needs to be
// guarded by a queue, which is done by the RustLog class.
private class RustLogState {
    var adapter: OpaquePointer?
    var callback: LogCallback?

    var isEnabled: Bool { return adapter != nil }

    func enable(_ callback: @escaping LogCallback) throws {
        if isEnabled {
            throw RustLogError.alreadyEnabled
        }
        assert(self.callback == nil)
        self.callback = callback
        adapter = try rustCall { error in
            rc_log_adapter_create(logCallbackFunc, error)
        }
    }

    func disable() {
        guard let adapter = self.adapter else {
            return
        }
        self.adapter = nil
        callback = nil
        rc_log_adapter_destroy(adapter)
    }

    func tryEnable(_ callback: @escaping LogCallback) -> Bool {
        if isEnabled {
            return false
        }
        do {
            try enable(callback)
            return true
        } catch {
            _ = callback(.error,
                         "RustLog.swift",
                         "RustLog.enable failed: \(error)")
            return false
        }
    }
}
