// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Network

enum GleanPingServerError: Error {
    case notReady
}

/// A request `GleanPingServer` couldn't read as a Glean ping, kept to explain the failure in the test report.
struct RejectedRequest: Sendable, CustomStringConvertible {
    let path: String
    let reason: String
    let body: Data

    var description: String {
        "\(path) (\(body.count) bytes): \(reason)"
    }
}

/// Minimal HTTP server, running in the test runner, that receives the Glean pings the app uploads when
/// launched with `LaunchArguments.GleanTestServerEndpoint`. Every request is answered with `200 OK`, so Glean
/// treats the ping as delivered and doesn't retry it.
/// Plain HTTP is enough: traffic never leaves the loopback interface, and the app allows it through
/// `NSAllowsArbitraryLoads`.
final class GleanPingServer: @unchecked Sendable {
    private let queue = DispatchQueue(label: "org.mozilla.xcuitests.GleanPingServer")
    private let lock = NSLock()
    private var listener: NWListener?
    private var receivedPings: [GleanPing] = []
    private var rejectedRequests: [RejectedRequest] = []

    /// Pings received so far, in arrival order.
    var pings: [GleanPing] {
        lock.withLock { receivedPings }
    }

    /// Requests that couldn't be read as a Glean ping, e.g. an unexpected path or a body that isn't valid JSON.
    /// They are still answered with `200 OK`, so the app doesn't retry them.
    var rejected: [RejectedRequest] {
        lock.withLock { rejectedRequests }
    }

    /// Starts listening on a free loopback port.
    /// - Returns: The endpoint to pass to the app through `LaunchArguments.GleanTestServerEndpoint`.
    func start() throws -> String {
        let parameters = NWParameters.tcp
        parameters.requiredLocalEndpoint = .hostPort(host: .ipv4(.loopback), port: .any)
        let listener = try NWListener(using: parameters)
        let ready = DispatchSemaphore(value: 0)
        listener.stateUpdateHandler = { state in
            if case .ready = state { ready.signal() }
        }
        listener.newConnectionHandler = { [weak self] connection in
            self?.receive(on: connection)
        }
        listener.start(queue: queue)

        guard ready.wait(timeout: .now() + 5) == .success, let port = listener.port else {
            listener.cancel()
            throw GleanPingServerError.notReady
        }
        self.listener = listener
        return "http://127.0.0.1:\(port.rawValue)"
    }

    func stop() {
        listener?.cancel()
        listener = nil
    }

    private func receive(on connection: NWConnection) {
        connection.start(queue: queue)
        read(from: connection, buffer: Data())
    }

    private func read(from connection: NWConnection, buffer: Data) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65_536) { [weak self] data, _, isComplete, error in
            guard let self else { return }
            var buffer = buffer
            if let data { buffer.append(data) }

            if let request = HTTPRequest(buffer) {
                do {
                    let ping = try GleanPing(path: request.path, body: request.body)
                    lock.withLock { receivedPings.append(ping) }
                } catch {
                    let reason = [request.decodingIssue, "\(error)"].compactMap { $0 }.joined(separator: "; ")
                    let rejection = RejectedRequest(path: request.path, reason: reason, body: request.body)
                    lock.withLock { rejectedRequests.append(rejection) }
                }
                respond(on: connection)
            } else if isComplete || error != nil {
                connection.cancel()
            } else {
                read(from: connection, buffer: buffer)
            }
        }
    }

    private func respond(on connection: NWConnection) {
        let response = Data("HTTP/1.1 200 OK\r\nContent-Length: 0\r\nConnection: close\r\n\r\n".utf8)
        connection.send(content: response, completion: .contentProcessed { _ in connection.cancel() })
    }
}

/// A complete HTTP request parsed from raw bytes, or `nil` while the request is still incomplete.
private struct HTTPRequest {
    let path: String
    let body: Data
    /// Set when the body says it's gzip but couldn't be inflated; `body` is then the raw compressed bytes.
    let decodingIssue: String?

    init?(_ data: Data) {
        guard let headerEnd = data.range(of: Data("\r\n\r\n".utf8)),
              let head = String(data: data[data.startIndex..<headerEnd.lowerBound], encoding: .utf8) else {
            return nil
        }
        let lines = head.components(separatedBy: "\r\n")
        let requestLine = lines.first?.split(separator: " ") ?? []
        guard requestLine.count >= 2 else { return nil }

        var headers: [String: String] = [:]
        for line in lines.dropFirst() {
            guard let separator = line.firstIndex(of: ":") else { continue }
            let name = line[..<separator].lowercased()
            headers[name] = line[line.index(after: separator)...].trimmingCharacters(in: .whitespaces)
        }

        let contentLength = Int(headers["content-length"] ?? "") ?? 0
        let body = data[headerEnd.upperBound...]
        guard body.count >= contentLength else { return nil }

        let rawBody = Data(body.prefix(contentLength))
        self.path = String(requestLine[1])
        if headers["content-encoding"] == "gzip" {
            let inflated = rawBody.gunzipped()
            self.body = inflated ?? rawBody
            self.decodingIssue = inflated == nil ? "gzip decompression failed" : nil
        } else {
            self.body = rawBody
            self.decodingIssue = nil
        }
    }
}

private extension Data {
    /// Inflates a gzip member (RFC 1952). `NSData`'s `.zlib` algorithm decodes the raw DEFLATE stream inside it.
    func gunzipped() -> Data? {
        let bytes = [UInt8](self)
        guard bytes.count > 18, bytes[0] == 0x1f, bytes[1] == 0x8b else { return nil }

        let flags = bytes[3]
        var index = 10
        if flags & 0x04 != 0 { index += 2 + (Int(bytes[index]) | Int(bytes[index + 1]) << 8) }
        if flags & 0x08 != 0 { index = (bytes[index...].firstIndex(of: 0) ?? bytes.count) + 1 }
        if flags & 0x10 != 0 { index = (bytes[index...].firstIndex(of: 0) ?? bytes.count) + 1 }
        if flags & 0x02 != 0 { index += 2 }
        guard index < bytes.count - 8 else { return nil }

        let deflate = Data(bytes[index..<(bytes.count - 8)])
        return try? (deflate as NSData).decompressed(using: .zlib) as Data
    }
}
