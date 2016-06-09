/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

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

    private func getCertificate(file: String) -> SecCertificateRef {
        let path = NSBundle(forClass: self.dynamicType).pathForResource(file, ofType: "pem")
        let data = NSData(contentsOfFile: path!)
        return SecCertificateCreateWithData(nil, data!)!
    }
}
