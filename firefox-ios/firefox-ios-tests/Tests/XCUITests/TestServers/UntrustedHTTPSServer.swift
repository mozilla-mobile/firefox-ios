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
    // Never trusted anywhere, which is the point; regenerate with the commands in PR #36550.
    private static let identityPKCS12 = """
        MIIEdAIBAzCCBCIGCSqGSIb3DQEHAaCCBBMEggQPMIIECzCCAroGCSqGSIb3DQEHBqCCAqswggKnAgEAMIICoAYJKoZIhvcNAQcB
        MF8GCSqGSIb3DQEFDTBSMDEGCSqGSIb3DQEFDDAkBBDuSuEvSrAeaUVWR/ZxXxndAgIIADAMBggqhkiG9w0CCQUAMB0GCWCGSAFl
        AwQBKgQQZ0GNOJFV31bV1+HUseQSPYCCAjAcoJKdyH+nRJAkTzHNDuQAYC+0jwBJI4O8GPprm0UTSj7XCmqknkhPBY+TkNTAM9DC
        HZLdCTR2e+XgoOSQBu8oZaPWkfhDAvB39Fx9gPjdFkxuWLT/AiVJbzwU3h/gKrLocxbJKZ4gHKIGMQjNlJVE8GpPALBww2fPBHdq
        oga8oezJUCIgO2gGP9HVRfXNEQ89H13r4JjAgHx7ypZPUGqQ5VIxTXp8fxspfjdrCeLhl8pjQSqaF6WS27LB17vUgifo5Fd4C1YL
        UIp26yOvCnvO+Iq5hRlsKiQIZ0sngnicXuUx4D12PjmO7RdwzftMULcVeGHfkeSjcffVR2pzZh+e5OG16Wz1BMQffat2H+ryCml2
        g7CU7HPY37QJikrv/+deDQBylMGMoyYJ+bvTi8wzKNJWus8nvsc/Fr3rfLNxxMYqlLrAU0WwdKhlN3hkZfkBpaK8lCknO4nbtSy8
        tLEliL10kRuNMaNThEeXc16/mNZZVnsVWMy7Oxra0dk/SEltzs1WRX+ZanrsoHQ46lqgrdsRh2uH56B3c00lQFubjM1VFUNKFRQm
        hPG9DjJZJ8goCuK7vVu/4+nKKSMdDiLMVvNByn2e+F/1INEV95ST0MvrdrgwyxStJ44mHpP/NmHr/opDhjRTA2Fdi4/ZddbKYyHq
        9zUaZUhaGpV8Pu0sDoqDXts8XovPxaFJoGFWYJ9iOZjDqZdxP01UttkUyw5Y2iqi5XZy7Q/0p7bipDI+VjCCAUkGCSqGSIb3DQEH
        AaCCAToEggE2MIIBMjCCAS4GCyqGSIb3DQEMCgECoIH3MIH0MF8GCSqGSIb3DQEFDTBSMDEGCSqGSIb3DQEFDDAkBBD1ukwFxCI/
        fOKxcq85quKAAgIIADAMBggqhkiG9w0CCQUAMB0GCWCGSAFlAwQBKgQQQ73W+N8JFAhSbDA/WtPdTgSBkNqHEjZ3WUnZ24pjvkb6
        U+jnJqGpv4FX+C3SBg4g9Wy7hejXV8DVM/lIjQSsw53vxr6tf6jWHuL23lXU0TRw/VCbm3V7aHRKf4PC7NhAsYT/3FOyMofMpfBE
        +LaahDcjMx2rJbG1fG65nK30fD3fIxtrfft7hAvaIgylbpGsbe5kQp6uY9aX8+ZaN2Jwdy8mLTElMCMGCSqGSIb3DQEJFTEWBBRi
        VqVYCMdxQI9TnxRo5FTy4PpbujBJMDEwDQYJYIZIAWUDBAIBBQAEIC6N97/MLc9Pd6afgBf0TL7+gt1+Wsk1FMQqdNAYI+8HBBDP
        37RG1U9fjLOKdP2aYAZTAgIIAA==
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
