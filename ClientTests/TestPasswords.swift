import Foundation
import XCTest
import Storage

class TestPasswords : ProfileTest {
    func testPasswords() {
        withTestProfile { (profile) -> Void in
            let hostname = "Hostname"
            let username = "Username"
            let password = "Password"

            let p = Password(hostname: hostname, username: username, password: password)
            println("Storing \(p.username) and \(p.password)")
            var expectation = self.expectationWithDescription("Save password")
            profile.passwords.add(p, complete: { success in
                XCTAssertTrue(success, "Password was added")
                expectation.fulfill()
            })
            self.waitForExpectationsWithTimeout(10, handler: nil)

            let options = QueryOptions(filter: hostname)
            expectation = self.expectationWithDescription("Get password")
            profile.passwords.get(options, complete: { results in
                XCTAssertEqual(results.count, 1, "Found one result")
                let p = results[0]
                XCTAssertEqual(p!.username, username, "Password has right username")
                XCTAssertEqual(p!.password, password, "Password has right password")
                expectation.fulfill()
            })
            self.waitForExpectationsWithTimeout(10, handler: nil)

            expectation = self.expectationWithDescription("Clear password")
            profile.passwords.remove(p, complete: { success in
                XCTAssertTrue(success, "Password was removed")
                profile.passwords.get(options, complete: { results in
                    XCTAssertEqual(results.count, 0, "Found no results")
                    expectation.fulfill()
                })
            })
            self.waitForExpectationsWithTimeout(10, handler: nil)

            expectation = self.expectationWithDescription("Clear all passwords")
            profile.passwords.add(p, complete: { success in
                XCTAssertTrue(success, "Password was added")
                profile.passwords.removeAll({ success in
                    XCTAssertTrue(success, "Password was removed")
                    profile.passwords.get(options, complete: { results in
                        XCTAssertEqual(results.count, 0, "Found no results")
                        expectation.fulfill()
                    })
                })
            })
            self.waitForExpectationsWithTimeout(10, handler: nil)

        }
    }
}