// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Network
import Security

/// In-runner HTTPS site on 127.0.0.1 with a self-signed certificate that nothing trusts, so the browser
/// shows its untrusted connection page without any network access.
final class UntrustedHTTPSServer: @unchecked Sendable {
    static let host = "127.0.0.1"
    static let pageHeading = "Untrusted test site"

    private static let identityPassword = "xcuitest"
    // Test-only P-256 key and self-signed certificate for 127.0.0.1 and localhost, valid until 2126.
    // Never trusted anywhere, which is the point. Export with `openssl pkcs12 -export -legacy`:
    // iOS 17 SecPKCS12Import rejects OpenSSL 3's default AES/SHA-256 encryption.
    private static let identityPKCS12 = """
        MIID0gIBAzCCA5AGCSqGSIb3DQEHAaCCA4EEggN9MIIDeTCCAm8GCSqGSIb3DQEHBqCCAmAwggJcAgEAMIICVQYJKoZIhvcNAQcB
        MBwGCiqGSIb3DQEMAQMwDgQIWWaUNGuLSXwCAggAgIICKHBpjoHqMt0pbZI5gxXHIlZpPdijcxknbNqG3e5nZY5CzXV4Gmz4pNRP
        Ukyp6eGSS6hJYebMmRFYkR2TE2pPkUBzoT1Z9UYldIlDMsARpHSC9vMJoAjAD9INznLZvDPzT5aOeIDobOung06dDJg3JFkzqFPE
        62rFoRlvuTZ1wVAtTcSOWbEwHofpG68Yzf42Fx+R702XsEtst0okMF3dkOHIT67M7JR8nvI0aoJqFW2bpiF2rHYDCSeMCbQnIh95
        Cvb7XUiXCCPSs4gEekrpEhXNv0IPBI5aOJpweVLR+GRfYO7SpCxCda3mgwVZ5IAPsiUyBz3KsTqkz3v0XHOUJrOCGzcMUiAE938t
        IoGKFxy5/0DWdOhvg7Nu+TBhB8GrQ43bkLy1P7guGrwJJQqTx5IdtdVfD1c1ZQDv1aY6fo7MwSKyUu7g8pKO+Bgc0cRf2kryBhYv
        gEhmebf/6JvzBWgGsxVfkoSecoqgk1VjxaRg0iCy8MP2q1BtV/NlIHkB2MvvIaNK5wdDIDynvLYUWCziK+4i0DCzl/3HytireWVS
        qN31ARHmt9hVZnw1AmclHgycQhqPlYdx91gV2ODMf4BXTVhIzdhWSHbsFkN+dV3bImFamN4CWys3JdHAAd/a7M8c6sqMNHk89zHK
        0TZUTzBfsxMnkoJfmmdjQ3d9/DC6vEmxs/Q0FUJ4ZuhNYaB2b5iVTgTlb3cUBmbdUo848Ze7EDIftg7t/zCCAQIGCSqGSIb3DQEH
        AaCB9ASB8TCB7jCB6wYLKoZIhvcNAQwKAQKggbQwgbEwHAYKKoZIhvcNAQwBAzAOBAhcQJE7Laq9tAICCAAEgZCZgSRerxPyF2A7
        2IBwPdjE8PmZ6aEME1T0OrV2z/AZ6rlob62i0gCWUtSuYMrSBskzb+JS+/mzCt9mutdGiXrHtWL7lYwty4NNAsWCghurSV0yQ6hc
        9gekmFN+dhckQ49xQI2+eRQO2KXXp3VYkhZUyBiq5jsrxKF663T2k6CCUWb7Ey5AezdYEeaHphLUJWgxJTAjBgkqhkiG9w0BCRUx
        FgQUYlalWAjHcUCPU58UaORU8uD6W7owOTAhMAkGBSsOAwIaBQAEFLmegFo9wf1C7h0oIIVX5k2xyZUgBBD1usmygnvmdygBjejb
        BywJAgIIAA==
        """

    private let listener: NWListener
    private let queue = DispatchQueue(label: "org.mozilla.ios.UntrustedHTTPSServer")
    private(set) var port: UInt16 = 0

    var siteURL: String {
        "https://\(Self.host):\(port)/"
    }

    init() throws {
        let tlsOptions = NWProtocolTLS.Options()
        sec_protocol_options_set_local_identity(tlsOptions.securityProtocolOptions, try Self.identity())
        let parameters = NWParameters(tls: tlsOptions, tcp: NWProtocolTCP.Options())
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
            throw Self.error("The local HTTPS server did not start")
        }
        self.port = port
    }

    func stop() {
        listener.cancel()
    }

    private static func identity() throws -> sec_identity_t {
        guard let data = Data(base64Encoded: identityPKCS12, options: .ignoreUnknownCharacters) else {
            throw error("The test certificate is not valid base64")
        }
        var items: CFArray?
        let options = [kSecImportExportPassphrase as String: identityPassword] as CFDictionary
        let status = SecPKCS12Import(data as CFData, options, &items)
        guard status == errSecSuccess,
              let item = (items as? [[String: Any]])?.first,
              let identity = item[kSecImportItemIdentity as String]
        else {
            throw error("The test certificate could not be loaded, SecPKCS12Import returned \(status)")
        }
        // swiftlint:disable:next force_cast
        guard let secIdentity = sec_identity_create(identity as! SecIdentity) else {
            throw error("The test certificate has no usable identity")
        }
        return secIdentity
    }

    private static func error(_ description: String) -> NSError {
        NSError(domain: "UntrustedHTTPSServer", code: 1, userInfo: [NSLocalizedDescriptionKey: description])
    }

    /// Answers every path with the same page. Handshakes the browser rejects simply end the connection.
    private func handle(_ connection: NWConnection) {
        connection.stateUpdateHandler = { state in
            if case .failed = state { connection.cancel() }
        }
        connection.start(queue: queue)
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, _, error in
            guard let self, data != nil, error == nil else {
                connection.cancel()
                return
            }
            self.respond(on: connection)
        }
    }

    private func respond(on connection: NWConnection) {
        let body = """
        <html><head><title>\(Self.pageHeading)</title></head><body>
        <h1>\(Self.pageHeading)</h1>
        </body></html>
        """
        let response = "HTTP/1.1 200 OK\r\nContent-Type: text/html; charset=utf-8\r\n" +
            "Content-Length: \(body.utf8.count)\r\nConnection: close\r\n\r\n" + body
        connection.send(content: Data(response.utf8), completion: .contentProcessed { _ in
            connection.cancel()
        })
    }
}
