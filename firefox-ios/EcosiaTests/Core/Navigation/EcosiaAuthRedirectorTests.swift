// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Ecosia

final class EcosiaAuthRedirectorTests: XCTestCase {
    func testRedirectURLForSignIn_appendsReturnToParameter() {
        // Given
        let signInURL = Environment.production.urlProvider.signInURL
        let originalQuery = "https://www.ecosia.org/search?q=test"

        // When
        let redirectedURL = EcosiaAuthRedirector.redirectURLForSignIn(signInURL, redirectURLString: originalQuery, urlProvider: .production)

        // Then
        XCTAssertNotNil(redirectedURL)
        let components = URLComponents(url: redirectedURL!, resolvingAgainstBaseURL: false)
        let returnToItem = components?.queryItems?.first(where: { $0.name == "returnTo" })
        XCTAssertEqual(returnToItem?.value, originalQuery)
    }

    func testRedirectURLForSignIn_appendsReturnToWithNonSearchString() {
        // Given
        let signInURL = Environment.current.urlProvider.signInURL
        let originalProfileURL = Environment.current.urlProvider.profileURL.absoluteString

        // When
        let redirectedURL = EcosiaAuthRedirector.redirectURLForSignIn(signInURL, redirectURLString: originalProfileURL)

        // Then
        XCTAssertNotNil(redirectedURL)
        let components = URLComponents(url: redirectedURL!, resolvingAgainstBaseURL: false)
        let returnToItem = components?.queryItems?.first(where: { $0.name == "returnTo" })
        XCTAssertEqual(returnToItem?.value, originalProfileURL)
    }

    func testRedirectURLForSignIn_returnsNilWhenURLIsNotSignIn() {
        // Given
        let nonSignInURL = Environment.production.urlProvider.profileURL

        // When
        let redirectedURL = EcosiaAuthRedirector.redirectURLForSignIn(nonSignInURL, redirectURLString: "https://www.ecosia.org/search?q=test", urlProvider: .production)

        // Then
        XCTAssertNil(redirectedURL)
    }

    func testRedirectURLForSignIn_returnsNotNilForSignInWithStagingHost() {
        // Given
        let stagingSignInURL = URL(string: "https://www.ecosia-staging.xyz/accounts/sign-in")!

        // When
        let redirectedURL = EcosiaAuthRedirector.redirectURLForSignIn(stagingSignInURL, redirectURLString: "https://www.ecosia.org/search?q=test", urlProvider: .staging)

        // Then
        XCTAssertNotNil(redirectedURL)
    }

    func testRedirectURLForSignIn_returnsNilForExternalSignInHost() {
        // Given
        let externalSignInURL = URL(string: "https://www.example.com/sign-in")!

        // When
        let redirectedURL = EcosiaAuthRedirector.redirectURLForSignIn(externalSignInURL, redirectURLString: "https://www.ecosia.org/search?q=test", urlProvider: .production)

        // Then
        XCTAssertNil(redirectedURL)
    }

    func testRedirectURL_returnsNilWhenReturnToAlreadyPresent() {
        // Given
        var components = URLComponents(url: Environment.production.urlProvider.signInURL, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "returnTo", value: "https://example.com")
        ]
        let urlWithReturnTo = components.url!

        // When
        let redirectedURL = EcosiaAuthRedirector.redirectURL(for: urlWithReturnTo, redirectURLString: "https://www.ecosia.org/search?q=test")

        // Then
        XCTAssertNil(redirectedURL)
    }

    func testRedirectURL_preservesExistingQueryItems() {
        // Given
        var components = URLComponents(url: Environment.production.urlProvider.signInURL, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "existingKey", value: "existingValue")
        ]
        let baseURL = components.url!

        // When
        let redirectedURL = EcosiaAuthRedirector.redirectURLForSignIn(baseURL,
                                                                      redirectURLString: "https://www.ecosia.org/search?q=another",
                                                                      urlProvider: .production)

        // Then
        XCTAssertNotNil(redirectedURL)
        let finalComponents = URLComponents(url: redirectedURL!, resolvingAgainstBaseURL: false)
        XCTAssertTrue(finalComponents?.queryItems?.contains(where: { $0.name == "existingKey" && $0.value == "existingValue" }) ?? false)
        XCTAssertTrue(finalComponents?.queryItems?.contains(where: { $0.name == "returnTo" && $0.value == "https://www.ecosia.org/search?q=another" }) ?? false)
    }
}
