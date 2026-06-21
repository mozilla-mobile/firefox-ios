// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Storage

class CertTests: XCTestCase {
    func testCertStore() {
        let certStore = CertStore()
        let origin1 = "www.mozilla.org:80"
        let origin2 = "people.mozilla.org:80"
        let cert1 = getCertificate("testcert1")
        let cert2 = getCertificate("testcert2")

        // Check that contains return false for certs not in store.
        XCTAssertFalse(certStore.containsCertificate(cert1, forOrigin: origin1))

        // Add a certificate.
        certStore.addCertificate(cert1, forOrigin: origin1)

        // Check that the cert is in the store.
        XCTAssert(certStore.containsCertificate(cert1, forOrigin: origin1))

        // Check that the cert is unique to the origin.
        XCTAssertFalse(certStore.containsCertificate(cert1, forOrigin: origin2))
        XCTAssertFalse(certStore.containsCertificate(cert2, forOrigin: origin1))

        // Add a different certificate for the same origin.
        certStore.addCertificate(cert2, forOrigin: origin1)

        // Check that adding a cert for an existing origin doesn't do a replace.
        XCTAssert(certStore.containsCertificate(cert1, forOrigin: origin1))
        XCTAssert(certStore.containsCertificate(cert2, forOrigin: origin1))

        // Check that adding an existing cert has no effect.
        certStore.addCertificate(cert1, forOrigin: origin1)
        XCTAssert(certStore.containsCertificate(cert1, forOrigin: origin1))
    }

    func testHasCertificateForOrigin() {
        let certStore = CertStore()
        let origin = "www.mozilla.org:80"
        let cert = getCertificate("testcert1")

        // Check that hasCertificate returns false before adding.
        XCTAssertFalse(certStore.hasCertificate(forOrigin: origin))

        // Add a certificate and check it's found.
        certStore.addCertificate(cert, forOrigin: origin)
        XCTAssert(certStore.hasCertificate(forOrigin: origin))

        // Check that it's unique to the origin.
        XCTAssertFalse(certStore.hasCertificate(forOrigin: "people.mozilla.org:80"))
    }

    func testSetAndGetCertificateChain() {
        let certStore = CertStore()
        let origin1 = "www.mozilla.org:80"
        let origin2 = "people.mozilla.org:80"
        let cert1 = getCertificate("testcert1")
        let cert2 = getCertificate("testcert2")
        let chain = [cert1, cert2]

        // No chain exists for an origin before it's set.
        XCTAssertNil(certStore.certificateChain(forOrigin: origin1))

        // Set a chain for an origin.
        certStore.setCertificateChain(chain, forOrigin: origin1)

        // The chain is retrievable, in order, and matches what was stored.
        let storedChain = certStore.certificateChain(forOrigin: origin1)
        XCTAssertEqual(storedChain?.count, 2)
        XCTAssert(storedChain?[0] === cert1)
        XCTAssert(storedChain?[1] === cert2)

        // The chain is scoped to the origin it was set for.
        XCTAssertNil(certStore.certificateChain(forOrigin: origin2))
    }

    func testSetCertificateChainOverwritesExistingChain() {
        let certStore = CertStore()
        let origin = "www.mozilla.org:80"
        let cert1 = getCertificate("testcert1")
        let cert2 = getCertificate("testcert2")

        certStore.setCertificateChain([cert1], forOrigin: origin)
        XCTAssertEqual(certStore.certificateChain(forOrigin: origin)?.count, 1)

        // Setting a new chain for the same origin replaces the old one (dictionary assignment), not appends.
        certStore.setCertificateChain([cert2], forOrigin: origin)
        let updatedChain = certStore.certificateChain(forOrigin: origin)
        XCTAssertEqual(updatedChain?.count, 1)
        XCTAssert(updatedChain?[0] === cert2)
    }

    func testSetCertificateChainWithEmptyArray() {
        let certStore = CertStore()
        let origin = "www.mozilla.org:80"
        let cert = getCertificate("testcert1")

        certStore.setCertificateChain([cert], forOrigin: origin)
        certStore.setCertificateChain([], forOrigin: origin)

        // Dictionary still has an entry for the origin, so this is Optional([]), not nil.
        XCTAssertNotNil(certStore.certificateChain(forOrigin: origin))
        XCTAssertEqual(certStore.certificateChain(forOrigin: origin)?.count, 0)
    }

    func testCertificateChainIsIndependentFromCertificateSet() {
        let certStore = CertStore()
        let origin = "www.mozilla.org:80"
        let cert1 = getCertificate("testcert1")
        let cert2 = getCertificate("testcert2")

        // addCertificate (keys/origins) and setCertificateChain (certificateChains) are separate stores.
        certStore.addCertificate(cert1, forOrigin: origin)
        XCTAssert(certStore.hasCertificate(forOrigin: origin))
        XCTAssertNil(certStore.certificateChain(forOrigin: origin))

        certStore.setCertificateChain([cert2], forOrigin: origin)
        XCTAssertNotNil(certStore.certificateChain(forOrigin: origin))
        // containsCertificate only ever reflects addCertificate, regardless of the chain.
        XCTAssertFalse(certStore.containsCertificate(cert2, forOrigin: origin))
        XCTAssert(certStore.containsCertificate(cert1, forOrigin: origin))
    }

    fileprivate func getCertificate(_ file: String) -> SecCertificate {
        let path = Bundle(for: type(of: self)).path(forResource: file, ofType: "pem")
        let data = try? Data(contentsOf: URL(fileURLWithPath: path!))
        return SecCertificateCreateWithData(nil, data! as CFData)!
    }
}
