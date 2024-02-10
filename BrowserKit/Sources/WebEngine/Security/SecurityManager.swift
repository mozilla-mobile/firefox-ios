// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// The SecurityManager takes in a BrowsingContext to determine if it's safe or not to navigate to a certain URL
public protocol SecurityManager {
    func canNavigateWith(browsingContext: BrowsingContext) -> NavigationDecisionType
}

public class DefaultSecurityManager: SecurityManager {
    public init() {}

    public func canNavigateWith(browsingContext: BrowsingContext) -> NavigationDecisionType {
        guard let url = URL(string: browsingContext.url) else {
            // The URL is not a URL, refuse the navigation
            return .refused
        }

        switch browsingContext.type {
        case .externalNavigation:
            return handleExternalNavigation(url: url)
        case .internalNavigation:
            return handleInternalNavigation(url: url)
        case .redirectionNavigation:
            return handleRedirectionNavigation(url: url)
        }
    }

    // MARK: - External

    private func handleExternalNavigation(url: URL) -> NavigationDecisionType {
        return schemeIsExternalNavigationValid(for: url) ? .allowed : .refused
    }

    private func schemeIsExternalNavigationValid(for url: URL) -> Bool {
        let acceptedSchemes = [SchemesDefinition.standardSchemes.data] + SchemesDefinition.webpageSchemes
        return acceptedSchemes.contains { $0.rawValue == url.scheme }
    }

    // MARK: - Internal

    private func handleInternalNavigation(url: URL) -> NavigationDecisionType {
        return schemeIsInternalNavigationValid(for: url) ? .allowed : .refused
    }

    /// Returns whether the URL's scheme is one of those listed on the official list of URI schemes
    private func schemeIsInternalNavigationValid(for url: URL) -> Bool {
        guard let scheme = url.scheme else { return false }

        let schemesList = SchemesDefinition.permanentURISchemes + [SchemesDefinition.standardSchemes.internalURL.rawValue]
        let isValidScheme = schemesList.contains(scheme.lowercased())
        let urlIsNotComposedOnlyOfAScheme = url.absoluteURL.absoluteString.lowercased() != scheme + ":"
        return isValidScheme && urlIsNotComposedOnlyOfAScheme
    }

    // MARK: - Redirection

    private func handleRedirectionNavigation(url: URL) -> NavigationDecisionType {
        return .allowed
        // TODO: FXIOS-8375 - Handle redirection navigation
//        if schemeIsRedirectionNavigationValid(for: url) {
//            return .allowed
//        } else if schemeIsRedirectionThirdPartyNavigationValid(for: url) {
//            return .clientHandled
//        } else {
//            return .refused
//        }
    }

//    private func schemeIsRedirectionNavigationValid(for url: URL) -> Bool {
//        let acceptedSchemes = [SchemesDefinition.standardSchemes.data] + SchemesDefinition.callingSchemes
//        return acceptedSchemes.contains { $0.rawValue == url.scheme }
//    }
//
//    private func schemeIsRedirectionThirdPartyNavigationValid(for url: URL) -> Bool {
//        let acceptedSchemes = [SchemesDefinition.standardSchemes.mailto]
//        + SchemesDefinition.appStoreSchemes
//        + SchemesDefinition.callingSchemes
//        return acceptedSchemes.contains { $0.rawValue == url.scheme }
//    }
}
