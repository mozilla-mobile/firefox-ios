// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Network

/// In-runner HTTP-only site that never answers TLS handshakes, so an HTTPS upgrade times out and
/// falls back to HTTP. Handshakes are counted to tell whether the browser attempted HTTPS.
final class HTTPSTimeoutServer: @unchecked Sendable {
    static let timeoutLinkText = "Timeout on secure site"

    private let listener: NWListener
    private let queue = DispatchQueue(label: "org.mozilla.ios.HTTPSTimeoutServer")
    private let lock = NSLock()
    private var handshakeCount = 0
    private var pageCount = 0
    private var stalledConnections: [NWConnection] = []
    private(set) var port: UInt16 = 0

    /// Number of TLS handshakes, i.e. HTTPS attempts, received since the server started.
    var httpsAttempts: Int {
        lock.lock()
        defer { lock.unlock() }
        return handshakeCount
    }

    /// Number of pages served over HTTP, favicon requests excluded.
    var pagesServed: Int {
        lock.lock()
        defer { lock.unlock() }
        return pageCount
    }

    /// Blocks until more than `count` pages have been served, returning false on timeout.
    func waitForPagesServed(moreThan count: Int, timeout: TimeInterval) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while pagesServed <= count {
            if Date() > deadline { return false }
            Thread.sleep(forTimeInterval: 0.1)
        }
        return true
    }

    init() throws {
        let parameters = NWParameters.tcp
        parameters.requiredLocalEndpoint = .hostPort(host: .ipv4(.loopback), port: .any)
        listener = try NWListener(using: parameters)
    }

    /// Starts listening on a free loopback port and returns once `port` is known.
    func start(timeout: TimeInterval = 10) throws {
        let ready = DispatchSemaphore(value: 0)
        listener.stateUpdateHandler = { state in
            if case .ready = state { ready.signal() }
        }
        listener.newConnectionHandler = { [weak self] connection in
            self?.handle(connection)
        }
        listener.start(queue: queue)
        guard ready.wait(timeout: .now() + timeout) == .success, let port = listener.port?.rawValue else {
            throw NSError(
                domain: "HTTPSTimeoutServer",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "The local server did not start"]
            )
        }
        self.port = port
    }

    func stop() {
        listener.cancel()
        lock.lock()
        let connections = stalledConnections
        stalledConnections.removeAll()
        lock.unlock()
        connections.forEach { $0.cancel() }
    }

    /// Page served on every host and path, linking to the `timeout` host of the same server.
    /// Without the scheme, the address is what a user types to let the browser pick HTTP or HTTPS.
    func timeoutSiteURL(host: String = "timeout.localtest.me", includesScheme: Bool = true) -> String {
        let address = "\(host):\(port)/"
        return includesScheme ? "http://\(address)" : address
    }

    private func handle(_ connection: NWConnection) {
        connection.start(queue: queue)
        connection.receive(minimumIncompleteLength: 1, maximumLength: 4096) { [weak self] data, _, _, _ in
            guard let self, let data, let firstByte = data.first else {
                connection.cancel()
                return
            }
            // 0x16 opens a TLS handshake record
            if firstByte == 0x16 {
                self.stall(connection)
            } else {
                self.respond(to: data, on: connection)
            }
        }
    }

    private func stall(_ connection: NWConnection) {
        lock.lock()
        handshakeCount += 1
        stalledConnections.append(connection)
        lock.unlock()
        // Drain until the client gives up, without ever answering the handshake
        drain(connection)
    }

    private func drain(_ connection: NWConnection) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 4096) { [weak self] _, _, isComplete, error in
            if isComplete || error != nil {
                connection.cancel()
            } else {
                self?.drain(connection)
            }
        }
    }

    private func respond(to request: Data, on connection: NWConnection) {
        let requestLine = String(bytes: request.prefix(while: { $0 != 0x0D }), encoding: .utf8) ?? ""
        guard !requestLine.contains("/favicon.ico") else {
            send("HTTP/1.1 404 Not Found\r\nContent-Length: 0\r\nConnection: close\r\n\r\n", on: connection)
            return
        }
        lock.lock()
        pageCount += 1
        lock.unlock()

        let body = """
        <html><head><title>HTTPS-only test site</title></head><body>
        <h1>HTTPS-only test site</h1>
        <p><a href="\(timeoutSiteURL())">\(HTTPSTimeoutServer.timeoutLinkText)</a></p>
        </body></html>
        """
        let header = "HTTP/1.1 200 OK\r\nContent-Type: text/html; charset=utf-8\r\n" +
            "Content-Length: \(body.utf8.count)\r\nConnection: close\r\n\r\n"
        send(header + body, on: connection)
    }

    private func send(_ response: String, on connection: NWConnection) {
        connection.send(content: Data(response.utf8), completion: .contentProcessed { _ in
            connection.cancel()
        })
    }
}
