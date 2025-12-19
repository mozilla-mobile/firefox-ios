// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Ecosia

final class EcosiaURLInterceptorTests: XCTestCase {
    private var sut: EcosiaURLInterceptor!

    override func setUp() {
        super.setUp()
        sut = EcosiaURLInterceptor(urlProvider: .production)
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Sign Up Detection Tests

    func testInterceptedType_whenSignUpURL_returnsSignUp() {
        // Given
        let url = URL(string: "https://www.ecosia.org/accounts/sign-up")!

        // When
        let result = sut.interceptedType(for: url)

        // Then
        XCTAssertEqual(result, .signUp)
    }

    func testInterceptedType_whenSignUpURLWithQueryParams_returnsSignUp() {
        // Given
        let url = URL(string: "https://www.ecosia.org/accounts/sign-up?redirect=/search")!

        // When
        let result = sut.interceptedType(for: url)

        // Then
        XCTAssertEqual(result, .signUp)
    }

    func testInterceptedType_whenSignUpURLWithMixedCase_returnsSignUp() {
        // Given
        let url = URL(string: "https://www.ecosia.org/Accounts/Sign-Up")!

        // When
        let result = sut.interceptedType(for: url)

        // Then
        XCTAssertEqual(result, .signUp)
    }

    func testShouldIntercept_whenSignUpURL_returnsTrue() {
        // Given
        let url = URL(string: "https://www.ecosia.org/accounts/sign-up")!
    // MARK: - Sign In Detection Tests

    func testInterceptedType_whenSignInURL_returnsSignIn() {
        // Given
        let url = URL(string: "https://www.ecosia.org/accounts/sign-in")!

        // When
        let result = sut.interceptedType(for: url)

        // Then
        XCTAssertEqual(result, .signIn)
    }

    func testInterceptedType_whenSignInURLWithQueryParams_returnsSignIn() {
        // Given
        let url = URL(string: "https://www.ecosia.org/accounts/sign-in?redirect=/")!

        // When
        let result = sut.interceptedType(for: url)

        // Then
        XCTAssertEqual(result, .signIn)
    }

    func testInterceptedType_whenSignInURLWithMixedCase_returnsSignIn() {
        // Given
        let url = URL(string: "https://www.ecosia.org/Accounts/Sign-In")!

        // When
        let result = sut.interceptedType(for: url)

        // Then
        XCTAssertEqual(result, .signIn)
    }

    func testShouldIntercept_whenSignInURL_returnsTrue() {
        // Given
        let url = URL(string: "https://www.ecosia.org/accounts/sign-in")!

        // When
        let result = sut.shouldIntercept(url)

        // Then
        XCTAssertTrue(result)
    }

        // When
        let result = sut.shouldIntercept(url)

        // Then
        XCTAssertTrue(result)
    }

    // MARK: - Sign Out Detection Tests

    func testInterceptedType_whenSignOutURL_returnsSignOut() {
        // Given
        let url = URL(string: "https://www.ecosia.org/accounts/sign-out")!

        // When
        let result = sut.interceptedType(for: url)

        // Then
        XCTAssertEqual(result, .signOut)
    }

    func testInterceptedType_whenSignOutURLWithQueryParams_returnsSignOut() {
        // Given
        let url = URL(string: "https://www.ecosia.org/accounts/sign-out?redirect=/")!

        // When
        let result = sut.interceptedType(for: url)

        // Then
        XCTAssertEqual(result, .signOut)
    }

    func testShouldIntercept_whenSignOutURL_returnsTrue() {
        // Given
        let url = URL(string: "https://www.ecosia.org/accounts/sign-out")!

        // When
        let result = sut.shouldIntercept(url)

        // Then
        XCTAssertTrue(result)
    }

    // MARK: - Profile Detection Tests

    func testInterceptedType_whenProfileURL_returnsProfile() {
        // Given
        let url = URL(string: "https://www.ecosia.org/accounts/profile")!

        // When
        let result = sut.interceptedType(for: url)

        // Then
        XCTAssertEqual(result, .profile)
    }

    func testInterceptedType_whenProfileURLWithQueryParams_returnsProfile() {
        // Given
        let url = URL(string: "https://www.ecosia.org/accounts/profile?tab=settings")!

        // When
        let result = sut.interceptedType(for: url)

        // Then
        XCTAssertEqual(result, .profile)
    }

    func testInterceptedType_whenProfileURLWithMixedCase_returnsProfile() {
        // Given
        let url = URL(string: "https://www.ecosia.org/Accounts/Profile")!

        // When
        let result = sut.interceptedType(for: url)

        // Then
        XCTAssertEqual(result, .profile)
    }

    func testShouldIntercept_whenProfileURL_returnsTrue() {
        // Given
        let url = URL(string: "https://www.ecosia.org/accounts/profile")!

        // When
        let result = sut.shouldIntercept(url)

        // Then
        XCTAssertTrue(result)
    }

    // MARK: - Non-Intercepted URL Tests

    func testInterceptedType_whenNonEcosiaURL_returnsNone() {
        // Given
        let url = URL(string: "https://www.google.com/search")!

        // When
        let result = sut.interceptedType(for: url)

        // Then
        XCTAssertEqual(result, .none)
    }

    func testInterceptedType_whenEcosiaSearchURL_returnsNone() {
        // Given
        let url = URL(string: "https://www.ecosia.org/search?q=test")!

        // When
        let result = sut.interceptedType(for: url)

        // Then
        XCTAssertEqual(result, .none)
    }

    func testInterceptedType_whenEcosiaHomeURL_returnsNone() {
        // Given
        let url = URL(string: "https://www.ecosia.org/")!

        // When
        let result = sut.interceptedType(for: url)

        // Then
        XCTAssertEqual(result, .none)
    }

    func testShouldIntercept_whenNonInterceptedURL_returnsFalse() {
        // Given
        let url = URL(string: "https://www.ecosia.org/search?q=test")!

        // When
        let result = sut.shouldIntercept(url)

        // Then
        XCTAssertFalse(result)
    }

    func testShouldIntercept_whenNonEcosiaURL_returnsFalse() {
        // Given
        let url = URL(string: "https://www.google.com")!

        // When
        let result = sut.shouldIntercept(url)

        // Then
        XCTAssertFalse(result)
    }

    // MARK: - Edge Cases

    func testInterceptedType_whenURLWithFragment_detectsCorrectly() {
        // Given
        let url = URL(string: "https://www.ecosia.org/accounts/profile#section")!

        // When
        let result = sut.interceptedType(for: url)

        // Then
        XCTAssertEqual(result, .profile)
    }

    func testInterceptedType_whenURLWithPort_detectsCorrectly() {
        // Given
        let url = URL(string: "https://www.ecosia.org:443/accounts/sign-up")!

        // When
        let result = sut.interceptedType(for: url)

        // Then
        XCTAssertEqual(result, .signUp)
    }

    func testInterceptedType_whenSubdomainEcosiaURL_detectsCorrectly() {
        // Given
        let url = URL(string: "https://test.ecosia.org/accounts/profile")!

        // When
        let result = sut.interceptedType(for: url)

        // Then
        XCTAssertEqual(result, .profile)
    }
}
